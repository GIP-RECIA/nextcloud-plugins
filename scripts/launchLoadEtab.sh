date
rlog=$HOME/logs-esco
fdata=$HOME/data
rcode=$HOME/scripts

find $rlog \( -name '*.log' -o -name '*.log.*gz' \) -a -ctime +7 -delete
find $rlog  -name 'groupFolders.*.log' -exec gzip  \{\} \;

/bin/tar -czf $rlog/Loader/loadEtab.log.`date +'%d.%Hh'`.tgz $rlog/Loader/*.log.gz $fdata/allEtab.*

#echo Arret des chargements Nextcloud
#exit 1
/usr/bin/nice $rcode/GroupFolder/loadGroupFolders.pl -u -l 4 all 2>&1 | /usr/bin/perl -n -e 'END{map {print ">$_";} @ERROR;} push @ERROR , $_ if /error/i; next if /=>/; print;'

$rcode/diffEtab.pl


date

echo suppression des groupes vides
logClean=$rlog/deleteGroupeVide.`date +'%d'`.log
/usr/bin/nice $rcode/deleteGroupeVide.pl LDAP >  $logClean 

grep -v 'was removed' $logClean

date
