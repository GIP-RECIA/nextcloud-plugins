PLUGIN=../../../onlyoffice-nextcloud

defaut:
	@echo "Availables commands: meld sync"

meld:
	meld \
	--diff src/editor.js  ${PLUGIN}/src/editor.js 

sync:
	rm -f js/*
	rsync -av ${PLUGIN}/js/onlyoffice-editor.js* ./js
