

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


cssjsloader:
	cp -rT cssjsloader  $(APPS)/cssjsloader 
	
files_sharing:
	cp -rT files_sharing $(APPS)/files_sharing
	
ldapimporter:
	cp -rT ldapimporter $(APPS)/ldapimporter

skeleton:
	cp -rT skeleton $(NEXTCLOUD_PATH)/core/skeleton

lib: 
	echo cp -rTb lib $(NEXTCLOUD_PATH)/lib

css: $(CSS)/reciaStyle.css
	cp $(CSS)/reciaStyle.css $(APPS)/$(CSS)/

$(CSS)/%.css: $(SCSS)/*.scss
	sass  $(SCSS)/$*.scss $@

