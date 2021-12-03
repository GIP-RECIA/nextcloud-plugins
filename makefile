

NEXTCLOUD_PATH := ${NC_WWW}

ifeq ($(NEXTCLOUD_PATH), )
	NEXTCLOUD_PATH = ../web
endif

NEXTCLOUD_OWNER := ${NC_OWNER}
NEXTCLOUD_GROUP := ${NC_GROUP}

ifeq ($(NEXTCLOUD_OWNER), )
	NEXTCLOUD_OWNER = 'www-data'
endif

ifeq ($(NEXTCLOUD_GROUP), )
	NEXTCLOUD_GROUP = 'www-data'
endif

APPS = $(NEXTCLOUD_PATH)/apps

LOADER=cssjsloader
SCSS=$(LOADER)/scss
CSS=$(LOADER)/inputs/css

defaut:
	@echo CSSJSLOADER FILES_SHARING LDAPIMPORTER SKELETON LIB CSS
	@echo $(NEXTCLOUD_PATH)


CSSJSLOADER:
	cp -rvT cssjsloader  $(APPS)/cssjsloader 

FILES_SHARING:
	mkdir -p ./backups
	mkdir -p ./backups/files_sharing_last
	rsync -v -a --delete $(APPS)/files_sharing/ ./backups/files_sharing_last/
	rsync -v -a --delete --chown=$(NEXTCLOUD_OWNER):$(NEXTCLOUD_GROUP) ./files_sharing/ $(APPS)/files_sharing/

RESTORE_FILES_SHARING:
	rsync -v -a --delete --chown=$(NEXTCLOUD_OWNER):$(NEXTCLOUD_GROUP) ./backups/files_sharing_last/ $(APPS)/files_sharing/

LDAPIMPORTER:
	cp -rvT ldapimporter $(APPS)/ldapimporter

SKELETON:
	cp -rvT skeleton $(NEXTCLOUD_PATH)/core/skeleton

LIB: 
	cp -riuTbv lib $(NEXTCLOUD_PATH)/lib

CSS: 
	cp $(CSS)/reciaStyle.css $(APPS)/$(CSS)/

sass: $(CSS)/reciaStyle.css

$(CSS)/%.css: $(SCSS)/*.scss
	sass  $(SCSS)/$*.scss $@

