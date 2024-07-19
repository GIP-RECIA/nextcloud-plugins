# Modifications du plugin files_sharing

- [Modifications du plugin files\_sharing](#modifications-du-plugin-files_sharing)
  - [Structure](#structure)
  - [Fichiers à ajouter](#fichiers-à-ajouter)
  - [Fichiers à modifier](#fichiers-à-modifier)
  - [Compilation](#compilation)
    - [Mettre à jour l'autoloader php](#mettre-à-jour-lautoloader-php)
    - [Packager les librairies Javascript](#packager-les-librairies-javascript)

## Structure

```bash
files_sharing/
├── app         # code source modifié
└── dist        # fichiers compilés
```

## Fichiers à ajouter

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
    ├── components
    │   ├── SharingInputChoice.vue
    │   ├── SharingInputEtab.vue
    │   └── SharingInputRecia.vue
    └── mixins
        └── MultiselectMixin.js
```

## Fichiers à modifier

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

**l10n/fr.js**

```diff
...
    "sharing is disabled" : "le partage est désactivé",
-   "For more info, please ask the person who sent this link." : "Pour plus d'informations, veuillez contacter la personne qui vous a envoyé ce lien."
+   "For more info, please ask the person who sent this link." : "Pour plus d'informations, veuillez contacter la personne qui vous a envoyé ce lien.",
+   "Search on :" : "Rechercher sur",
+   "Your establishments" : "Vos établissements",
+   "All platform" : "Tout le monde",
+   "Establishments" : "Etablissements",
+   "Select all" : "Tous",
+   "Select none" : "Aucun"
},
"nplurals=3; plural=(n == 0 || n == 1) ? 0 : n != 0 && n % 1000000 == 0 ? 1 : 2;");
```

**l10n/fr.json**

```diff
...
    "sharing is disabled" : "le partage est désactivé",
-   "For more info, please ask the person who sent this link." : "Pour plus d'informations, veuillez contacter la personne qui vous a envoyé ce lien."
+   "For more info, please ask the person who sent this link." : "Pour plus d'informations, veuillez contacter la personne qui vous a envoyé ce lien.",
+   "Search on :" : "Rechercher sur",
+   "Your establishments" : "Vos établissements",
+   "All platform" : "Tout le monde",
+   "Establishments" : "Etablissements",
+   "Select all" : "Tous",
+   "Select none" : "Aucun"
},"pluralForm" :"nplurals=3; plural=(n == 0 || n == 1) ? 0 : n != 0 && n % 1000000 == 0 ? 1 : 2;"
}
```

**src/views/SharingTab.vue**

```diff
...
    <!-- add new share input -->
+   <!--
    <SharingInput v-if="!loading"
      :can-reshare="canReshare"
      :file-info="fileInfo"
      :link-shares="linkShares"
      :reshare="reshare"
      :shares="shares"
      @open-sharing-details="toggleShareDetailsView" />
+    -->
+
+    <span>{{ t('files_sharing', 'Search on :') }}</span>
+
+    <!-- add seach choice -->
+    <SharingInputChoice v-if="!loading && canReshare"
+      :type="searchType"
+     @change="updateSearchType" />
+
+    <!-- add etab choice -->
+    <SharingInputEtab v-if="!loading && canReshare"
+      v-show="searchType==='etab'"
+      @change="updateSelectedEtabs" />
+
+    <!-- add new share input -->
+    <SharingInputRecia v-if="!loading"
+      :can-reshare="canReshare"
+      :file-info="fileInfo"
+      :link-shares="linkShares"
+      :reshare="reshare"
+      :shares="shares"
+      :search-type="searchType"
+      :search-etabs="selectedEtabs"
+      @add:share="addShare" />

     <!-- link shares list -->
...
<script>
...
import ShareTypes from '../mixins/ShareTypes.js'
import SharingEntryInternal from '../components/SharingEntryInternal.vue'
import SharingEntrySimple from '../components/SharingEntrySimple.vue'
-import SharingInput from '../components/SharingInput.vue'
+// import SharingInput from '../components/SharingInput.vue'
+import SharingInputRecia from '../components/SharingInputRecia.vue'
+import SharingInputEtab from '../components/SharingInputEtab.vue'
+import SharingInputChoice from '../components/SharingInputChoice.vue'

import SharingInherited from './SharingInherited.vue'
import SharingLinkList from './SharingLinkList.vue'
...
  SharingEntryInternal,
  SharingEntrySimple,
  SharingInherited,
- SharingInput,
+ // SharingInput,
  SharingInputRecia,
  SharingInputEtab,
  SharingInputChoice,
  SharingLinkList,
  SharingList,
  SharingDetailsTab,
...
 data() {
  return {
...
   // reshare Share object
   reshare: null,
   sharedWithMe: {},
   shares: [],
   linkShares: [],

+   searchType: 'etab',
+   selectedEtabs: [],
+
   sections: OCA.Sharing.ShareTabSections.getSections(),
   projectsEnabled: loadState('core', 'projects_enabled', false),
   showSharingDetailsView: false,
...
  }
 },

 computed: {
...
    })
   }
  },
+
+  updateSearchType(type) {
+   this.searchType = type
+  },
+
+  updateSelectedEtabs(etabs) {
+   this.selectedEtabs = etabs
+  },
 },
}
</script>
```

## Compilation

1. [Mettre à jour l'autoloader php](#mettre-à-jour-lautoloader-php) et [packager les librairies Javascript](#packager-les-librairies-javascript).
2. Faire un meld entre `nextcloud-plugins/files_sharing/dist` et le serveur Nextcloud `server/dist`.
3. Faire un meld entre `nextcloud-plugins/files_sharing/app` et le serveur Nextcloud `server/apps/files_sharing`.

### Mettre à jour l'autoloader php

> Dans le dossier `files_sharing`

```shell
cd ./composer
composer install
```

### Packager les librairies Javascript

> A la racine de Nextcloud

```shell
make build-js-production
```
