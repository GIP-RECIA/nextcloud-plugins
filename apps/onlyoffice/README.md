# Modifications du plugin onlyoffice

- [Modifications du plugin onlyoffice](#modifications-du-plugin-onlyoffice)
  - [Mise à jour](#mise-à-jour)
    - [Fichiers modifieés](#fichiers-modifieés)

## Mise à jour

1. Mettez vous au tag de la version souhaitée.

2. Initialisez le projet : `npm i`.

3. Reportez les modifications de `nextcloud-plugins/apps/onlyoffice` vers le projet `onlyoffice-nextcloud` et inversement.

4. Compilez le projet : `npm run build`.

5. Récuperez les fichiers compilés : `make sync`.

```bash
nextcloud-plugins/apps/onlyoffice$ cd ../../../onlyoffice-nextcloud/
onlyoffice-nextcloud$ git checkout v9.11.0 -b v9.11.0
onlyoffice-nextcloud$ npm i
onlyoffice-nextcloud$ cd -
nextcloud-plugins/apps/onlyoffice$ make meld
nextcloud-plugins/apps/onlyoffice$ cd -
onlyoffice-nextcloud$ npm run build
onlyoffice-nextcloud$ cd -
nextcloud-plugins/apps/onlyoffice$ make sync
```

### Fichiers modifieés

**src/editor.js**

```diff
[...]
  const headerHeight = $('#header').length > 0 ? $('#header').height() : 50
+ const headerEscoHeight = $('#escoDiv').length > 0 ? $('#escoDiv').height() : 38
+ const totalHeaderHeight = headerHeight + headerEscoHeight
  const wrapEl = $('#app>iframe')
  if (wrapEl.length > 0) {
-         wrapEl[0].style.height = (screen.availHeight - headerHeight) + 'px'
+         wrapEl[0].style.height = (screen.availHeight - totalHeaderHeight) + 'px'
          window.scrollTo(0, -1)
-         wrapEl[0].style.height = (window.top.innerHeight - headerHeight) + 'px'
+         wrapEl[0].style.height = (window.top.innerHeight - totalHeaderHeight) + 'px'
[...]
```
