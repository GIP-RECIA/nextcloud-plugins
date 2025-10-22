PLUGIN=../../../onlyoffice-nextcloud

defaut:
	@echo "Availables commands: meld sync"

meld:
	meld \
	--diff src/editor.js  ${PLUGIN}/src/editor.js \
	--diff css/editor.css  ${PLUGIN}/css/editor.css 

sync:
	rm -f js/*
	rsync -av ${PLUGIN}/js/onlyoffice-editor.js* ./js
