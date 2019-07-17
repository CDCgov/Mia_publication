#!/bin/bash

if [[ ! $(grep -s dataSense <(crontab -l)) ]] ; then
	rootsed=$(readlink -f $(dirname $0) | sed 's/\//\\\//g' | rev | cut -d '/' -f 2- | rev)
	rootsed=${rootsed::-1}

	root=$(readlink -f $(dirname $0) | rev | cut -d '/' -f 2- | rev)
	#root=${root::-1}

	sed -i "s/ROOT/${rootsed}/g" ${root}/scripts/cron.txt

	t=$(mktemp)
	crontab -l > $t
	cat ${root}/scripts/cron.txt >> $t
	crontab $t
fi
