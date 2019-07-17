#!/bin/bash

# Ben Rambo-Martin (nbx0@cdc.gov)
# 2019-05-01
#
#    This script launches Guppy basecalling and demultiplexing 
# locally when fast5 read files originate from a MinION sequencer 
# controlled by MinION software release 18.12.9 (and likely newer 
# releases that create multi-read fast5 files) . 
#
# Requires installing inotify-tools on Ubuntu 16.

# USER SPECIFIC SETTINGS
##########################################################
user=$(whoami)
machineLocation=${user^^}
destRoot=/home/${user}/minionRuns && [[ ! -d $destRoot ]] && mkdir -p $destRoot
watchDir=/var/lib/MinKNOW/data/
GUPPY=/usr/bin/guppy_basecaller
DEMUX=/usr/bin/guppy_barcoder
THREADS=$(grep -c ^processor /proc/cpuinfo)

# DEPENDENCIES
scriptDir=$(readlink -f $(dirname $0))
MIAdb=$(cd $scriptDir && readlink -f ../db/MIA.db)
RUNMETA="python3 $scriptDir/minionMachineFlowcell_v3.py"
gupSum2sqlite="python $scriptDir/guppy_summary2sqlite.py"
#updateFast5="python $scriptDir/updateFast5progress.py"

# LOG FILES
logDir=${scriptDir}/logs && [[ ! -d ${logDir} ]] && mkdir -p $logDir
MIALOG=$logDir/mia.log
INWLOG=$logDir/inotify.log
startTimes=$logDir/startimes.log
metaErr=$logDir/meta.err
gupsumlog=$logDir/guppySummary.log
#########################################################

# MAIN
function basecalledDirFun {
dirroot=$1
fast5number=$2
originalNumber=$3
if [[ ! -d $dirroot/$fast5number ]]; then
	echo $dirroot/$fast5number
else
	fast5number=${fast5number}_$originalNumber
	basecalledDirFun $dirroot $fast5number $originalNumber
fi
}

## Mia.log function
function MIALOG {
	CMD="$@"
	date "+[%Y-%m-%d %H:%M:%S]  Run CMD=($CMD)" >> $MIALOG
	eval $CMD && date "+[%Y-%m-%d %H:%M:%S]  Success CMD=($CMD)" >> $MIALOG 2>&1 || date "+[%Y-%m-%d %H:%M:%S]  Failed CMD=($CMD)" >> $MIALOG 2>&1
}

## touch guppy.fin function to kick off IRMA etc. Process each dir 0-5 and then every set of 5 until 50 dirs and then every set of 10
function guppyFin {
    dirNum=$1
    outPath=$2
    if [[ $dirNum -le 5 ]]; then touch $outPath/guppy.fin
    elif [[ $dirNum -le 50 ]] && [[ $dirNum =~ [50]$ ]]; then touch $outPath/guppy.fin
    elif [[ $dirNum =~ 0$ ]]; then touch $outPath/guppy.fin
    fi
    }

inotifywait --exclude "intermediate|queued_reads|reads|reports|pings"  --timefmt "[%Y-%m-%d %H:%M:%S]" --format "%T %e %w%f" -m -r -e moved_to -e create $watchDir | while read INWOUTLINE; do 
	INWTRIGGER=$(echo $INWOUTLINE | rev | cut -d ' ' -f 1 | rev)
	echo $INWOUTLINE \(WATCHDIR=$watchDir\)>> $INWLOG
	if [[ $INWTRIGGER =~ fast5$ ]] && [[ ! $INWTRIGGER =~ platform_qc ]] && [[ ! -d $INWTRIGGER ]]; then	
		sleep 5
		fast5=$INWTRIGGER
		macflow=$(eval $RUNMETA $fast5 2>>$metaErr)
		gmacflow=$(echo $macflow | tr -d ' ')
		unset gst
		gst=$(grep $gmacflow $startTimes)
		[[ $gst ]] &&\
			runDate=$(echo $gst | cut -d ' ' -f 1) ||\
			(runDate=$(date -d @$(stat -c "%Z" $fast5) +%y%m%d) && echo $runDate $gmacflow >> $startTimes) \
			&& runDate=$(echo $(grep $gmacflow $startTimes) | cut -d ' ' -f 1)
		machine=$(echo $macflow | cut -d ' ' -f 1)
		flowcell=$(echo $macflow | cut -d ' ' -f 2)
		flowcell_type=$(echo $macflow | cut -d ' ' -f 3)
		seq_kit=$(echo $macflow | cut -d ' ' -f 4)
		fast5count=$(echo $macflow | cut -d ' ' -f 5)
		macRoot=$destRoot/${machineLocation}_Nanopore-MinION-${machine}
		[[ ! -d $macRoot ]] && mkdir $macRoot
		existingDir=$macRoot/${runDate}_${machine}_*_${flowcell}
		if ls $existingDir 1>/dev/null 2>&1 ; then
			destDir=$(readlink -f $existingDir)
		else
			preMaxCount=$(ls $macRoot | cut -d '_' -f 3 | sort -n | tail -1)
			preMaxCount=$((10#$preMaxCount)) # switch number to 10 base format from octal
			newMaxCount=$(printf "%05d" $((preMaxCount+1))) # format number with lead-padded zeros
			destDir=$macRoot/${runDate}_${machine}_${newMaxCount}_$flowcell
			mkdir -p $destDir/fast5
			mkdir $destDir/logs
		fi
		runID=$(basename $destDir)
		fast5number=$(echo $fast5 | rev | cut -d '_' -f1 |rev | cut -d '.' -f1)
		
		#fast5count=$(((fast5number+1)*4000))
		cmd="sqlite3 $MIAdb < <(echo -e \"insert into progress values ('$runID', 'FAST5', '$fast5count', '$(date "+%Y-%m-%d %H:%M:%S")');\")"
		MIALOG $cmd

		fast5destDir=$(basecalledDirFun $destDir/fast5 $fast5number $fast5number)
		mkdir -p $fast5destDir
		mv $fast5 $fast5destDir/
		basecalledDir=$(basecalledDirFun $destDir/fastq $fast5number $fast5number)
		[[ -z $pid ]] && echo '' &
		[[ -z $pid ]] && pid=$!
		# Following "tail --pid=$pid -f /dev/null" leading command waits for tail to run until $pid is terminated, thus queuing current guppy until previous guppy instance finishes
		cmd="tail --pid=$pid -f /dev/null && \
			$GUPPY -i $fast5destDir \
				   -s $basecalledDir \
				   --kit $seq_kit \
				   --flowcell $flowcell_type \
				   --cpu_threads_per_caller $THREADS 
				   >> $destDir/logs/guppy.log 2>&1 && \
			$DEMUX -i $basecalledDir \
				   -s $basecalledDir \
				   -t $THREADS \
				   -r 
				   >> $destDir/logs/guppy.log 2>&1 &"
		MIALOG $cmd
		pid=$!
		cmd="tail --pid=$pid -f /dev/null && guppyFin $fast5number $destDir &"
		MIALOG $cmd
		#pidWrapup=$pid
		# UPDATE ALBACORE_SUMMARY TABLE IN DB
		#runID=${runDate}_${machine}_${newMaxCount}_$flowcell
		cmd="tail --pid=$pid -f /dev/null && $gupSum2sqlite $runID $(basename $basecalledDir) $basecalledDir/sequencing_summary.txt $basecalledDir/barcoding_summary.txt 2>&1 >> $gupsumlog &"
		MIALOG $cmd
		cmd="tail --pid=$pid -f /dev/null && sqlite3 $MIAdb < <(echo -e \"insert into progress values ('$runID', 'FASTQ', '$(tail --pid=$pid -qn +2 $destDir/fastq/*/sequencing_summary.txt | wc -l)', '$(date "+%Y-%m-%d %H:%M:%S")');\")"
		MIALOG $cmd
        #tail --pid=$pidWrapup -f /dev/null && $updateFast5 $runID &
	fi
done
