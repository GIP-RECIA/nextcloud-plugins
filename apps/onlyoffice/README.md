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
onlyoffice-nextcloud$ git checkout v9.14.2 -b v9.14.2
onlyoffice-nextcloud$ npm i
onlyoffice-nextcloud$ cd -
nextcloud-plugins/apps/onlyoffice$ make meld
nextcloud-plugins/apps/onlyoffice$ cd -
onlyoffice-nextcloud$ npm run build
onlyoffice-nextcloud$ cd -
nextcloud-plugins/apps/onlyoffice$ make sync
```

### Fichiers modifieés

**src/editor.css**

```diff
[...]
-    height: calc(100dvh - 58px);
+    height: calc(100dvh - 50px);
[...]
```

**src/editor.js**

```diff
[...]
        const headerHeight = document.getElementById('header')?.offsetHeight ?? 50
+       const headerEscoHeight = document.getElementById('escoDiv')?.offsetHeight
+               ?? parent.getElementById('escoDiv')?.offsetHeight
+               ?? 0
+       const totalHeaderHeight = headerHeight + headerEscoHeight
        const wrapEl = document.querySelector('#app>iframe')
        if (wrapEl) {
-               wrapEl.style.height = (screen.availHeight - headerHeight) + 'px'
+               wrapEl.style.height = (screen.availHeight - totalHeaderHeight) + 'px'
                window.scrollTo(0, -1)
-               wrapEl.style.height = (window.top.innerHeight - headerHeight) + 'px'
+               wrapEl.style.height = (window.top.innerHeight - totalHeaderHeight) + 'px'
[...]
```
