date
rlog=$HOME/logs-esco
fdata=$HOME/data
rcode=$HOME/esco-nextcloud-plugins

find $rlog \( -name '*.log' -o -name '*.log.*gz' \) -a -ctime +7 -delete


/bin/tar -czf $rlog/Loader/loadEtab.log.`date +'%d.%Hh'`.tgz $rlog/Loader/*.log.gz $fdata/allEtab.*

#echo Arret des chargements Nextcloud
#exit 1
/usr/bin/nice $rcode/loadEtabs.pl all 2>&1 | /bin/grep -v '=>'


$rcode/diffEtab.pl

date

$rcode/saveBucketId.pl

/bin/gzip $rlog/cleanBucket.*.log 

logClean=$rlog/cleanBucket.`date +'%d'`.log

echo nettoyage de nc-prod-0
/usr/bin/nice $rcode/cleanBucket.pl s3://nc-prod-0 90 all > $logClean

tail -1 $logClean

echo nettoyage de nc-prod-corbeille
/usr/bin/nice $rcode/cleanBucket.pl s3://nc-prod-corbeille all >> $logClean

tail -1 $logClean

date

echo suppression des groupes vides
logClean=$rlog/deleteGroupeVide.`date +'%d'`.log
/usr/bin/nice $rcode/deleteGroupeVide.pl >  $logClean 

grep -v 'was removed' $logClean

date
