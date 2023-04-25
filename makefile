#un makefile pour le dev

NEXTCLOUD_PATH := ${NC_WWW}

NEXTCLOUD_SCRIPTS := ${HOME}/scripts

ifeq ($(NEXTCLOUD_PATH), )
	NEXTCLOUD_PATH = ../web
endif

NEXTCLOUD_OWNER := ${NC_OWNER}
NEXTCLOUD_GROUP := ${NC_GROUP}

ifeq ($(NEXTCLOUD_OWNER), )
	NEXTCLOUD_OWNER := ${USER}
endif

ifeq ($(NEXTCLOUD_GROUP), )
	NEXTCLOUD_GROUP := ${USER}
endif

DIST = $(NEXTCLOUD_PATH)/dist
APPS = $(NEXTCLOUD_PATH)/apps

LOADER=cssjsloader
SCSS=$(LOADER)/scss
CSS=$(LOADER)/inputs/css


ALLETAB=allEtab_ncgip.txt

defaut:
	@echo SCRIPTS LDAPIMPORTER COLLABORA OOPATCH SKELETON USER_CAS
	@echo user_cas a faire qu'a la 1er install du plugin (a vérifier)
	@echo ${USER} $(NEXTCLOUD_PATH)
	



SCRIPTS: 
	cp -rvu scripts/* $(NEXTCLOUD_SCRIPTS)/
	cp -uv $(ALLETAB) $(NEXTCLOUD_SCRIPTS)/allEtab.txt
	$(NEXTCLOUD_SCRIPTS)/diffEtab.pl

LDAPIMPORTER:
	cp -rvT ldapimporter $(APPS)/ldapimporter

OOPATCH: 
	cp apps/onlyoffice/js/main.js $(NEXTCLOUD_PATH)/apps/onlyoffice/js/main.js

COLLABORA:
	find apps/richdocuments -type f -exec cp \{\} $(NEXTCLOUD_PATH)/\{\} \;
	find apps/onlyoffice -type f -exec cp \{\} $(NEXTCLOUD_PATH)/\{\} \;

SKELETON:
	cp -rvT skeleton $(NEXTCLOUD_PATH)/core/skeleton

USER_CAS:
	find apps/user_cas -type f -exec cp \{\} $(NEXTCLOUD_PATH)/\{\} \;

ifneq (${USER}, ncgip)
CSSJSLOADER:
	cp -rvT cssjsloader  $(APPS)/cssjsloader 


FILES_SHARING:
	mkdir -p ./backups
	mkdir -p ./backups/files_sharing_app_last
	mkdir -p ./backups/files_sharing_dist_last
	rsync -v -a --delete $(APPS)/files_sharing/ ./backups/files_sharing_app_last/
	rsync -v -a --delete --include='files_sharing-files_sharing_tab*' --exclude='*' $(DIST)/ ./backups/files_sharing_dist_last/
	rsync -v -a --delete --chown=$(NEXTCLOUD_OWNER):$(NEXTCLOUD_GROUP) ./files_sharing/app/ $(APPS)/files_sharing/
	rsync -v -a --chown=$(NEXTCLOUD_OWNER):$(NEXTCLOUD_GROUP) ./files_sharing/dist/ $(DIST)/

RESTORE_FILES_SHARING:
	rsync -v -a --delete --chown=$(NEXTCLOUD_OWNER):$(NEXTCLOUD_GROUP) ./backups/files_sharing_app_last/ $(APPS)/files_sharing/
	rsync -v -a --chown=$(NEXTCLOUD_OWNER):$(NEXTCLOUD_GROUP) ./backups/files_sharing_dist_last/ $(DIST)/


LIB: 
	cp -rvT  $(NEXTCLOUD_PATH)/lib
	cp apps/dav/lib/CardDAV/CardDavBackend.php $(NEXTCLOUD_PATH)/apps/dav/lib/CardDAV/CardDavBackend.php

CSS: 
	cp $(CSS)/reciaStyle.css $(APPS)/$(CSS)/

endif

sass: $(CSS)/reciaStyle.css

$(CSS)/%.css: $(SCSS)/*.scss
	sass  $(SCSS)/$*.scss $@
