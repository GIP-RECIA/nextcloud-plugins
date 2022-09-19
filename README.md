#### Adaptation a nextcloud pour le gip recia

Le recia à deux déploiements de NC sur la même architecture une pour les
ENT dans lycées et collèges (nc-ent) et l'autre pour le gip lui-même et les collectivités (nc-gip, gip.nextcloud.recia.aquaray.com) 


Les modifications portent principalement sur :
- la gestion des groupes (ldap importer):
Données les droits (quota) et créer les groupes NC à partir des groupes LDAP.

- La recherche de groupe et personne pour le partage (file_sharing):
uniquement pour 'nc-ent'.

- gestion des buckets (nc-ent uniquement):
n'avoir qu'un bucket par compte , par avatar et vignette.

- un plugin de chargement de js et css particulier (uniquement nc-ent cssjsLoader)

- les fichiers par défauts (uniquement nc-ent):
suppression modification du repertoire skeleton


# LDAP Importer

Plugin LDAP Importer
Permet l'alimentation des utilisateurs avec filtrage sur leurs groupes LDAP.
On en déduit leurs groupes NC et leurs quota.
Les filtres sont paramètrés avec des regexs dans "Paramètres -> sécurité -> Import Users -> Filtre & nomage de groupe"

- Une première serie de regex permet de deduire les nom des établissement (pour NC) à partir des groupes LDAP.
- La deuxième définit les groupes NC à partir des groupes LDAP (fixe le quota minimum),
sans groupe de cette serie un user LDAP ne sera pas importer dans NC.

- La troisièmes définit les groupes NC à partir des groupes pédagogiques de l'utilisateur, ce ne sont pas des groupes fonctionnels, ils  ne sont pas dans le isMemberOf du LDAP.
Il faut donc définir l'attribut LDAP approprié. 
  
Tester sous nextcloud version 24
Tester avec le plugin "CAS Authentication backend" version : 1.10

## Installation

A placer dans le dossier apps/ de nextcloud

## Utilisation

La commande pour importer les utilisateurs du LDAP à la BDD :

```
sudo -u www-data php occ ldap:import-users-ad
```

# File Sharing

Remplacement du plugin nextcloud File Sharing

Tester sous nextcloud version 24

## Installation

Remplacer TOTALEMENT le dossier files_sharing dans le dossier apps/ à la racine du projet.


# CSS JS Loader

Plugin pour nextcloud CSSJSLoader qui surcharge le css et le js de toutes les pages

Tester sous nextcloud version 24

## Installation

A placer dans le dossier apps/ de nextcloud

## Utilisation

- Placer les ficher js dans le dossier `apps/cssjsloader/inputs/js`
- Placer les ficher css dans le dossier `apps/cssjsloader/inputs/css`


# Skeleton

Répertoire contenant le document par défaut à la creation d'un l'utilisateur.
À recopie dans core/skeleton


# s3 gestion des buckets:
remplacer  	./lib/private/Files/objectStore/Mapper.php
			./lib/private/Files/Mount/RootMountProvider.php
par nos versions
et  ajouter dans ./lib/private/Files/ObjectStore:
	ReciaObjectStoreStorage.php  S3Recia.php

Mapper.php distribut un bucket par user (c'est un hash donc quasiment un bucket par user).
ReciaObjectStoreStorage.php  S3Recia.php permetent de na pas stocker tous les avatars et bréview dans le même bucket system (bucket 0).
