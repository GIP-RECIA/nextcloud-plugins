# LDAP Importer

Plugin pour nextcloud LDAP Importer 

Tester sous nextcloud version 18
Tester avec le plugin "CAS Authentication backend" version : 1.8.1

A placer dans le dossier apps/ de nextcloud

## Utilisation

La commande pour importer les utilisateurs du LDAP à la BDD  :

```
sudo -u www-data php occ ldap:import-users-ad
```