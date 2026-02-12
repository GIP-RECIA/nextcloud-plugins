**Adaptation a Nextcloud pour le GIP RECIA (Projet Neto centre)**

Le GIP RECIA à deux déploiements de Nextcloud sur la même architecture. Un pour les ENT dans lycées et collèges (nc-ent) et l'autre pour le GIP lui-même et les collectivités (nc-gip).

Les modifications portent principalement sur :

- La gestion des groupes (LDAP Importer): Données les droits (quota) et créer les groupes Nextcloud à partir des groupes LDAP.
- La recherche de groupe et personne pour le partage (Files Sharing).
- La gestion des buckets : n'avoir qu'un bucket par compte.
- Les fichiers par défauts (Skeleton) : suppression modification du repertoire skeleton.

[Présentation de juin 2023 au ESUP DAYS](Presentation_ESUP_DAYS_06.2023/presentation.pdf)

Aller sur la branche [ENT](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-ent) | [GIP](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-gip)

# LDAP Importer

Le plugin LDAP Importer permet l'alimentation des utilisateurs avec filtrage sur leurs groupes LDAP. On en déduit leurs groupes Nextcloud et leurs quota. Les filtres sont paramètrés avec des regexs dans "Paramètres d'&dministration -> LDAP Importer".

- Une première serie de regex permet de deduire les noms des établissement (pour Nextcloud) à partir des groupes LDAP.
- La deuxième définit les groupes Nextcloud à partir des groupes LDAP (fixe le quota minimum), sans groupe de cette serie un user LDAP ne sera pas importer dans Nextcloud.
- La troisièmes définit les groupes Nextcloud à partir des groupes pédagogiques de l'utilisateur, ce ne sont pas des groupes fonctionnels, ils  ne sont pas dans le isMemberOf du LDAP. Il faut donc définir l'attribut LDAP approprié.  

Voir les fichiers [branche ENT](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-ent/ldapimporter) | [branche GIP](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-gip/ldapimporter)

**Installation**

A placer dans le dossier `apps/` de Nextcloud.

```sh
Make LDAPIMPORTER
```

**Utilisation**

La commande pour importer les utilisateurs du LDAP à la BDD :

```sh
php occ ldap:import-users-ad
```

# File Sharing

Remplacement du plugin Nextcloud File Sharing

Voir les fichiers [branche ENT](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-ent/files_sharing)

**Installation**

```sh
Make FILES_SHARING
```

# Gestion des buckets (S3)

Utilisation d'un hash par user, donc quasiment un bucket par user.

**Installation**

Remplacer `lib/private/Files/objectStore/Mapper.php`.

```sh
Make LIB
```

Voir les fichiers [branche ENT](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-ent/lib)

# Skeleton

Répertoire contenant le document par défaut à la creation d'un l'utilisateur.

**Installation**

À recopier dans `core/skeleton`.

```sh
Make SKELETON
```

Voir les fichiers [branche ENT](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-ent/skeleton) | [branche GIP](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-gip/skeleton) (même skleton pour les deux branches)

# Scripts

Ensemble des scripts utiles à l'exploitation:

- `loadEtabs.pl` : creation des comptes et groupes à partir de LDAP.
- `userFile.pl` : donne les fichiers et info d'un compte.
- `groupFinder.pl` : donne les membres d'un groupe.

Voir les fichiers [branche ENT](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-ent/scripts) | [branche GIP](https://github.com/GIP-RECIA/nextcloud-plugins/tree/master-gip/scripts)
