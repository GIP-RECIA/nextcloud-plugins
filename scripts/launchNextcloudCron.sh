#!/bin/bash
day=`date +%d`
path=$HOME/logs-esco/NCcron

#on ne garde les logs que 7 jours.
find $path -name '??.?.log' -a -ctime +7 -delete

log=$path/$day.log

lock=$path/lock

function executeCron {
	log=$path/$day.$1.log
	date '+%F %T' >> $log
        php   -d memory_limit=4G  -f $HOME/web/cron.php 2>&1 | tee -a  $log
    date '+%T' >> $log
    return 0
}

# indiqué le nombre de cron possiblement éxécuté un même temps 
for i in 1 
do
(flock -n 9  &&  executeCron $i
) 9>${lock}$i && exit 0
done

exit 1
