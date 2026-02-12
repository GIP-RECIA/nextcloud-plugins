# Nextcloud ENT

```bash
.
├── apps
│   ├── dav
│   ├── notifications
│   ├── onlyoffice
│   └── settings
├── config
├── core
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

## Build theme

```sh
nvm use
npm i -g sass
sass --style=compressed --error-css themes/esco/scss:themes/esco/css
```
