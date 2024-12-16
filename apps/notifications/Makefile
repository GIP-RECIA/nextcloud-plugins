PLUGIN=../../../notifications

defaut:
	@echo "Availables commands: meld sync"

meld:
	meld \
	--diff lib/Push.php ${PLUGIN}/lib/Push.php \
	--diff src/NotificationsApp.vue  ${PLUGIN}/src/NotificationsApp.vue 

sync:
	rsync -av ${PLUGIN}/js .
