NEXTCLOUD_VERSION=32
NEXTCLOUD_DOCKER=../../nextcloud-docker-dev/workspace/stable${NEXTCLOUD_VERSION}

$(info You are currently working on ${NEXTCLOUD_DOCKER})
$(info )

defaut:
	@echo "Availables commands: add meld meld-app meld-dist update-composer sync sync-dist sync-composer"

add:
	rsync -av \
	--include='lib/***' \
	--include='src/' \
	--include='src/components/***' \
	--include='src/mixins/***' \
	--exclude='*' app/ ${NEXTCLOUD_DOCKER}/apps/files_sharing/

meld:
	meld \
	--diff app/appinfo/routes.php ${NEXTCLOUD_DOCKER}/apps/files_sharing/appinfo/routes.php \
	--diff app/l10n/fr.js ${NEXTCLOUD_DOCKER}/apps/files_sharing/l10n/fr.js \
	--diff app/l10n/fr.json ${NEXTCLOUD_DOCKER}/apps/files_sharing/l10n/fr.json \
	--diff app/src/views/SharingTab.vue ${NEXTCLOUD_DOCKER}/apps/files_sharing/src/views/SharingTab.vue

meld-app:
	meld app/ ${NEXTCLOUD_DOCKER}/apps/files_sharing/

meld-dist:
	meld dist/ ${NEXTCLOUD_DOCKER}/dist/

meld-sharing-input:
	meld app/src/components/SharingInputRecia.vue ${NEXTCLOUD_DOCKER}/apps/files_sharing/src/components/SharingInput.vue

update-composer:
	cd ${NEXTCLOUD_DOCKER}/apps/files_sharing/composer/ && composer install

sync: sync-dist sync-composer

sync-dist:
	rm -r dist/*
	rsync -av \
	--include='files_sharing-files_sharing_tab*' \
	--exclude='*' ${NEXTCLOUD_DOCKER}/dist/ dist/
	cd ${NEXTCLOUD_DOCKER} && git status --porcelain | grep -E "[0-9]{3,}-[0-9]{3,}" > dist_changes.txt
	mv ${NEXTCLOUD_DOCKER}/dist_changes.txt dist_changes.txt
	cat dist_changes.txt
	@grep '^??' dist_changes.txt | awk '{print $$2}' | xargs -I {} cp ${NEXTCLOUD_DOCKER}/{} dist/

sync-composer:
	rsync -av ${NEXTCLOUD_DOCKER}/apps/files_sharing/composer/ app/composer/
