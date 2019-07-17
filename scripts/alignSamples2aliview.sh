#!/bin/bash

ROOT=$(readlink -f $(dirname $0)| rev| cut -d '/' -f 2- | rev)
MUSCLE=$ROOT/bin/muscle
ALIVIEW=$ROOT/bin/aliview

function usage {
	printf "\n\tUSAGE $(basename $0) <runID> <HA|MP|NA|NP|NS|PA|PB1|PB2> <id1 ... idN (space-delimited)>\n\n"	
	exit
}

[[ $# -le 2 ]] && printf "\n$#\n$@\n" && usage

runID=$1
seg=$2
refIDs=$(for i in "$@"; do [[ $i != $runID ]] && [[ $i != $seg ]] && [[ ! $i =~ "barcode" ]] && echo $i | tr '/' '_'; done)
barIDs=$(for i in "$@"; do [[ $i != $runID ]] && [[ $i != $seg ]] && [[ $i =~ "barcode" ]] && echo $i; done)

function ref_fastas {
	for r in $refIDs; do
		cat $ROOT/lib/ncbi-blast-2.7.1+/BlastDB/FullGenome_Seq/$seg/v2/$r.fasta
	done
}

function bar_fastas {
	for b in $barIDs; do
		cat /home/$(whoami)/minionRuns/*_Nanopore-MinION-*/$runID/IRMA-utr/$b/*$seg*.fasta | sed "s/^>.*$/>${seg}_${b}/"
	done
}

t=$(mktemp)
$MUSCLE -in <(ref_fastas; bar_fastas) -out $t
$ALIVIEW $t



