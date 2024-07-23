NEXTCLOUD_VERSION = 28
NEXTCLOUD_DOCKER = ../../nextcloud-docker-dev/workspace/stable${NEXTCLOUD_VERSION}

$(info You are currently working on ${NEXTCLOUD_DOCKER})
$(info )

defaut:
	@echo "Availables commands: meld meld-app meld-dist sync-dist"

meld:
	meld \
	--diff app/l10n/fr.js ${NEXTCLOUD_DOCKER}/apps/files_sharing/l10n/fr.js \
	--diff app/l10n/fr.json ${NEXTCLOUD_DOCKER}/apps/files_sharing/l10n/fr.json \
	--diff app/src/components/SharingEntryInternal.vue ${NEXTCLOUD_DOCKER}/apps/files_sharing/src/components/SharingEntryInternal.vue \
	--diff app/src/components/SharingEntryLink.vue ${NEXTCLOUD_DOCKER}/apps/files_sharing/src/components/SharingEntryLink.vue \
	--diff app/src/components/SharingInput.vue ${NEXTCLOUD_DOCKER}/apps/files_sharing/src/components/SharingInput.vue \
	--diff app/src/views/SharingTab.vue ${NEXTCLOUD_DOCKER}/apps/files_sharing/src/views/SharingTab.vue

meld-app:
	meld app/ ${NEXTCLOUD_DOCKER}/apps/files_sharing/

meld-dist:
	meld dist/ ${NEXTCLOUD_DOCKER}/dist/

sync-dist:
	rm -r dist/*
	rsync -av --include='files_sharing-files_sharing_tab*' --exclude='*' ${NEXTCLOUD_DOCKER}/dist/ dist/
	cd ${NEXTCLOUD_DOCKER} && git status --porcelain | grep -E "[0-9]{3,}-[0-9]{3,}" > dist_changes.txt
	mv ${NEXTCLOUD_DOCKER}/dist_changes.txt dist_changes.txt
	cat dist_changes.txt
	@grep '^??' dist_changes.txt | awk '{print $$2}' | xargs -I {} cp ${NEXTCLOUD_DOCKER}/{} dist/
