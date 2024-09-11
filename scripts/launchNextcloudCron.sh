#!/bin/bash
day=`date +%d`
path=$HOME/logs-esco/NCcron


log=$path/$day.log

lock=$path/lock

lck=7

(flock -n $lck || flock -n $((++lck)) || flock -n $((++lck)) || exit 1;
	log=$path/$day.$lck.log
	date '+%F %T' >> $log
        php  -f $HOME/web/cron.php 2>&1 | tee -a  $log
    date '+%T' >> $log

) 7>${lock}7 8>${lock}8 9>${lock}9
