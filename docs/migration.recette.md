## migration de nextcloud  sur recette

	$ NcOld=30.0.8
	$ NcNew=30.0.16

 
### Pousser la nouvelle version de NC et de notre git :

	esco-nextcloud-plugins> cd ~/esco-nextcloud-plugins
	esco-nextcloud-plugins> git fetch
	esco-nextcloud-plugins> git checkout ncEnt/v$NcNew

### passer en mode maintenance:

	> cd ~/web
	> web$ php occ maintenance:mode --on

### arret du cron
	> crontab -e

### dump de la base : 
pas fait

	
### arret du server web apache ,
a ne pas faire en recette cela arrete tous les NC de prod

#	> #sudo systemctl stop apache2.service

#### faire la sauvegared de l'ancienne version

	> cd ; tar -cvzf nextcloud.recette.$NcOld.tgz web

### suppression ancien rep
	> cd ; rm -r nextcloud

### on deploie la nouvelle version dans nextcloud
	
	scp -P 2022  nextcloud-$NcNew.tar.bz2  ncrecette@nextcloud.recia.aquaray.com:
	> tar -xvjf nextcloud-$NcNew.tar.bz2

### copie la conf

	> cp web/config/config.php nextcloud/config/config.php


#### comparaison des plugins :
	> ls web/apps/ > ~/nc_apps.$NcOld
	> ls nextcloud/apps/ > ~/nc_apps.$NcNew
	> diff ~/nc_apps.$NcOld ~/nc_apps.$NcNew
5d4
< calendar
18d16
< files_markdown
24d21
< files_videoplayer
26,28d22
< forms
< groupfolders
< ldapimporter
32d25
< notes
34d26
< notify_push
36d27
< onlyoffice
56d46
< user_cas
59d48
< user_usage_report



#### on copie les plugins manquant (verifier la liste ci-dessous) :
	cd web/apps
	for i in  calendar  files_markdown files_videoplayer  forms    groupfolders  notes notify_push  onlyoffice    user_cas user_usage_report   ;  do cp -R $i ~/nextcloud/apps ; done;


#### les notres :

on efface d'abort le skeleton:

	> cd
	> rm -r  ~/nextcloud/core/skeleton/*

	> cd ~/esco-nextcloud-plugins
	> git pull
	> cp -rvT ldapimporter ~/nextcloud/apps/ldapimporter
	> cp -rvT skeleton ~/nextcloud/core/skeleton
	# cp -rvT cssjsloader  ~/nextcloud/apps/cssjsloader

ne pas mettre notre files_sharing ni anotation tout de suite attendre la fin de la migration
#> rsync -v -a --delete  ./files_sharing/ ~/nextcloud/apps/files_sharing/



#### copier le nouveau NC dans web

	> cd
	> rsync -v -a --delete ~/nextcloud/ ~/web/
	> cd ~/esco-nextcloud-plugins/
	> make LIB
	> make SCRIPTS
	> make THEME
	> make USER_CAS
	> make CONFIG
	> make SETTINGS_APP 




#### attendre la fin du dump et  Lancer la migration

	> cd ~/web
	> php occ upgrade
il y a eu unprobleme avec la classe S3Recia mal nomme S3 corrigé et relance de upgrade
...
Update successful
Maintenance mode is kept active
Resetting log level



#### connexion à l'UI
	> php occ maintenance:mode --off
	
#### ajout index manquants
	#> php occ db:add-missing-columns
	> php occ db:add-missing-indices
	#> php occ maintenance:repair --include-expensive

	
#### convertion en big int de certaine table

	# 	php occ maintenance:mode --on
	#	php  occ db:convert-filecache-bigint
	#   php occ maintenance:mode --off

	# mettre a jour le applie non mise a jour:
	web> 	php occ app:update --all


	#old methode de calcul des droit dans groupfolders
    > php occ config:app:set groupfolders acl-inherit-per-user --value true
connexion à l'UI


	php occ setupchecks


#Le reste n'est pas fait pour la version intermediare 30.0.16
#### files_sharing  

	> cd ~/esco-nextcloud-plugins/
#	> tar -cvzf backup.last.tgz backups
#	> rm -r backups/*
	> make FILES_SHARING
	> make NOTIFICATIONS

### autre commande occ avant le cron
	# suppression de mail quand un compte change de groupe	
    > php occ config:app:set settings disable_activity.email_address_changed_by_admin --value yes

#### vérifier Onlyffice
	aller dans administration:ONLYOFFICE -> save 

####relancé le cron:
	> ~/scripts/launchNextcloudCron.sh
	> crontab -e 
