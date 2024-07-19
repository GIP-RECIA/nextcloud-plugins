
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
	@echo SCRIPTS LDAPIMPORTER COLLABORA FILES_SHARING SKELETON USER_CAS
#   @echo SCRIPTS LDAPIMPORTER COLLABORA OOPATCH SKELETON USER_CAS LIB
	@echo "user_cas a faire qu'a la 1er install du plugin (a vérifier)"
	@echo ${USER} $(NEXTCLOUD_PATH)

SCRIPTS: 
	cp -rvu scripts/* $(NEXTCLOUD_SCRIPTS)/
	cp -uv $(ALLETAB) $(NEXTCLOUD_SCRIPTS)/allEtab.txt
	$(NEXTCLOUD_SCRIPTS)/diffEtab.pl

LDAPIMPORTER:
	cp -rvT ldapimporter $(APPS)/ldapimporter

FILES_SHARING:
	rsync -av files_sharing/dist/* $(DIST)
	rsync -av files_sharing/app/* $(APPS)/files_sharing --exclude src
	rsync -av --chown=$(NEXTCLOUD_OWNER):$(NEXTCLOUD_GROUP) $(DIST)
	@echo ""
	@echo Files to delete from dist ${DIST}
	git log -n 1 --diff-filter=D --name-only --pretty=format:"" | grep -E "[0-9]{3,}-[0-9]{3,}\.js" | sed "s|^files_sharing/dist/||"

COLLABORA:
	find apps/richdocuments -type f -exec cp \{\} $(NEXTCLOUD_PATH)/\{\} \;
	find apps/onlyoffice -type f -exec cp \{\} $(NEXTCLOUD_PATH)/\{\} \;

SKELETON:
	cp -rvT skeleton $(NEXTCLOUD_PATH)/core/skeleton

USER_CAS:
	find apps/user_cas -type f -exec cp \{\} $(NEXTCLOUD_PATH)/\{\} \;

#LIB: 
#	cp -riTbv lib $(NEXTCLOUD_PATH)/lib
