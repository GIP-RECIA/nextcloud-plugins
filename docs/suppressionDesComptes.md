
# La suppression des comptes NC-ent dans la base et dans le stockage objet.

## Les tables supplémentaires du recia :

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

## Les scripts de mise à jour et de désactivations des comptes :
### loadEtap.pl:
 execute 'occ ldap:import-users-ad' pour mettre a jour les comptes, ceux qui sont en DELETE ont le champs 'isdel' de la table 'oc_recia_user_history' mise à 1.

Ensuite 'loadEtab.pl' excute 'occ ldap:disable-deleted-user' qui dans DeleteService.php met à isdel=2 aux comptes NC qui ont 'isdel' à 1 et qui n'existe plus dans ldap.

régulièrement on verifie le 1000 comptes les plus anciens pour verifier qu'ils sont encore dans le ldap sinon on les supprimes comme si ils avaient eu le DELETE et met isDel a 2,
du coup ces compte sont indiqués comme VALIDE dans  oc_recia_user_history.

### removeOldUser.pl :
-	test les comptes obsolete (isDel = 2 et > 60 jour)  beneficiant d'un partage et supprime ce partages.
-	test les comptes obsolete n'ayant pas fait de partage (ou ayant des partages expiré depuis plus de 60 jours) et le marque isDel = 3; et les désactive (oc_preferences core enabled false).
-	expire a la date du jour les partages public des comptes obsoletes. 
-	lance occ ldap:remove-disabled-user
-	Pour limité le nombre d'update et delete removeOldUser prend le nombre d'action a faire en parametre (<= 1000), les suppressions se feront donc sur plusieurs jours.
	
### occ ldap:remove-disabled-user' :
 efface les comptes ayant 'isdel' à 3 depuis plus de 60 jours et le met à 4. Il supprime définitivement les comptes avec leurs fichier et partages.
Les comptes ayant isDel à 3 ne devraient plus avoir de partage.

### reste a faire
Il faut un processus qui verifie que les comptes avec isDel à 4 sont bien supprimer ainsi que les bucket et si ok  supprimer les lignes concerné dans nos tables (oc_recia_user_history, recia_bucket, recia_storage ...).
verifier aussi les buckets correspondant au avatar et prewiew .
les avatar sont dans des bucket de la forme : s3://nc-recette-0f19z004g (l'uid est en minuscule)
les previews dans des buckets de la forme : s3://nc-recette-0preview10 (le 10 est remplacer par des valeurs modulo 1000)

