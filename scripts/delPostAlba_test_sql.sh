#!/bin/bash

if  ([[ -z $1 ]] || [[ $@ =~ "-h" ]] ); then
	printf "\n\tUSAGE: $(basename $0) <runID>\n\n"
	exit
fi

cd $(dirname $0)
MIAdb=$(cd ../db && readlink -f MIA.db)
runID=$1

cmd=" \
delete from irma_summary where RunID = '$runID'; \
delete from coverage where RunID = '$runID'; \
delete from blast where RunID = '$runID'; \
delete from newick where RunID = '$runID'; \
delete from cvv_vars where RunID = '$runID'; \
delete from progress where RunID = '$runID' and DirType != 'FAST5'; \
"

sqlite3 $MIAdb < <(echo "$cmd")

