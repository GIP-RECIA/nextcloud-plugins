#### Adaptation a nextcloud pour le gip recia

Le recia à deux déploiements de NC sur la même architecture une pour les
ENT dans lycées et collèges (nc-ent) et l'autre pour le gip lui-même et les collectivités (nc-gip)


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

Plugin pour nextcloud LDAP Importer

Tester sous nextcloud version 18
Tester avec le plugin "CAS Authentication backend" version : 1.8.1

## Installation

A placer dans le dossier apps/ de nextcloud

## Utilisation

La commande pour importer les utilisateurs du LDAP à la BDD :

```
sudo -u www-data php occ ldap:import-users-ad
```

# School Sharing

Plugin pour nextcloud School Sharing

Tester sous nextcloud version 18

## Installation

Remplacer TOTALEMENT le dossier files_sharing dans le dossier apps/ à la racine du projet.

Aller dans la configuration des plugins nextcloud via l'interface et activer le plugin 'School Sharing' si il n'est pas déjà activé.

# CSS JS Loader

Plugin pour nextcloud CSSJSLoader qui surcharge le css et le js de toutes les pages

Tester sous nextcloud version 18

## Installation

A placer dans le dossier apps/ de nextcloud

## Utilisation

- Placer les ficher js dans le dossier `apps/cssjsloader/inputs/js`
- Placer les ficher css dans le dossier `apps/cssjsloader/inputs/css`


# Skeleton

Répertoire contenant le document par défaut à la creation d'un l'utilisateur.
À recopie dans core/skeleton


# s3 gestion des buckets:
remplacer  ./lib/private/Files/objectStore/mapper.php
par notre version
