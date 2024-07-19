
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
THEME_ESCO=themes/esco
SCSS=$(THEME_ESCO)/scss
CSS=$(THEME_ESCO)/css

ALLETAB=allEtab.txt

defaut:
	@echo SCRIPTS CSSJSLOADER FILES_SHARING LDAPIMPORTER SKELETON LIB THEME PATCH CONFIG USER_CAS NOTIFICATIONS
	@echo "user_cas a faire qu'a la 1er install du plugin (a vérifier)"
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
	rsync -av files_sharing/dist/* $(DIST)
	rsync -av files_sharing/app/* $(APPS)/files_sharing --exclude src
	rsync -av --chown=$(NEXTCLOUD_OWNER):$(NEXTCLOUD_GROUP) $(DIST)

NOTIFICATIONS:
	cp -rv apps/notifications/* $(NEXTCLOUD_PATH)/apps/notifications

SETTINGS_APP:
	cp -rv apps/settings/* $(NEXTCLOUD_PATH)/apps/settings

SKELETON:
	cp -rvT skeleton $(NEXTCLOUD_PATH)/core/skeleton

USER_CAS:
	find apps/user_cas -type f -exec cp \{\} $(NEXTCLOUD_PATH)/\{\} \;
LIB: 
	cp -riTbv lib $(NEXTCLOUD_PATH)/lib

PATCH:
	cp apps/dav/lib/CardDAV/CardDavBackend.php $(NEXTCLOUD_PATH)/apps/dav/lib/CardDAV/CardDavBackend.php

THEME:
	cp -riTv themes/esco $(NEXTCLOUD_PATH)/themes/esco
	cp core/css/variables.scss $(NEXTCLOUD_PATH)/core/css/variables.scss

CONFIG: config/*.json
	cp config/*.json $(NEXTCLOUD_PATH)/config/

sass: --style compressed $(CSS)/reciaStyle.css

$(CSS)/%.css: $(SCSS)/*.scss
	sass  $(SCSS)/$*.scss $@
