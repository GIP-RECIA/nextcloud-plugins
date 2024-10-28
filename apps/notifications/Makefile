NOTIFICATIONS=../../../notifications

defaut:
	@echo "Availables commands: meld meld-app sync"

meld:
	meld \
	--diff lib/Push.php ${NOTIFICATIONS}/lib/Push.php \
	--diff src/NotificationsApp.vue  ${NOTIFICATIONS}/src/NotificationsApp.vue 

meld-app:
	meld . ${NOTIFICATIONS}

sync:
	rsync -av ${NOTIFICATIONS}/js .
