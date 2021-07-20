day=`date +%d`
path=$HOME/logs-esco/nextcloud.cron
log=$path.$day.log
err=$path.error.$day.log
date >> $log
date >> $err
php  -f $HOME/web/cron.php  >> $log 2>> $err

