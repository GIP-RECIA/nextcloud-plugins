day=`date +%d`
path=/var/www/ncprod.recia/logs-esco/nextcloud.cron
log=$path.$day.log
err=$path.error.$day.log
date >> $log
date >> $err
php  -f /var/www/ncprod.recia/web/cron.php  >> $log 2>> $err

