

NEXTCLOUD_PATH := ${NC_WWW}

ifeq ($(NEXTCLOUD_PATH), )
	NEXTCLOUD_PATH = ../web
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
	cp -rubviT files_sharing $(APPS)/files_sharing

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

