#!/bin/bash

runID=$1
numReads=$2
ROOT=$(readlink -f $(dirname $0) | rev | cut -d '/' -f 2- | rev)
muscle="${ROOT}/bin/muscle"
fasttree="${ROOT}/bin/FastTreeDbl"
segs="HA MP NA NP NS PA PB1 PB2"

tmp=$(mktemp)

for s in $segs;do
	refs="${ROOT}/lib/ncbi-blast-2.7.1+/BlastDB/FullGenome_Seq/$s/v2/*fasta"
	newick=$($fasttree -quote -nt -gtr -gamma -boot 10000 <($muscle -in <(cat <(for i in barcode*/*${s}*fasta; do cat <(echo '>'$(echo $i |rev |cut -d '/' -f 2|rev)) <(tail -n +2 $i) ;done) <(cat $refs)) 2>> muscle.log) 2>> fasttree.log)
	wait
	printf "$runID|$numReads|$s|$newick\n" >> $tmp
done

echo $tmp
