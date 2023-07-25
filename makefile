

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


ALLETAB=allEtab.txt
defaut:
	@echo SCRIPTS CSSJSLOADER FILES_SHARING LDAPIMPORTER SKELETON LIB CSS THEME PATCH CONFIG USER_CAS RESTORE_FILES_SHARING
	@echo user_cas a faire qu'a la 1er install du plugin (a vérifier)
	@echo ${USER} $(NEXTCLOUD_PATH) 


SCRIPTS: 
	cp -rvu scripts/* $(NEXTCLOUD_SCRIPTS)/
	cp -uv $(ALLETAB) $(NEXTCLOUD_SCRIPTS)/allEtab.txt
	$(NEXTCLOUD_SCRIPTS)/diffEtab.pl

LDAPIMPORTER:
	cp -rvT ldapimporter $(APPS)/ldapimporter


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

SKELETON:
	cp -rvT skeleton $(NEXTCLOUD_PATH)/core/skeleton

USER_CAS:
	find apps/user_cas -type f -exec cp \{\} $(NEXTCLOUD_PATH)/\{\} \;
LIB: 
	cp -riTbv lib $(NEXTCLOUD_PATH)/lib

PATCH:
	cp apps/dav/lib/CardDAV/CardDavBackend.php $(NEXTCLOUD_PATH)/apps/dav/lib/CardDAV/CardDavBackend.php
	cp apps/text/lib/Db/SessionMapper.php $(NEXTCLOUD_PATH)/apps/text/lib/Db/SessionMapper.php

CSS: 
	cp $(CSS)/reciaStyle.css $(APPS)/$(CSS)/

THEME:
	cp -riTv themes/esco $(NEXTCLOUD_PATH)/themes/esco
	cp core/css/variables.scss $(NEXTCLOUD_PATH)/core/css/variables.scss

CONFIG: config/*.json
	cp config/*.json $(NEXTCLOUD_PATH)/config/

sass: $(CSS)/reciaStyle.css

$(CSS)/%.css: $(SCSS)/*.scss
	sass  $(SCSS)/$*.scss $@
