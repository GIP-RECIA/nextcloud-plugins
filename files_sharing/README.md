# Modifications du plugin files_sharing

- [Modifications du plugin files\_sharing](#modifications-du-plugin-files_sharing)
  - [Structure](#structure)
  - [Mise à jour](#mise-à-jour)
    - [Fichiers ajouteés](#fichiers-ajouteés)
    - [Fichiers modifieés](#fichiers-modifieés)

## Structure

```bash
files_sharing/
├── app         # code source modifié
└── dist        # fichiers compilés
```

## Mise à jour

> Version 28 ⚠️ La compilation génères 3 fichiers (du type `xxxx-xxxx.js` `xxxx-xxxx.js.license` `xxxx-xxxx.js.map`) qui sont nécessaire au fonctionnement du plugin.

1. Mettez vous au tag de la version stable souhaitée et lancer le docker compose. `docker compose up -d stable30`

2. Initialisez le projet : `make dev-setup`.

3. Reportez les modifications de `nextcloud-plugins/files_sharing/app` vers le serveur `nextcloud-docker-dev/workspace/stable30/apps/files_sharing` et inversement.

4. Mettez à jour l'autoloader php : `composer install`.

5. Compilez le projet : `make build-js-production`.

6. Assurez vous que tout fonction correctement dans le docker ([stable30.local](stable30.local)).

7. Récuperez les fichiers compilés et le dossier `composer` : `make sync`.

```bash
nextcloud-plugins/files_sharing$ cd ../../nextcloud-docker-dev/workspace/stable30/
nextcloud-docker-dev/workspace/stable30$ git checkout v30.0.8 -b v30.0.8
nextcloud-docker-dev/workspace/stable30$ docker compose up -d stable30
nextcloud-docker-dev/workspace/stable30$ make dev-setup
nextcloud-docker-dev/workspace/stable30$ cd -
nextcloud-plugins/files_sharing$ make add
nextcloud-plugins/files_sharing$ make meld
nextcloud-plugins/files_sharing$ make update-composer
nextcloud-plugins/files_sharing$ cd -
nextcloud-docker-dev/workspace/stable30$ make build-js-production
nextcloud-docker-dev/workspace/stable30$ cd -
nextcloud-plugins/files_sharing$ make sync
```

### Fichiers ajouteés

```bash
files_sharing/
├── lib
│   ├── Controller
│   │   └── ReciaRechercheAPIController.php
│   └── Db
│       ├── EtablissementMapper.php
│       ├── Etablissement.php
│       └── SearchDB.php
└── src
    └── components
        ├── SharingInputEtab.vue
        └── SharingInputRecia.vue
```

### Fichiers modifieés

**appinfo/routes.php**

```diff
...
  [
   'name' => 'Remote#unshare',
   'url' => '/api/v1/remote_shares/{id}',
   'verb' => 'DELETE',
  ],
+  /*
+   * Recia Sharee API
+   */
+  [
+   'name' => 'ReciaRechercheAPI#search',
+   'url' => '/api/v1/recia_search',
+   'verb' => 'GET',
+  ],
+  [
+   'name' => 'ReciaRechercheAPI#listUserEtabs',
+   'url' => '/api/v1/recia_list_etabs',
+   'verb' => 'GET',
+  ],
 ],
];
```

**l10n/fr.js** et **l10n/fr.json**

- Ajouter les lignes ci-dessous à la fin des fichiers

```diff
...
+   "Search on :" : "Rechercher sur",
+   "Your establishments" : "Vos établissements",
+   "All platform" : "Tout le monde",
+   "Establishments" : "Etablissements",
+   "Select all" : "Tous",
+   "Select none" : "Aucun"
...
```

**src/views/SharingTab.vue**

```diff
...
    <!-- add new share input -->
-   <SharingInput v-if="!loading"
+   <SharingInputRecia v-if="!loading"
      :can-reshare="canReshare"
      :file-info="fileInfo"
      :link-shares="linkShares"
      :reshare="reshare"
      :shares="shares"
      @open-sharing-details="toggleShareDetailsView" />

+   <!-- internal link copy -->
+   <SharingEntryInternal :file-info="fileInfo" />
+
   <!-- link shares list -->
   <SharingLinkList v-if="!loading"
    ref="linkShareList"
    :can-reshare="canReshare"
    :file-info="fileInfo"
    :shares="linkShares"
    @open-sharing-details="toggleShareDetailsView" />

+   <!-- projects -->
+   <CollectionList v-if="projectsEnabled && fileInfo"
+    :id="`${fileInfo.id}`"
+    type="file"
+    :name="fileInfo.name" />
+  </div>
+
+  <div v-show="!showSharingDetailsView"
+   class="sharingTab__content sharingTab__additionalContent">
+   <div>{{ t('files_sharing', 'Users and groups with access') }}</div>
+
   <!-- other shares list -->
   <SharingList v-if="!loading"
    ref="shareList"
    :shares="shares"
    :file-info="fileInfo"
    @open-sharing-details="toggleShareDetailsView" />

   <!-- inherited shares -->
   <SharingInherited v-if="canReshare && !loading" :file-info="fileInfo" />
-
-   <!-- internal link copy -->
-   <SharingEntryInternal :file-info="fileInfo" />
-
-   <!-- projects -->
-   <CollectionList v-if="projectsEnabled && fileInfo"
-    :id="`${fileInfo.id}`"
-    type="file"
-    :name="fileInfo.name" />
  </div>
...
<script>
...
import SharingEntryInternal from '../components/SharingEntryInternal.vue'
import SharingEntrySimple from '../components/SharingEntrySimple.vue'
-import SharingInput from '../components/SharingInput.vue'
+import SharingInputRecia from '../components/SharingInputRecia.vue'

import SharingInherited from './SharingInherited.vue'
import SharingLinkList from './SharingLinkList.vue'
...
  SharingEntryInternal,
  SharingEntrySimple,
  SharingInherited,
- SharingInput,
+ SharingInputRecia,
  SharingInputEtab,
  SharingInputChoice,
  SharingLinkList,
  SharingList,
  SharingDetailsTab,
...
</script>
```
