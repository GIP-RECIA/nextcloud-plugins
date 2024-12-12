# Modifications du plugin calendar

- [Modifications du plugin calendar](#modifications-du-plugin-calendar)
  - [Mise à jour](#mise-à-jour)

## Mise à jour

```bash
nextcloud-plugins/apps/calendar$ cd ../../../calendar/
calendar$ git checkout v4.7.16 -b v4.7.16
calendar$ npm i
calendar$ npm i @mdi/js@^7.4.47
calendar$ cd -
nextcloud-plugins/apps/calendar$ make add
nextcloud-plugins/apps/calendar$ make meld
nextcloud-plugins/apps/calendar$ cd -
calendar$ npm run build
calendar$ cd -
nextcloud-plugins/apps/calendar$ make sync
```
