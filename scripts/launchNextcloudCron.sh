#!/bin/bash
day=`date +%d`
path=$HOME/logs-esco/NCcron

log=$path/$day.log

lock=$path/lock

function executeCron {
	log=$path/$day.$1.log
	date '+%F %T' >> $log
	
	php  -f $HOME/web/cron.php 2>&1 | tee -a  $log

	date '+%T' >> $log
    return 0
}

for i in 1 2 3
do
(flock -n 9  &&  executeCron $i
) 9>${lock}$i && exit 0
done

exit 1
