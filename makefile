

NEXTCLOUD_PATH := ${NC_WWW}

ifeq ($(NEXTCLOUD_PATH), )
	NEXTCLOUD_PATH = ../web
endif

APPS = $(NEXTCLOUD_PATH)/apps

defaut:
	@echo $(NEXTCLOUD_PATH)


cssjsloader:
	cp -rT cssjsloader  $(APPS)/cssjsloader) 
	
files_sharing:
	cp -rT files_sharing $(APPS)/files_sharing
	
ldapimporter:
	cp -rT ldapimporter $(APPS)/ldapimporter

skeleton:
	cp -rT skeleton $(NEXTCLOUD_PATH)/core/skeleton

lib: 
	echo cp -rTb lib $(NEXTCLOUD_PATH)/lib
