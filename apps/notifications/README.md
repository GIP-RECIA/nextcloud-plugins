# Modifications du plugin notifications

- [Modifications du plugin notifications](#modifications-du-plugin-notifications)
  - [Mise à jour](#mise-à-jour)
    - [Fichiers modifieés](#fichiers-modifieés)

## Mise à jour

1. Mettez vous au tag de la version souhaitée.

2. Initialisez le projet : `make dev-setup`.

3. Reportez les modifications de `nextcloud-plugins/apps/notifications` vers le projet `notifications` et inversement.

4. Compilez le projet : `make build-js-production`.

5. Récuperez les fichiers compilés : `make sync`.

```bash
nextcloud-plugins/apps/notifications$ cd ../../../notifications/
notifications$ git checkout v30.0.6 -b v30.0.6
notifications$ make dev-setup
notifications$ cd -
nextcloud-plugins/apps/notifications$ make meld
nextcloud-plugins/apps/notifications$ cd -
notifications$ make build-js-production
notifications$ cd -
nextcloud-plugins/apps/notifications$ make sync
```

### Fichiers modifieés

**lib/Push.php**

```diff
[...]
protected function sendNotificationsToProxies(): void {
+ return; // Disable push
[...]
```

**src/NotificationsApp.vue**

```diff
[...]
data() {
    return {
      [...]
-     // hasThrottledPushNotifications: loadState('notifications', 'throttled_push_notifications'),
+     hasThrottledPushNotifications: false,
      [...]
}
[...]
```
