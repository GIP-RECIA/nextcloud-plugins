PLUGIN=../../../calendar

defaut:
	@echo "Availables commands: add meld meld-app sync"

add:
	rsync -av \
	--include='src/' \
	--include='src/components/' \
	--include='src/components/Recia/***' \
	--include='src/services/***' \
	--exclude='*' . ${PLUGIN}

meld:
	meld \
	--diff l10n/fr.js ${PLUGIN}/l10n/fr.js \
	--diff l10n/fr.json ${PLUGIN}/l10n/fr.json \
	--diff src/components/AppNavigation/EditCalendarModal.vue  ${PLUGIN}/src/components/AppNavigation/EditCalendarModal.vue \
	--diff src/components/Editor/Invitees/InviteesList.vue  ${PLUGIN}/src/components/Editor/Invitees/InviteesList.vue \
	--diff src/views/Calendar.vue  ${PLUGIN}/src/views/Calendar.vue

meld-app:
	meld \
	--diff src/components/Recia/SharingSearchRecia.vue  ${PLUGIN}/src/components/AppNavigation/EditCalendarModal/SharingSearch.vue \
	--diff src/components/Recia/InviteesListSearchRecia.vue  ${PLUGIN}/src/components/Editor/Invitees/InviteesListSearch.vue

sync:
	rm -r js/*
	rsync -av \
	--include='js/***' \
	--include='l10n/fr.js*' \
	--exclude='*' ${PLUGIN}/ .
