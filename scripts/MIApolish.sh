#!/bin/bash
ROOT=$(readlink -f $(dirname $0) | rev | cut -d '/' -f 2- | rev)
nanopolish=${ROOT}/bin/nanopolish

function usage {
	printf "\n\tUSAGE: $(basename $0) <runID> <ALL|HA|MP|NA|NP|NS|PA|PB1|PB2> [utr (optional)] [-o (overwrite previous output)]\n\n\tNanopolish MIA-IRMA derived consensus sequences.\n\n"
	exit
}

if [[ $# -lt 2 ]]; then
	usage
fi

runID=$1
seg=$2
[[ ${@^^} =~ 'UTR' ]] && utr=1
[[ ${@^^} =~ "-O" ]] && OVER=1

if [[ ${seg^^} == 'ALL' ]]; then
	seg="HA MP NA NP NS PA PB1 PB2"
else
	seg=${seg^^}
fi

cd ~/minionRuns/*/$runID

function POLISHFUN {
	if [[ $utr -eq 1 ]]; then
		mkdir nanopolish-utr && cd nanopolish-utr
	else
		mkdir nanopolish && cd nanopolish
	fi

	mkdir index logs
	cp ../IRMA/*fastq index/
	seqSummary=$(readlink -f ../fastq/*/sequencing_summary.txt >> seqSummary.locations && readlink -f seqSummary.locations)
	fast5s=$(readlink -f /var/lib/MinKNOW/data/reads/*$(echo $runID | cut -d '_' -f 1)* | tail -1)"/fast5/"
	for i in index/*fastq; do
		barcode=$(basename $i) && barcode=${barcode%.fastq}

		# INDEX READS
		$nanopolish index -d $fast5s -f $seqSummary $i >> logs/${barcode}.idx.log 2>&1
		for s in $seg; do

			# NANOPOLISH CONSENSUS
			if [[ $utr -eq 1 ]]; then
				cmd="$nanopolish variants --consensus ${barcode}.${s}.polished.fasta -r $i -b ../IRMA-utr/$barcode/*${s}*bam -g ../IRMA-utr/$barcode/*${s}*fasta -t 8 >> logs/${barcode}.pol.log 2>&1"
			else
				cmd="$nanopolish variants --consensus ${barcode}.${s}.polished.fasta -r $i -b ../IRMA/$barcode/*${s}*bam -g ../IRMA/$barcode/*${s}*fasta -t 8 >> logs/${barcode}.pol.log 2>&1"
			fi
			echo "COMMAND: "$cmd >> logs/${barcode}.pol.log 
			eval $cmd
		done
	done
}

if [[ $utr -eq 1 ]] && [[ ! -d nanopolish-utr ]]; then
	POLISHFUN
elif [[ $utr -eq 1 ]] && [[ -d nanopolish-utr ]] && [[ ! -z $OVER ]]; then
	rm -r nanopolish-utr && POLISHFUN
elif [[ -z $utr ]] && [[ ! -d nanopolish ]]; then
	POLISHFUN
elif [[ -z $utr ]] && [[ -d nanopolish ]] && [[ ! -z $OVER ]]; then
	rm -r nanopolish && POLISHFUN
fi









