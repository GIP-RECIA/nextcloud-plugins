# Modifications du plugin files_sharing

- [Modifications du plugin files\_sharing](#modifications-du-plugin-files_sharing)
  - [Structure](#structure)
  - [Fichiers à modifier](#fichiers-à-modifier)
  - [Packager les librairies Javascript](#packager-les-librairies-javascript)

## Structure

```bash
files_sharing/
├── app         # code source modifié
└── dist        # fichiers compilés
```

## Fichiers à modifier

**l10n/fr.js**

```diff
...
    "Add another link" : "Ajouter un autre lien",
-   "Create a new share link" : "Créer un nouveau lien de partage",
+   "Create a new share link" : "Créer un nouveau lien de partage public",
    "{shareWith} by {initiator}" : "{shareWith} par {initiator}",
    "Shared via link by {initiator}" : "Partagé par lien par {initiator}",
    "Mail share ({label})" : "Partager par e-mail ({label}) ",
-   "Share link ({label})" : "Lien de partage ({label})",
-   "Share link ({index})" : "Lien de partage ({index})",
-   "Share link" : "Lien de partage",
+   "Share link ({label})" : "Lien de partage public ({label})",
+   "Share link ({index})" : "Lien de partage public ({index})",
+   "Share link" : "Lien de partage public",
    "Actions for \"{title}\"" : "Actions pour \"{title}\"",
...
    "sharing is disabled" : "le partage est désactivé",
-   "For more info, please ask the person who sent this link." : "Pour plus d'informations, veuillez contacter la personne qui vous a envoyé ce lien."
+   "For more info, please ask the person who sent this link." : "Pour plus d'informations, veuillez contacter la personne qui vous a envoyé ce lien.",
+   "Person or group": "Personne ou groupe",
+   "Users and groups with access" : "Utilisateurs et groupes ayant accès"
},
"nplurals=3; plural=(n == 0 || n == 1) ? 0 : n != 0 && n % 1000000 == 0 ? 1 : 2;");
...
```

**l10n/fr.json**

```diff
...
    "Add another link" : "Ajouter un autre lien",
-   "Create a new share link" : "Créer un nouveau lien de partage",
+   "Create a new share link" : "Créer un nouveau lien de partage public",
    "{shareWith} by {initiator}" : "{shareWith} par {initiator}",
    "Shared via link by {initiator}" : "Partagé par lien par {initiator}",
    "Mail share ({label})" : "Partager par e-mail ({label}) ",
-   "Share link ({label})" : "Lien de partage ({label})",
-   "Share link ({index})" : "Lien de partage ({index})",
-   "Share link" : "Lien de partage",
+   "Share link ({label})" : "Lien de partage public ({label})",
+   "Share link ({index})" : "Lien de partage public ({index})",
+   "Share link" : "Lien de partage public",
    "Actions for \"{title}\"" : "Actions pour \"{title}\"",
...
    "sharing is disabled" : "le partage est désactivé",
-   "For more info, please ask the person who sent this link." : "Pour plus d'informations, veuillez contacter la personne qui vous a envoyé ce lien."
+   "For more info, please ask the person who sent this link." : "Pour plus d'informations, veuillez contacter la personne qui vous a envoyé ce lien.",
+   "Person or group": "Personne ou groupe",
+   "Users and groups with access" : "Utilisateurs et groupes ayant accès"
},"pluralForm" :"nplurals=3; plural=(n == 0 || n == 1) ? 0 : n != 0 && n % 1000000 == 0 ? 1 : 2;"
}
```

**src/components/SharingEntryInternal.vue**

```diff
...
<style lang="scss" scoped>
.sharing-entry__internal {
 .avatar-external {
  width: 32px;
  height: 32px;
  line-height: 32px;
  font-size: 18px;
-  background-color: var(--color-text-maxcontrast);
+  background-color: var(--color-primary-element);
  border-radius: 50%;
  flex-shrink: 0;
 }
 .icon-checkmark-color {
  opacity: 1;
 }
}
</style>
```

**src/components/SharingEntryLink.vue**

```diff
...
<style lang="scss" scoped>
...
 &:not(.sharing-entry--share) &__actions {
  .new-share-link {
   border-top: 1px solid var(--color-border);
  }
 }

 ::v-deep .avatar-link-share {
-  background-color: var(--color-primary-element);
+  background-color: var(--color-text-maxcontrast);
 }
...
</style>
```

**src/components/SharingInput.vue**

```diff
...
<template>
 <div class="sharing-search">
-  <label for="sharing-search-input">{{ t('files_sharing', 'Search for share recipients') }}</label>
+  <label for="sharing-search-input">{{ t('files_sharing', 'Share with ') }}</label>
  <NcSelect ref="select"
   v-model="value"
   input-id="sharing-search-input"
   class="sharing-search__input"
   :disabled="!canReshare"
   :loading="loading"
   :filterable="false"
   :placeholder="inputPlaceholder"
   :clear-search-on-blur="() => false"
   :user-select="true"
   :options="options"
   @search="asyncFind"
   @option:selected="onSelected">
   <template #no-options="{ search }">
    {{ search ? noResultText : t('files_sharing', 'No recommendations. Start typing.') }}
   </template>
  </NcSelect>
 </div>
</template>
...
 computed: {
  /**
   * Implement ShareSearch
   * allows external appas to inject new
   * results into the autocomplete dropdown
   * Used for the guests app
   *
   * @return {Array}
   */
  externalResults() {
   return this.ShareSearch.results
  },
  inputPlaceholder() {
   const allowRemoteSharing = this.config.isRemoteShareAllowed

   if (!this.canReshare) {
    return t('files_sharing', 'Resharing is not allowed')
   }
   // We can always search with email addresses for users too
   if (!allowRemoteSharing) {
-    return t('files_sharing', 'Name or email …')
+    return t('files_sharing', 'Person or group')
   }

-   return t('files_sharing', 'Name, email, or Federated Cloud ID …')
+   return t('files_sharing', 'Person or group')
  },

  isValidQuery() {
   return this.query && this.query.trim() !== '' && this.query.length > this.config.minSearchStringLength
  },
...
```

**src/views/SharingTab.vue**

```diff
<template>
 <div class="sharingTab" :class="{ 'icon-loading': loading }">
  <!-- error message -->
  <div v-if="error" class="emptycontent" :class="{ emptyContentWithSections: sections.length > 0 }">
   <div class="icon icon-error" />
   <h2>{{ error }}</h2>
  </div>

  <!-- shares content -->
  <div v-show="!showSharingDetailsView"
   class="sharingTab__content">
   <!-- shared with me information -->
   <ul>
    <SharingEntrySimple v-if="isSharedWithMe" v-bind="sharedWithMe" class="sharing-entry__reshare">
     <template #avatar>
      <NcAvatar :user="sharedWithMe.user"
       :display-name="sharedWithMe.displayName"
       class="sharing-entry__avatar" />
     </template>
    </SharingEntrySimple>
   </ul>

   <!-- add new share input -->
   <SharingInput v-if="!loading"
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

  <!-- additional entries, use it with cautious -->
      <div v-for="(section, index) in sections"
   v-show="!showSharingDetailsView"
   :ref="'section-' + index"
   :key="index"
   class="sharingTab__additionalContent">
   <component :is="section($refs['section-'+index], fileInfo)" :file-info="fileInfo" />
  </div>

  <!-- share details -->
  <SharingDetailsTab v-if="showSharingDetailsView"
   :file-info="shareDetailsData.fileInfo"
   :share="shareDetailsData.share"
   @close-sharing-details="toggleShareDetailsView"
   @add:share="addShare"
   @remove:share="removeShare" />
 </div>
</template>
...
```

## Packager les librairies Javascript

> Revenir à la racine de nextcloud

```shell
make build-js-production
```

> ⚠️ La compilation génères 3 fichiers (du type `xxxx-xxxx.js` `xxxx-xxxx.js.LICENSE.txt` `xxxx-xxxx.js.map`) qui sont nécessaire au fonctionnement du plugin. Ces fichiers ne sont pas suivi par git => on peut facilement les trouver avec un `git status` ou `git ls-files --others --exclude-standard`.

1. Compiler le js.
2. Faire un meld entre `nextcloud-plugins/files_sharing/dist` et le serveur Nextcloud `server/dist` supprimer les anciens fichiers du type `xxxx-xxxx.js` et les remplacer par les nouveaux.
3. Faire un meld entre `nextcloud-plugins/files_sharing/app` et le serveur Nextcloud `server/apps/files_sharing`.
