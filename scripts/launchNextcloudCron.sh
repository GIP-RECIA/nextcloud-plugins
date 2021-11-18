day=`date +%d`
path=$HOME/logs-esco/NCcron

log=$path/$day.log

lock=$path/lock

date '+%F %T' >> $log
(flock -n 7 || flock -n 8 || flock -n 9 || exit 1;
        php  -f $HOME/web/cron.php 2>&1 | tee -a  $log 
) 7>${lock}7 8>${lock}8 9>${lock}9
date '+%T' >> $log



