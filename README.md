**Adaptation a Nextcloud pour le GIP RECIA (Projet Neto centre)**

Le GIP RECIA à deux déploiements de Nextcloud sur la même architecture. Un pour les ENT dans lycées et collèges (nc-ent) et l'autre pour le GIP lui-même et les collectivités (nc-gip).

Les modifications portent principalement sur :

- La gestion des groupes (LDAP Importer): Données les droits (quota) et créer les groupes Nextcloud à partir des groupes LDAP.
- La recherche de groupe et personne pour le partage (Files Sharing).
- La gestion des buckets : n'avoir qu'un bucket par compte, par avatar et vignette.
- Un plugin de chargement de js et css particulier (CSS JS Loader).
- Les fichiers par défauts (Skeleton) : suppression modification du repertoire skeleton.

[Présentation de juin 2023 au ESUP DAYS](Presentation_ESUP_DAYS_06.2023/presentation.pdf)

Aller sur la branche [ENT](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-ent) | [GIP](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-gip)

# LDAP Importer

Le plugin LDAP Importer permet l'alimentation des utilisateurs avec filtrage sur leurs groupes LDAP. On en déduit leurs groupes Nextcloud et leurs quota. Les filtres sont paramètrés avec des regexs dans "Paramètres -> sécurité -> Import Users -> Filtre & nomage de groupe".

- Une première serie de regex permet de deduire les noms des établissement (pour Nextcloud) à partir des groupes LDAP.
- La deuxième définit les groupes Nextcloud à partir des groupes LDAP (fixe le quota minimum), sans groupe de cette serie un user LDAP ne sera pas importer dans Nextcloud.
- La troisièmes définit les groupes Nextcloud à partir des groupes pédagogiques de l'utilisateur, ce ne sont pas des groupes fonctionnels, ils  ne sont pas dans le isMemberOf du LDAP. Il faut donc définir l'attribut LDAP approprié.  

Tester avec le plugin "CAS Authentication backend" version : 1.10

Voir les fichiers [branche ENT](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-ent/ldapimporter) | [branche GIP](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-gip/ldapimporter)

**Installation**

A placer dans le dossier `apps/` de Nextcloud

**Utilisation**

La commande pour importer les utilisateurs du LDAP à la BDD :

```sh
sudo -u www-data php occ ldap:import-users-ad
```

# File Sharing

Remplacement du plugin Nextcloud File Sharing

Voir les fichiers [branche ENT](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-ent/files_sharing)

**Installation**

Remplacer TOTALEMENT le dossier `files_sharing` dans le dossier `apps/` à la racine du projet.

# Gestion des buckets (S3)

Remplacer `./lib/private/Files/objectStore/Mapper.php` et `./lib/private/Files/Mount/RootMountProvider.php` par nos versions
et ajouter dans `./lib/private/Files/ObjectStore` : `ReciaObjectStoreStorage.php` et `S3Recia.php`.

`Mapper.php` distribut un bucket par user (c'est un hash donc quasiment un bucket par user).\
`ReciaObjectStoreStorage.php` et `S3Recia.php` permetent de na pas stocker tous les avatars et préview dans le même bucket system (bucket 0).

Voir les fichiers [branche ENT](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-ent/lib)

# CSS JS Loader

Plugin pour Nextcloud CSSJSLoader qui surcharge le css et le js de toutes les pages

Voir les fichiers [branche ENT](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-ent/cssjsloader)

**Installation**

A placer dans le dossier `apps/` de Nextcloud

**Utilisation**

- Placer les ficher js dans le dossier `apps/cssjsloader/inputs/js`
- Placer les ficher css dans le dossier `apps/cssjsloader/inputs/css`

# Skeleton

Répertoire contenant le document par défaut à la creation d'un l'utilisateur.\
À recopier dans `core/skeleton`.

Le plugin est le même pour les deux branches :

Voir les fichiers [branche ENT](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-ent/skeleton) | [branche GIP](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-gip/skeleton)

# Scripts

Ensemble des scripts utiles à l'exploitation:

- loadEtabs.pl: creation des comptes et groupes à partir de LDAP.
- userFile.pl donne les fichiers et info d'un compte.
- groupFinder.pl donne les membres d'un groupe.

Voir les fichiers [branche ENT](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-ent/scripts) | [branche GIP](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-gip/scripts)
