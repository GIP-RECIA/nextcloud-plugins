## migration de nextcloud  sur recette

	$ NcOld=30.0.16
	$ NcNew=31.0.9

 
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
39a31
> profile
56d47
< user_cas
59d49
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
il y a eu un probleme
PHP Fatal error:  Declaration of OC\Files\ObjectStore\ReciaObjectStoreStorage::stat($path) must be compatible with OC\Files\ObjectStore\ObjectStoreStorage::stat(string $path): array|false in /var/www/ncrecette.recia/web/lib/private/Files/ObjectStore/ReciaObjectStoreStorage.php on line 51

Modifier OC\Files\ObjectStore\ReciaObjectStoreStorage::stat($path) 
J'ai relancé et obtenu :
An unhandled exception has been thrown:
ParseError: syntax error, unexpected token "array", expecting ";" or "{" in /var/www/ncrecette.recia/web/lib/private/Files/ObjectStore/ReciaObjectStoreStorage.php:51
Stack trace:
#0 /var/www/ncrecette.recia/web/lib/composer/composer/ClassLoader.php(427): Composer\Autoload\{closure}('/var/www/ncrece...')
#1 [internal function]: Composer\Autoload\ClassLoader->loadClass('OC\\Files\\Object...')
#2 /var/www/ncrecette.recia/web/lib/private/Files/Mount/MountPoint.php(141): class_exists('OC\\Files\\Object...')
#3 /var/www/ncrecette.recia/web/lib/private/Files/Mount/MountPoint.php(170): OC\Files\Mount\MountPoint->createStorage()
#4 /var/www/ncrecette.recia/web/lib/private/Files/View.php(1420): OC\Files\Mount\MountPoint->getStorage()
#5 /var/www/ncrecette.recia/web/lib/private/Files/Node/Root.php(178): OC\Files\View->getFileInfo('/appdata_ocbzxy...', false)
#6 /var/www/ncrecette.recia/web/lib/private/Files/Node/LazyFolder.php(138): OC\Files\Node\Root->get('/appdata_ocbzxy...')
#7 /var/www/ncrecette.recia/web/lib/private/Files/AppData/AppData.php(80): OC\Files\Node\LazyFolder->get('appdata_ocbzxyi...')
#8 /var/www/ncrecette.recia/web/lib/private/Files/AppData/AppData.php(111): OC\Files\AppData\AppData->getAppDataFolder()
#9 /var/www/ncrecette.recia/web/lib/private/App/AppStore/Fetcher/Fetcher.php(130): OC\Files\AppData\AppData->getFolder('/')
#10 /var/www/ncrecette.recia/web/lib/private/App/AppStore/Fetcher/AppFetcher.php(156): OC\App\AppStore\Fetcher\Fetcher->get(false)
#11 /var/www/ncrecette.recia/web/lib/private/Installer.php(391): OC\App\AppStore\Fetcher\AppFetcher->get(false)
#12 /var/www/ncrecette.recia/web/lib/private/Updater.php(385): OC\Installer->isUpdateAvailable('app_api')
#13 /var/www/ncrecette.recia/web/lib/private/Updater.php(245): OC\Updater->upgradeAppStoreApps(Array)
#14 /var/www/ncrecette.recia/web/lib/private/Updater.php(100): OC\Updater->doUpgrade('31.0.9.1', '30.0.16.1')
#15 /var/www/ncrecette.recia/web/core/Command/Upgrade.php(192): OC\Updater->upgrade()
#16 /var/www/ncrecette.recia/web/3rdparty/symfony/console/Command/Command.php(326): OC\Core\Command\Upgrade->execute(Object(Symfony\Component\Console\Input\ArgvInput), Object(Symfony\Component\Console\Output\ConsoleOutput))
#17 /var/www/ncrecette.recia/web/3rdparty/symfony/console/Application.php(1078): Symfony\Component\Console\Command\Command->run(Object(Symfony\Component\Console\Input\ArgvInput), Object(Symfony\Component\Console\Output\ConsoleOutput))
#18 /var/www/ncrecette.recia/web/3rdparty/symfony/console/Application.php(324): Symfony\Component\Console\Application->doRunCommand(Object(OC\Core\Command\Upgrade), Object(Symfony\Component\Console\Input\ArgvInput), Object(Symfony\Component\Console\Output\ConsoleOutput))
#19 /var/www/ncrecette.recia/web/3rdparty/symfony/console/Application.php(175): Symfony\Component\Console\Application->doRun(Object(Symfony\Component\Console\Input\ArgvInput), Object(Symfony\Component\Console\Output\ConsoleOutput))
#20 /var/www/ncrecette.recia/web/lib/private/Console/Application.php(187): Symfony\Component\Console\Application->run(Object(Symfony\Component\Console\Input\ArgvInput), Object(Symfony\Component\Console\Output\ConsoleOutput))
#21 /var/www/ncrecette.recia/web/console.php(87): OC\Console\Application->run(Object(Symfony\Component\Console\Input\ArgvInput))
#22 /var/www/ncrecette.recia/web/occ(33): require_once('/var/www/ncrece...')
#23 {main}
un probleme de : qui manquait
...
Update successful
Maintenance mode is kept active
Resetting log level

	php occ setupchecks
	
#### connexion à l'UI
	> php occ maintenance:mode --off
	
#### ajout index manquants
	#> php occ db:add-missing-columns
	> php occ db:add-missing-indices
	> php occ maintenance:repair --include-expensive

	
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
               ⚠ MySQL row format: Incorrect row format found in your database. ROW_FORMAT=Dynamic offers the best database performances for Nextcloud. Please update row format on the following list: oc_accounts, oc_accounts_data, oc_activity, oc_activity_mq, oc_addressbookchanges, oc_addressbooks, oc_appconfig, oc_appointments_hash, oc_appointments_pref, oc_appointments_sync, oc_asso_uai_user_group, oc_authorized_groups, oc_authtoken, oc_bbb_restrictions, oc_bbb_room_shares, oc_bbb_rooms, oc_bruteforce_attempts, oc_calendar_appt_bookings, oc_calendar_appt_configs, oc_calendar_invitations, oc_calendar_reminders, oc_calendar_resources, oc_calendar_resources_md, oc_calendar_rooms, oc_calendar_rooms_md, oc_calendarchanges, oc_calendarobjects, oc_calendarobjects_props, oc_calendars, oc_calendarsubscriptions, oc_cards, oc_cards_properties, oc_carnet_metadata, oc_cengine_steps, oc_cengine_users, oc_circle_circles, oc_circle_clouds, oc_circle_groups, oc_circle_gsevents, oc_circle_gsshares, oc_circle_gsshares_mp, oc_circle_links, oc_circle_members, oc_circle_shares, oc_circle_tokens, oc_circles_circle, oc_circles_event, oc_circles_member, oc_circles_membership, oc_circles_mount, oc_circles_mountpoint, oc_circles_remote, oc_circles_share_lock, oc_circles_token, oc_collectives, oc_collectives_pages, oc_collectives_shares, oc_collectives_u_settings, oc_collres_accesscache, oc_collres_collections, oc_collres_resources, oc_comments, oc_comments_read_markers, oc_dashboard_data, oc_dav_cal_proxy, oc_dav_shares, oc_deck_assigned_labels, oc_deck_assigned_users, oc_deck_attachment, oc_deck_board_acl, oc_deck_boards, oc_deck_cards, oc_deck_labels, oc_deck_stacks, oc_direct_edit, oc_directlink, oc_documentserver_changes, oc_documentserver_ipc, oc_documentserver_locks, oc_documentserver_sess, oc_etablissements, oc_external_applicable, oc_external_config, oc_external_mounts, oc_external_options, oc_federated_reshares, oc_file_locks, oc_filecache, oc_filecache_extended, oc_files_trash, oc_flow_checks, oc_flow_operations, oc_flow_operations_scope, oc_group_admin, oc_group_folders, oc_group_folders_acl, oc_group_folders_groups, oc_group_folders_manage, oc_group_folders_trash, oc_group_user, oc_groups, oc_jobs, oc_known_users, oc_ldap_group_mapping, oc_ldap_group_members, oc_ldap_user_mapping, oc_login_flow_v2, oc_mail_accounts, oc_mail_aliases, oc_mail_attachments, oc_mail_classifiers, oc_mail_coll_addresses, oc_mail_local_messages, oc_mail_mailboxes, oc_mail_message_tags, oc_mail_messages, oc_mail_provisionings, oc_mail_recipients, oc_mail_tags, oc_mail_trusted_senders, oc_migrations, oc_mimetypes, oc_mounts, oc_notes_meta, oc_notifications, oc_notifications_pushhash, oc_notifications_settings, oc_oauth2_access_tokens, oc_oauth2_clients, oc_officeonline_locks, oc_officeonline_wopi, oc_onlyoffice_filekey, oc_onlyoffice_permissions, oc_polls_comments, oc_polls_log, oc_polls_notif, oc_polls_options, oc_polls_polls, oc_polls_preferences, oc_polls_share, oc_polls_votes, oc_polls_watch, oc_preferences, oc_privacy_admins, oc_profile_config, oc_properties, oc_quicknotes_attach, oc_quicknotes_colors, oc_quicknotes_note_tags, oc_quicknotes_notes, oc_quicknotes_shares, oc_quicknotes_tags, oc_ratelimit_entries, oc_recent_contact, oc_recia_user_history, oc_richdocuments_assets, oc_richdocuments_direct, oc_richdocuments_wopi, oc_schedulingobjects, oc_share, oc_share_external, oc_storages, oc_storages_credentials, oc_systemtag, oc_systemtag_group, oc_systemtag_object_mapping, oc_talk_attendees, oc_talk_bridges, oc_talk_commands, oc_talk_internalsignaling, oc_talk_rooms, oc_talk_sessions, oc_termsofservice_sigs, oc_termsofservice_terms, oc_text_documents, oc_text_sessions, oc_text_steps, oc_trusted_servers, oc_twofactor_backupcodes, oc_twofactor_providers, oc_user_cas_ticket, oc_user_status, oc_user_transfer_owner, oc_users, oc_vcategory, oc_vcategory_to_object, oc_webauthn, oc_whats_new, oc_wopi_assets, oc_wopi_direct, oc_wopi_locks, oc_wopi_tokens, oc_wopi_wopi.

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
