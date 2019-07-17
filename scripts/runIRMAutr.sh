#!/bin/bash

SCRIPTS=$(dirname $(readlink -f $0))
ROOT=$(readlink -f $(dirname $0) | rev | cut -d '/' -f 2- | rev)
IRMA=${ROOT}/bin/flu-amd/IRMA

function usage {
	printf "\n\tUSAGE: $(basename $0) <runID> [-o (overwrite previous output)]\n\n"
	exit
	}

runID=$1
user=$(whoami)
cd /home/${user}/minionRuns/*/$runID || (printf "\n\t!!! runID: $1 not found in /home/${user}/minionRuns/*/<runID> !!!\n\n" && usage)

if [[ ${@^^} =~ '-H' ]] || [[ -z $runID ]]; then
	echo $runID
	usage
fi

function IRMAUTR {
	mkdir IRMA-utr && cd IRMA-utr
	for i in ../IRMA/*.fastq; do
		out=$(echo $i | rev | cut -d '/' -f 1 | rev)
		$IRMA FLU-minionUTR $i ${out%.fastq} >> ${out%.fastq}.IRMAutr.log 2>&1
	done
}

if [[ ! -d IRMA-utr ]]; then
	IRMAUTR
elif [[ -d IRMA-utr ]] && [[ ${2^^} =~ "-O" ]]; then
	rm -r IRMA-utr && IRMAUTR
fi
