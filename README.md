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
