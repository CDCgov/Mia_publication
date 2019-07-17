#!/bin/bash
# Mia installer
[[ ! $EUID -eq 0 ]] && printf "\n\tMust run as sudo\n\n" && exit

# For logger
dpkg -l moreutils >/dev/null 2>&1 || apt install moreutils

# Direct stdout/stderr to log with 'run' function
scripts=$(dirname $(readlink -f $0))
log=$scripts/logs/install.log
function run {
	echo CMD=\"$@\" > >(ts '[%Y-%m-%d %H:%M:%S]		' >> $log) 2> >(ts '[%Y-%m-%d %H:%M:%S](stderr)	' >> $log)
	eval $@ > >(ts '[%Y-%m-%d %H:%M:%S]		' >> $log) 2> >(ts '[%Y-%m-%d %H:%M:%S](stderr)	' >> $log)
}
function echol {
	echo \*\* "$@" already installed \*\* > >(ts '[%Y-%m-%d %H:%M:%S]' >> $log)
}

#### [Python 3.5 and 2.7](https://www.python.org/downloads/release/python-357/)
cmd="apt-get install python3.5"
dpkg -l python3 >/dev/null 2>&1 && echol python3.5 || run $cmd
cmd="apt-get install python2.7"
dpkg -l python2.7 >/dev/null 2>&1 && echol python2.7 || run $cmd

#### [MinKnow](https://community.nanoporetech.com/protocols/experiment-companion-minknow/v/mke_1013_v1_revao_11apr2016/installing-minknow-on-linu)
cmd="apt-get update;
apt-get install wget;
wget -O- https://mirror.oxfordnanoportal.com/apt/ont-repo.pub | apt-key add -;
echo deb http://mirror.oxfordnanoportal.com/apt xenial-stable non-free | tee /etc/apt/sources.list.d/nanoporetech.sources.list;
apt-get update;
apt-get install minknow-nc;"
dpkg -l minknow-nc >/dev/null 2>&1 && echol minknow || run $cmd

#### [Guppy](https://community.nanoporetech.com/protocols/Guppy-protocol/v/gpb_2003_v1_revl_14dec2018/linux-guppy)
export PLATFORM=$(lsb_release -cs)
cmd="apt-get update;
apt-get install wget lsb-release;
wget -O- https://mirror.oxfordnanoportal.com/apt/ont-repo.pub | apt-key add -;
echo deb http://mirror.oxfordnanoportal.com/apt ${PLATFORM}-stable non-free | tee /etc/apt/sources.list.d/nanoporetech.sources.list;
apt-get update;
apt-get install ont-guppy;"
dpkg -l ont-guppy >/dev/null 2>&1 && echol guppy || run $cmd

#### [inotifywait](https://packages.debian.org/source/jessie/inotify-tools)
cmd="apt-get install inotify-tools"
dpkg -l inotify-tools >/dev/null 2>&1 && echol inotify-tools || run $cmd

cd $scripts && cd ../bin
#### [Aliview](http://www.ormbunkar.se/aliview/downloads/linux/linux-version-1.26/)
cmd="wget http://www.ormbunkar.se/aliview/downloads/linux/linux-version-1.26/aliview.install.run;
chmod +x aliview.install.run;
./aliview.install.run;"
[[ $(aliview -v >/dev/null 2>&1) ]] && echol aliview || run $cmd

#### [IRMA: Iterative Refinement MetaAssembler](https://wonder.cdc.gov/amd/flu/irma/install.html)
cmd="wget https://wonder.cdc.gov/amd/flu/irma/flu-amd.zip;
unzip flu-amd.zip;"
[[ -f ./flu-amd/IRMA ]] && echol irma || run $cmd

#### [FastTree Double Precision](http://www.microbesonline.org/fasttree/#Install)
cmd="get http://www.microbesonline.org/fasttree/FastTreeDbl"
[[ -f ./FastTreeDbl ]] && echol fasttree || run $cmd

#### [Muscle](http://www.drive5.com/muscle/)
cmd="wget http://www.drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86linux64.tar.gz;
tar -xzf muscle3.8.31_i86linux64.tar.gz;"
[[ -f ./muscle ]] && echol muscle || run $cmd

#### [R](https://mran.microsoft.com/open)
cmd="wget https://mran.blob.core.windows.net/install/mro/3.5.3/ubuntu/microsoft-r-open-3.5.3.tar.gz;
tar -xf microsoft-r-open-3.5.3.tar.gz;
microsoft-r-open/install.sh -a -u;"
[[ -d microsoft-r-open ]] && echol microsoft-r-open || run $cmd

cd ../lib

#### [BLAST+](https://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download)
cmd="wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.9.0+-x64-linux.tar.gz;
tar -xzf ncbi-blast-2.9.0+-x64-linux.tar.gz;"
[[ $(ls ncbi-blast-*/bin/blastn 2>/dev/null) ]] && echol blastn || run $cmd

cd ../scripts

##### R dependencies
cmd="Rscript install_R_libs.R"
run $cmd

#### Swith to user
su $(who am i | cut -d ' ' -f1)

## Build database and initialize references
cmd="bash createMIAdb.sh"
run $cmd

## Create Desktop Icon
cmd="bash makeDesktopIcon.sh"
run $cmd

## Set crontab
cmd="bash setCron.sh"
run $cmd
