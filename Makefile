
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

ALLETAB=allEtab_ncgip.txt

defaut:
	@echo "USER:\t\t${USER}\nNEXTCLOUD_PATH:\t$(NEXTCLOUD_PATH)"
	@echo ""
	@echo "Availables commands:"
	@echo " SCRIPTS"
	@echo " SKELETON"
	@echo "### Plugins ###"
	@echo " USER_CAS\tonly on first install (to check)"
	@echo " LDAPIMPORTER"
	@echo " COLLABORA"

SCRIPTS: 
	cp -rvu scripts/* $(NEXTCLOUD_SCRIPTS)/
	cp -uv $(ALLETAB) $(NEXTCLOUD_SCRIPTS)/allEtab.txt
	$(NEXTCLOUD_SCRIPTS)/diffEtab.pl

SKELETON:
	cp -rvT skeleton $(NEXTCLOUD_PATH)/core/skeleton

# Plugins

USER_CAS:
	cp -rvT apps/user_cas $(APPS)/user_cas

LDAPIMPORTER:
	cp -rvT ldapimporter $(APPS)/ldapimporter

COLLABORA:
	find apps/richdocuments -type f -exec cp \{\} $(NEXTCLOUD_PATH)/\{\} \;
	find apps/onlyoffice -type f -exec cp \{\} $(NEXTCLOUD_PATH)/\{\} \;
