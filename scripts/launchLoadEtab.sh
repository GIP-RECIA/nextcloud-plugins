date
rlog=$HOME/logs-esco
fdata=$HOME/data
rcode=$HOME/scripts


	find $rlog \( -name '*.log' -o -name '*.log.*gz' \) -a -ctime +7 -delete


	/bin/tar -czf $rlog/Loader/loadEtab.log.`date +'%d.%Hh'`.tgz $rlog/Loader/*.log.gz $fdata/allEtab.*

#pour poser des verrous empechant l'execution  des cron NC. Si le process termine tardivement
lock=$HOME/logs-esco/NCcron/lock

#si les cron tourne on vire leurs verous pour pouvoir passer quand même

rm ${lock}1 ${lock}2 ${lock}3

# et on repose les verous pour les empécher de revenir
(flock -x 7 ; flock -x 8 ; flock -x 9;

	/usr/bin/nice $rcode/GroupFolder/loadGroupFolders.pl -l 3 up 2>&1 | /usr/bin/perl -n -e 'END{map {print ">$_";} @ERROR;} push @ERROR , $_ if /error/i; next if /=>/; print;'
	/usr/bin/nice $rcode/loadEtabs.pl all 2>&1 | /usr/bin/perl -n -e 'END{map {print ">$_";} @ERROR;} push @ERROR , $_ if /error/i; next if /=>/; print;'

) 7>${lock}1 8>${lock}2 9>${lock}3

	$rcode/diffEtab.pl

	date

	$rcode/saveBucketId.pl

	/bin/gzip $rlog/*.log 

	logClean=$rlog/cleanBucket.`date +'%d'`.log

	echo "\nnettoyage de nc-prod-0"
	/usr/bin/nice $rcode/cleanBucket.pl s3://nc-prod-0 90 all > $logClean

	tail -1 $logClean

	echo "\nnettoyage de nc-prod-corbeille"
	/usr/bin/nice $rcode/cleanBucket.pl s3://nc-prod-corbeille all >> $logClean

	tail -1 $logClean

	date
	logClean=$rlog/cleanGroup.`date +'%d'`.log

	echo "\nsuppression des comptes désactivés dans les groupes"

	echo "/usr/bin/nice $rcode/cleanGroup.pl all" > $logClean
	/usr/bin/nice $rcode/cleanGroup.pl all >> $logClean 2>&1
	grep -v 'INFO' $logClean

	date
	logClean=$rlog/deleteGroupeVide.`date +'%d'`.log

	echo "\nsuppression des groupes vides"
	echo "/usr/bin/nice $rcode/deleteGroupeVide.pl all" >  $logClean 
	/usr/bin/nice $rcode/deleteGroupeVide.pl all 2>&1  >>  $logClean 

	grep -v 'was removed' $logClean

	date

	echo "\nVerification que loadEtab soit  terminé sans erreur:\n ";
	gunzip -c rlog/Loader/*.log.gz | $rcode/uidKo.pl

	date

	#echo "\nsuppression définitive des comptes obsolètes"
	#/usr/bin/nice $rcode/removeOldUser.pl -n 1500 -l 4 2>&1

	#date
