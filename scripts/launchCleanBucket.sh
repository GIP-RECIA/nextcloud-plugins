date
rlog=$HOME/logs-esco
fdata=$HOME/data
rcode=$HOME/scripts

	# nétoyage du bucket 0 peut être tres long donc on verrouille pour ne pas en lancer 2 à la fois
lock=$HOME/logs-esco/lockCleanBucket

(flock -n 9 || exit 1 ; # si il y a un verrou on sort sans rien faire
	logClean=$rlog/cleanBucket.`date +'%d'`.log
	echo "\nnettoyage de nc-prod-0 encours"
	/usr/bin/nice $rcode/cleanBucket.pl s3://nc-prod-0 90 all > $logClean
	date 
	tail -1 $logClean

	date
	echo "\nnettoyage de nc-prod-corbeille"
	/usr/bin/nice $rcode/cleanBucket.pl s3://nc-prod-corbeille all >> $logClean
	date
	tail -1 $logClean
	echo "\nnettoyage de nc-prod terminé"
) 9>${lock}

