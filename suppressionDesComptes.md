
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
régulièrement on verifie le 1000 comptes les plus anciens pour verifier qu'ils sont encore dans le ldap sinon on les supprimes on les marques DELETE_NOT_IN_LDAP et met isDel a 2.



'occ ldap:remove-disable-user' doit effacer les comptes ayant 'isdel à 2 depuis plus de 60 jours et le mettre à 3. N'est pour le moment jamais appelé, pas vraiment testé non plus.

Pour le moment il n'y a pas de gestion des partages donc si on utilise 'occ ldap:remove-disable-user' les fichiers partagés seront perdus.
adddate(dat, 60) 
## A faire :
# suppressions des vieux comptes désactivé vide (jamais connecté).
select s.uid from recia_storage s,  oc_recia_user_history h , oc_users u where h.isdel = 2 and h.eta = 'DELETE' and h.uid = s.uid and (s.volume is null or s.volume = 0) and adddate(h.dat, 60) < curdate() and u.uid = s.uid;

1er idée : calculer dans recia_storage le nombre de partage , on pourrait ainsi supprimer les comptes sans partage
=> ajouter une colonne (nbShareIfDel) dans recia_storage qui donne le nombre de partage si la personne est en suppression (isDel = 2), null sinon: 


-  supprimer les fichier non partagés des comptes désactivé obsolète,
ATTENTION un fichier peut être partagé via un répertoire donc c'est le répertoire qui est partagé

select f.path from oc_storages s, oc_filecache f
where s.id =  'object::user:F08001us'
and s.numeric_id = f.storage
and not exists (select file_source from oc_share where file_source = f.fileid);



- supprimer les partages aux comptes désactivé obsolète
les partages a des comptes désactivé:
select h.uid, s.share_with, s.uid_owner, s.uid_initiator, h.eta, h.dat,  h.isdel, h.name from oc_share s , oc_recia_user_history h
where  h.isdel = 2 and h.eta = 'DELETE' and h.uid = s.share_with and adddate(h.dat, 60) < curdate();
