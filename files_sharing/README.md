# Mmodifications du plugin files_sharing
## Fichiers à ajouter :
``` files
+-- .
+-- lib
|	+-- Controller
|	|	+-- ReciaRechercheAPIController.php
|	+-- Db
|	|	+-- Etablissement.php
|	|	+-- EtablissementMapper.php
|	|	+-- SearchDB.php
+-- src
|	+-- components
|	|	+-- SharingInputChoice.vue
|	|	+-- SharingInputEtab.vue
|	|	+-- SharingInputRecia.vue
|	+-- mixins
|	|	+-- MultiselectMixin.js
```

## Fichiers à modifier :
**/appinfo/routes.php**
``` php
/** Ajouter les routes suivantes **/
...
/*
* Recia Sharee API
*/
[
  'name' => 'ReciaRechercheAPI#search',
  'url' => '/api/v1/recia_search',
  'verb' => 'GET',
],
[
  'name' => 'ReciaRechercheAPI#listUserEtabs',
  'url' => '/api/v1/recia_list_etabs',
  'verb' => 'GET',
],
...
```
**/l10n/fr.js**
``` javascript
/** Ajouter à la fin **/
	...
	"Search on :" : "Rechercher sur",
	"Your establishments" : "Vos établissements",
	"All platform" : "Tout le monde",
	"Establishments" : "Etablissements"
},
"nplurals=2; plural=(n > 1);");
```
**/l10n/fr.json**
``` json
/** Ajouter à la fin **/
	...
	"Search on :" : "Rechercher sur",
	"Your establishments" : "Vos établissements",
	"All platform" : "Tout le monde",
	"Establishments" : "Etablissements"
},"pluralForm" :"nplurals=2; plural=(n > 1);"
}
```
**/src/views/SharingTab.vue**
``` javascript
...
/** Commenter le composant SharingInput par les nouveaux composants**/
<!--
<SharingInput v-if="!loading"
	:can-reshare="canReshare"
	:file-info="fileInfo"
	:link-shares="linkShares"
	:reshare="reshare"
	:shares="shares"
	@add:share="addShare" />
-->
<span>{{ t('files_sharing','Search on :') }}</span>
<!-- add seach choice -->
<SharingInputChoice v-if="!loading && canReshare"
	:type="searchType"
	@change="updateSearchType" />

<!-- add etab choice -->
<SharingInputEtab v-if="!loading && canReshare"
	v-show="searchType==='etab'"
	@change="updateSelectedEtabs" />

<!-- add new share input -->
<SharingInputRecia v-if="!loading"
	:can-reshare="canReshare"
	:file-info="fileInfo"
	:link-shares="linkShares"
	:reshare="reshare"
	:shares="shares"
	:search-type="searchType"
	:search-etabs="selectedEtabs"
	@add:share="addShare" />
}
...
/** Remplacer l'import de SharingInput par celui des nouveaux composants **/
// import SharingInput from '../components/SharingInput'
import SharingInputRecia from '../components/SharingInputRecia'
import SharingInputEtab from '../components/SharingInputEtab'
import SharingInputChoice from '../components/SharingInputChoice'
...
/** Remplacer la declaration SharingInput par celle des nouveaux composants dans la vue **/
components: {
	Avatar,
	CollectionList,
	SharingEntryInternal,
	SharingEntrySimple,
	SharingInherited,
	/*SharingInput,*/
	SharingInputRecia,
	SharingInputEtab,
	SharingInputChoice,
	SharingLinkList,
	SharingList,
},
...
/** Ajouter les propriété inernes **/
data() {
	return {
		config: new Config(),

		error: '',
		expirationInterval: null,
		loading: true,

		fileInfo: null,

		// reshare Share object
		reshare: null,
		sharedWithMe: {},
		shares: [],
		linkShares: [],

		searchType: 'etab',
		selectedEtabs: [],

		sections: OCA.Sharing.ShareTabSections.getSections(),
	}
},
...
/** Ajouter les méthodes **/
methods: {
	...

	updateSearchType(type) {
		this.searchType = type
	},

	updateSelectedEtabs(etabs) {
		this.selectedEtabs = etabs
	},
},
```
## Mettre à jour l'autoloader php
``` shell
$ cd ./composer
$ composer install
```
_**!!! IMPORTANT !!! :** composer doit être installé_

[<img src="https://getcomposer.org/img/logo-composer-transparent3.png" width="75px"/>](https://getcomposer.org/doc/00-intro.md#installation-linux-unix-macos)

## Packager les librairies Javascript
``` shell
$ npm run dev
```
_**!!! IMPORTANT !!! :** npm & nodejs doivent être installés_

[<img src="https://github.com/npm/logos/blob/master/npm%20logo/npm-logo-red.png?raw=true" width="75px"/>](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)

**[NVM](https://github.com/nvm-sh/nvm)**


	