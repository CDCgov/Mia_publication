#!/bin/bash

watchRoot="/home/mia2/minionRuns/*MinION*"

SCRIPTS=$(readlink -f $(dirname $0))
IRMA=$(cd $SCRIPTS && readlink -f ../bin/flu-amd/IRMA)
IRMAlaunch="$IRMA FLU-minion"
PY="/usr/bin/python"
COVERAGE2SQL="$PY $SCRIPTS/coverageWrap2sqlite.py"
IRMASUM2SQL="$PY $SCRIPTS/irmaSummary2sqlite.py"
BLAST2SQL="$PY $SCRIPTS/blast2sqlite.py"
TREE2SQLREADY="$SCRIPTS/muscle2fasttree2sql.sh"
HANA2SQL="$SCRIPTS/hanaLoader.py"
MUSCLE=$(cd $SCRIPTS && readlink -f ../bin/muscle)
VARSCRIPTS=$(cd $SCRIPTS && readlink -f ../lib/Variants/)
DNA2AA="$PY $VARSCRIPTS/translateDNA.py"
COMPARE2CVV="$PY $SCRIPTS/cvv_comparison.py"
H1ref="$VARSCRIPTS/cvv_H1aaFasta/*"
H3ref="$VARSCRIPTS/cvv_H3aaFasta/*"
H1anti="$VARSCRIPTS/H1N1v_antigenicSite.txt"
H3anti="$VARSCRIPTS/H3N2v_antigenicSite.txt"

# LOGS
MIALOG=$SCRIPTS/logs/mia.log

MIAdb=$(cd $SCRIPTS && readlink -f ../db/MIA.db)

function MIALOG {
    CMD="$@"
    date "+[%Y-%m-%d %H:%M:%S]  Run CMD=($CMD)" >> $MIALOG
    eval $CMD && date "+[%Y-%m-%d %H:%M:%S]  Success CMD=($CMD)" >> $MIALOG 2>&1 || date "+[%Y-%m-%d %H:%M:%S]  Failed CMD=($CMD)" >> $MIALOG 2>&1
}


for FILE in $watchRoot/*/*; do
	if [[ $FILE =~ guppy.fin$ ]]; then
		cd $(dirname $FILE)
		rm guppy.fin
		runID=$(basename $PWD)
		if [[ ! -d IRMA ]]; then mkdir IRMA; fi
		numReads=$(tail -qn +2 fastq/*/sequencing_summary.txt | wc -l)
		# UPDATE DATABASE WITH NUMBER OF FASTQS
		maxdirtime=$(sqlite3 $MIAdb < <(echo -e "select max(DirMtime) from progress where RunID = '$runID' and DirType = 'FASTQ';"))
		cmd="sqlite3 $MIAdb < <(echo -e \"update progress set Reads = '$numReads' where RunID = '$runID' and DirType = 'FASTQ' and DirMtime = '$maxdirtime';\")"
		MIALOG $cmd

		cd IRMA
		for barcode in $(for i in ../fastq/*/* ; do [[ -d $i ]] && echo $i; done | rev | cut -d '/' -f 1 | rev | sort | uniq); do
			if [[ ! $barcode =~ unclassified ]]; then
				cat ../fastq/*/$barcode/*fastq > ${barcode}.fastq
				cmd="$IRMAlaunch ${barcode}.fastq $barcode >> IRMA_${barcode}.log 2>&1"
				MIALOG $cmd
			fi
		done
		for i in $(ls | grep '\-V2'); do cmd="rm -r ${i%-V2} && mv $i ${i%-V2}"; MIALOG $cmd; done
		
		# LOAD COVERAGE, SUMMARY, HA-NA, BLAST RESULTS, PHYLO TREE, CVV AA VARIANTS, PROGRESS TO DATABASE
		cmd="$COVERAGE2SQL $numReads >> coverage2sql.log 2>&1"
		MIALOG $cmd
		cmd="$IRMASUM2SQL $numReads >> irmaSum2sql.log 2>&1"
		MIALOG $cmd
		cmd="$HANA2SQL $runID $numReads >> hana2sql.log 2>&1"
		MIALOG $cmd
		classifiedReads=$(sqlite3 $MIAdb < <(echo -e "select sum(Match)+sum(Nomatch) from irma_summary where RunID = '$runID' and NumReads = (select max(NumReads) from irma_summary where RunID = '$runID');"))
		fluReads=$(sqlite3 $MIAdb < <(echo -e "select sum(Match) from irma_summary where RunID = '$runID' and NumReads = (select max(NumReads) from irma_summary where RunID = '$runID');"))
		cmd="sqlite3 $MIAdb < <(echo -e \"update coverage set NumReads = '$classifiedReads' where RunID = '$runID' and NumReads = '$numReads';\")"
		MIALOG $cmd
		cmd="sqlite3 $MIAdb < <(echo -e \"update irma_summary set NumReads = '$classifiedReads' where RunID = '$runID' and NumReads = '$numReads';\")"
		MIALOG $cmd
		cmd="sqlite3 $MIAdb < <(echo -e \"update hana set NumReads = '$classifiedReads' where RunID = '$runID' and NumReads = '$numReads';\")"
		MIALOG $cmd
		cmd="sqlite3 $MIAdb < <(echo -e \"insert into progress values ('$runID', 'IRMA', '$classifiedReads', '$(date "+%Y-%m-%d %H:%M:%S")');\")"
		MIALOG $cmd
		cmd="$BLAST2SQL $fluReads 2>&1 >> blast.log || echo $? $BLAST2SQL $numReads >> blast.log"
		MIALOG $cmd
		cmd="sqlite3 $MIAdb < <(echo -e \"insert into progress values ('$runID', 'blast', '$fluReads', '$(date "+%Y-%m-%d %H:%M:%S")');\")"
		MIALOG $cmd 
		cmd="tree=$($TREE2SQLREADY $runID $fluReads)"
		MIALOG $cmd
		cmd="sqlite3 $MIAdb \".import $tree newick\" 2>&1 >> fasttreeimport.log"
		MIALOG $cmd
		cmd="sqlite3 $MIAdb < <(echo -e \"insert into progress values ('$runID', 'newick', '$fluReads', '$(date "+%Y-%m-%d %H:%M:%S")');\")"
		MIALOG $cmd
		
		# CVV AA VARIANTS
		for b in *; do
			if [[ -d $b ]] && f=$(ls $b/*HA*fasta 2>/dev/null) && [[ -f $f ]]; then
				if [[ $f =~ 'H1' ]]; then
					ref=$H1ref && anti=$H1anti
				elif [[ $f =~ 'H3' ]]; then
					ref=$H3ref && anti=$H3anti
				fi
				for refFasta in $ref; do
					t=$(mktemp) 
					cmd="cat $refFasta <($DNA2AA -i $f) | $MUSCLE > $t 2>> translate_muscle.log"
					MIALOG $cmd
					cmd="$COMPARE2CVV $t $anti $runID $fluReads $b 2>> compare2cvv.log"
					MIALOG $cmd
				done
			fi
		done 
		cmd="sqlite3 $MIAdb < <(echo -e \"insert into progress values ('$runID', 'cvv_aa', '$fluReads', '$(date "+%Y-%m-%d %H:%M:%S")');\")"
		MIALOG $cmd
	fi
done

