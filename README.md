# Nextcloud ENT

```bash
.
├── apps
│   ├── calendar
│   ├── dav
│   ├── notifications
│   ├── settings
│   └── user_cas
├── config
├── core
├── cssjsloader
├── docs
├── files_sharing
├── ldapimporter
├── lib
├── scripts
├── skeleton
└── themes
```

## Version des plugins

Vérifier la dernière version compatible avec la version de Nextcloud :

- [ONLYOFFICE](https://apps.nextcloud.com/apps/onlyoffice/releases)
- [CAS user and group backend](https://apps.nextcloud.com/apps/user_cas/releases)

## Build theme

```sh
nvm use
npm i -g sass
sass --style=compressed --error-css themes/esco/scss:themes/esco/css
```
