
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
	@echo "USER:\t\t${USER}\nNEXTCLOUD_PATH:\t$(NEXTCLOUD_PATH)"
	@echo ""
	@echo "Availables commands:"
	@echo " SCRIPTS"
	@echo " CONFIG"
	@echo " LIB"
	@echo " THEME"
	@echo " SKELETON"
	@echo "### Plugins ###"
	@echo " USER_CAS\tonly on first install (to check)"
	@echo " LDAPIMPORTER"
	@echo " DAV"
	@echo " CSSJSLOADER"
	@echo " SETTINGS or SETTINGS_APP"
	@echo " NOTIFICATIONS"
	@echo " FILES_SHARING"
	@echo " CALENDAR"
	@echo " ONLYOFFICE"

SCRIPTS: 
	cp -rvu scripts/* $(NEXTCLOUD_SCRIPTS)/
	cp -uv $(ALLETAB) $(NEXTCLOUD_SCRIPTS)/allEtab.txt
	$(NEXTCLOUD_SCRIPTS)/diffEtab.pl

CONFIG: config/*.json
	cp config/*.json $(NEXTCLOUD_PATH)/config/

LIB: 
	cp -riTbv lib $(NEXTCLOUD_PATH)/lib

THEME:
	cp -riTv themes/esco $(NEXTCLOUD_PATH)/themes/esco
	cp core/css/variables.scss $(NEXTCLOUD_PATH)/core/css/variables.scss

SKELETON:
	cp -rvT skeleton $(NEXTCLOUD_PATH)/core/skeleton

# Plugins

USER_CAS:
	cp -rvT apps/user_cas $(APPS)/user_cas

LDAPIMPORTER:
	cp -rvT ldapimporter $(APPS)/ldapimporter

DAV:
	cp apps/dav/lib/CardDAV/CardDavBackend.php $(NEXTCLOUD_PATH)/apps/dav/lib/CardDAV/CardDavBackend.php

CSSJSLOADER:
	cp -rvT cssjsloader $(APPS)/cssjsloader

SETTINGS SETTINGS_APP:
	cp -rv apps/settings/* $(NEXTCLOUD_PATH)/apps/settings

NOTIFICATIONS:
	rsync -av \
	--include='css/***' \
	--include='js/***' \
	--include='lib/***' \
	--exclude='*' apps/notifications/* $(APPS)/notifications

FILES_SHARING:
	rsync -av files_sharing/dist/* $(DIST)
	rsync -av files_sharing/app/* $(APPS)/files_sharing --exclude src
	rsync -av --chown=$(NEXTCLOUD_OWNER):$(NEXTCLOUD_GROUP) $(DIST)

CALENDAR:
	rsync -av \
	--include='js/***' \
	--include='l10n/***' \
	--exclude='*' apps/calendar/* $(APPS)/calendar

ONLYOFFICE:
	rsync -av \
	--include='js/***' \
	--include='css/***' \
	--exclude='*' apps/onlyoffice/* $(APPS)/onlyoffice
