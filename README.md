# LDAP Importer

Plugin pour nextcloud LDAP Importer

Tester sous nextcloud version 18
Tester avec le plugin "CAS Authentication backend" version : 1.8.1

## installation

A placer dans le dossier apps/ de nextcloud

## Utilisation

La commande pour importer les utilisateurs du LDAP à la BDD :

```
sudo -u www-data php occ ldap:import-users-ad
```

# School Sharing

Plugin pour nextcloud School Sharing

Tester sous nextcloud version 18

## installation

Remplacer TOTALEMENT le dossier files_sharing dans le dossier apps/ à la racine du projet.

Aller dans la configuration des plugins nextcloud via l'interface et activer le plugin 'School Sharing' si il n'est pas déjà activé.
