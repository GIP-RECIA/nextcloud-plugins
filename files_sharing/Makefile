NEXTCLOUD_VERSION=28
NEXTCLOUD_DOCKER=../../nextcloud-docker-dev/workspace/stable${NEXTCLOUD_VERSION}

$(info You are currently working on ${NEXTCLOUD_DOCKER})
$(info )

defaut:
	@echo "Availables commands: meld meld-app meld-dist sync-dist"

meld:
	@find app/ -type f | while read FILE; do \
		echo "--diff $${FILE} ${NEXTCLOUD_DOCKER}/apps/files_sharing/$${FILE#app/}"; \
	done | xargs meld

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
