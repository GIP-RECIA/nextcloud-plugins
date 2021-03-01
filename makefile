

NEXTCLOUD_PATH := ${NC_WWW}

ifeq ($(NEXTCLOUD_PATH), )
	NEXTCLOUD_PATH = ../web
endif

APPS = $(NEXTCLOUD_PATH)/apps

LOADER=cssjsloader
SCSS=$(LOADER)/scss
CSS=$(LOADER)/inputs/css

defaut:
	@echo $(NEXTCLOUD_PATH)


CSSJSLOADER:
	cp -rT cssjsloader  $(APPS)/cssjsloader 

FILES_SHARING:
	cp -rT files_sharing $(APPS)/files_sharing

LDAPIMPORTER:
	cp -rT ldapimporter $(APPS)/ldapimporter

SKELETON:
	cp -rT skeleton $(NEXTCLOUD_PATH)/core/skeleton

LIB: 
	echo cp -rTb lib $(NEXTCLOUD_PATH)/lib

css: $(CSS)/reciaStyle.css
	cp $(CSS)/reciaStyle.css $(APPS)/$(CSS)/

$(CSS)/%.css: $(SCSS)/*.scss
	sass  $(SCSS)/$*.scss $@

