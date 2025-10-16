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

## Build theme

```sh
nvm use
npm i -g sass
sass --style=compressed --error-css themes/esco/scss:themes/esco/css
```
