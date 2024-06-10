
# Réflexion sur la suppression des comptes NC-ent dans la base et dans le stockage objet.

## État des lieux.

### Les tables supplémentaires du recia avec leurs scripts de mise à jour :

- oc_etablissements :

	Mise à jour par 'ldapimporter' donne la liste des établissements (nom, uai, siren).

- oc_asso_uai_user_group : associe, les groupes NC venant du ldap et les uid,  aux établissements.

	Mise à jour par

	- 'ldapimporter' : ajout des uid et groupes créés
	- 'LoadGroupFolder' : ajout des groupes créés
	- 'cleanGroup.pl' : suppression des uid desactivé et des groupes vide

- oc_recia_user_history :

	'ldapimporter' :  insertion et mise à jour du dernier état du ldap.

- recia_bucket_history : associe les uids aux buckets.

	'saveBucketId.pl' : supprime les doublons éventuels, ajoute les nouveaux , pas de suppression.
 
- recia_storage : associe les uid au storage, avec l'espaces ocuppé

	'statVolume.pl' recalcule tout les jours sans suppression.

- recia_share : une vue qui donne les fichiers partagés.

### Désactivations des comptes :
'loadEtap.pl' qui execute 'occ ldap:import-users-ad' pour mettre a jour les comptes, ceux qui sont en DELETE ont le champs 'isdel' de la table 'oc_recia_user_history' mise à 1.

Ensuite 'loadEtab.pl' excute 'occ ldap:disable-deleted-user' qui désactive les comptes NC qui ont 'isdel' à 1 (mise à false dans oc_preferences du champs qui va bien), et met 'isdel' à 2.
régulièrement on verifie le 1000 comptes les plus anciens pour verifier qu'ils sont encore dans le ldap sinon on les supprimes comme si ils avaient eu le DELETE et met isDel a 2,
du coup ces compte sont indiqués comme VALIDE dans  oc_recia_user_history.

un script perl pas encore ecrit doit tester les comptes qui ont isDel à 2 et les passer a 3 si ils n'ont pas de partage.

'occ ldap:remove-disabled-user' doit effacer les comptes ayant 'isdel à 3 depuis plus de 60 jours et le mettre à 4. N'est pour le moment jamais appelé, pas vraiment testé non plus.

Pour le moment il n'y a pas de gestion des partages donc si on utilise 'occ ldap:remove-disabled-user' rien ne se passera car il n'y a pas de isDel a 3 .

Il faut un processus qui verifie que les comptes avec isDel à 4 sont bien supprimer ainsi que les bucket et si ok  supprimer les lignes concerné dans nos tables.
