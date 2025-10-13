
CREATE TABLE oc_etablissements (
	id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
	name VARCHAR(255),
	uai VARCHAR(255),
	siren VARCHAR(255)
)

CREATE TABLE oc_asso_uai_user_group (
	id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
	id_etablissement VARCHAR(255),
	user_group VARCHAR(255)
);

/* historisation des user
	isadd = 0 si la derniere mise a jour n'etait pas un ajout
			= 1 si derniere modif est un ajout
	isdel = 0 si n'est pas en etat SUPPRIMER
		= 1 quand le compte  est dans l'état DELETE
		= 2 quand le compte est disabled (ldapimporter/lib/Service/Delete/DeleteService.php 259)
		= 3 quand le compte est supprimé (ldapimporter/lib/Service/Delete/DeleteService.php 139)
*/
CREATE TABLE oc_recia_user_history (
	uid char(8) PRIMARY KEY,
	siren varchar(15), 
	dat date, 
	eta varchar(32),
	isadd tinyint(1),
	isdel tinyint(1),
/*	hasRep tinyint(1), */
	name varchar(100),
	UNIQUE (siren, isdel, uid)
);

create table recia_bucket_history (
	bucket varchar(128) ,
	uid varchar(64),
	creation date,
	suppression date,
	primary key (bucket, uid)
);

create or replace view recia_share as 
(select s.*, f.path from oc_share s, oc_filecache f
where s.file_source = f.fileid
);

create or replace view recia_etab_par_taille as (
    select e.*, count(a.id) taille 
    from oc_etablissements e, oc_asso_uai_user_group a 
    where e.id = a.id_etablissement 
    group by e.id
    order by taille desc
);
    

create table recia_storage  (
	storage bigint,
	uid varchar(64) not null,
	categorie char(1) not null,
	volume bigint,
	primary key (storage),
	unique (uid)
);

insert IGNORE into recia_storage (storage, uid, categorie)
select s.id, g.uid , 'E' from
(select distinct uid
from oc_group_user 
where  gid like 'Eleves%'
) g,
(select SUBSTRING_INDEX(id, ':', -1) uid , numeric_id id  from oc_storages ) s
where g.uid = s.uid
;

insert IGNORE into recia_storage (storage, uid, categorie)
select s.id, g.uid, 'P'  from
(select distinct uid
from oc_group_user 
where  gid like 'administratif.%'
or gid like 'Agents_Coll_Ter.%'
or gid like 'Profs.%'
or gid like 'Maitre.%'
or gid like 'administratif%'
or gid like 'CONSEIL DEPARTEMENTA%'
or gid in ('Academie', 'Inspecteurs', 'Dane', 'GIP-RECIA')
) g,
(select SUBSTRING_INDEX(id, ':', -1) uid , numeric_id id  from oc_storages ) s
where g.uid = s.uid
;

update IGNORE recia_storage rs, (select storage , sum(size) vol from oc_filecache where mimetype != 4 and storage != 1 group by storage) st
set rs.volume = st.vol
where rs.storage = st.storage;

/* vue qui donne les partages directes d'un owner à une personne
	donne les repertoires partagés mais pas les fichiers du répertoire
	ne donne pas non plus les partages a un groupe.
	select distinct share_type from oc_share; 
+------------+
| share_type |
+------------+
|          0 | -> a des personnes
|          1 | -> a des groupes
|          2 | -> a des personnes via un groupe dans ce cas le partage a un parent : le partage au groupe
|          3 | -> partage public link
|          4 | -> partage par mail
|         12 | -> deck '/{DECK_PLACEHOLDER}' ressemble au 1 sauf le share_with est un numero 
|         13 | -> deck a des personne ressemble au 2 avec un groupe a la deck et parent avec share_type 12
+------------+
*/ 

create or replace view recia_direct_partages as (
	select f.fileid, f.storage,  f.parent, f.path, p.uid_owner, (p.item_type = 'folder') isFolder, f.mimetype, regexp_substr(f.path, '(?<=__groupfolders/)\\d+') gfid, share_type
	from oc_share p, oc_filecache f
	where f.fileid = file_source
	and share_type in (0, 2, 13)
);

/* une table pour initialiser le calcul, des fichiers partagés ou non.
	Utilisé dans les vues: recia_rep_with_partage, 
	la table doit contenir pour chaque uid
	le storage (numerique id)
	le fileid de la racine de l'arbre des fichiers pour le compte (uid)
	et le mimetype de cette racine (depend des instances de NC)
*/
create  table recia_init_nopartage_temp (
storage bigint primary key  ,
fileid bigint unique,
uid char(8) unique,
mimetype bigint
);

/* un exemple d'init de la table

insert into recia_init_nopartage_temp (
select s.numeric_id, f.fileid, h.uid, f.mimetype 
from  oc_recia_user_history h, oc_storages s, oc_filecache f
where isDel = 2 and datediff(now(), dat) > 60
and s.id = concat('object::user:', h.uid)
and f.storage = s.numeric_id
and f.parent = -1
and f.path = ''
and s.numeric_id is not null
order by h.dat  limit 2000
);

*/

/* Les vues utilisées pour LA SUPPRESSION DES REPERTOIRE UTILISATEUR */


/* 	Une vue qui donne les répertoire partagés:
	un répertoire partagé est soit partagé explicitement soit contenue dans un repertoire partagé

	Utilise recia_init_nopartage_temp 	pour limiter aux comptes qui nous intéresse.
			recia_direct_partages  		pour initialiser avec les partages directe de répertoire.
	Puis fait un parcour top down. 
*/
create or replace view recia_rep_partages as
with recursive reppartage as (
	/* init avec les partages sur les storages de la table recia_init_nopartage_temp */
	select distinct t.storage,  if(p.isFolder = 1, p.fileid, null) fileid, p.parent , if(p.isFolder = 1, p.path, REGEXP_replace(p.path, '/[^/]+$', '')) path, t.mimetype
	from recia_init_nopartage_temp t , recia_direct_partages p
	where p.storage = t.storage
	and p.mimetype = t.mimetype
	union
	/* on descent dans tous les sous-repertoires */
	select p.storage,  f.fileid, f.parent, f.path, f.mimetype
	from reppartage p , oc_filecache f
	where f.parent = p.fileid
	and f.mimetype = p.mimetype
) select * from reppartage where fileid is not null  order by storage, path;


/* 	Une vue qui donne les repertoires contenant des partages,
	pour tout les comptes initialisés dans recia_init_nopartage_temp.

	Les répertoires contenants des partages sont 
	ceux qui ont des fichiers ou des répertoires partagés
	ou des répertoires contenant des partages.
	 
	Utilise: 	recia_init_nopartage_temp 	pour limiter aux comptes qui nous intéresse.
				recia_direct_partage		pour initialiser avec les répertoires contenants de partages directe de fichier
				recia_rep_partages 			pour initialiser avec les répertoires partagés (même indirecte).
	Fait un parcour bottom up 
*/
create or replace view recia_rep_avec_partage as
with recursive repwithpartage as (
	/* init avec les partages sur les storage de la table recia_init_nopartage_temp */
	select distinct t.storage,  if(p.isFolder = 1, p.fileid, null) fileid, p.parent , if(p.isFolder = 1, p.path, REGEXP_replace(p.path, '/[^/]+$', '')) path
	from recia_init_nopartage_temp t , recia_direct_partages p
	where p.storage = t.storage
	and p.mimetype != t.mimetype /* on ne prend pas les repertoires pris dans l'union suivantes */
	union /* on ajoute les répertoires partagés */
	select p.storage,  p.fileid, p.parent, p.path
	from recia_init_nopartage_temp t, recia_rep_partages p
	where p.storage = t.storage
	union
	/* on remonte sur les repertoires contenant */
	select p.storage,  f.fileid, f.parent, f.path
	from repwithpartage p , oc_filecache f
	where p.parent = f.fileid
) select * from repwithpartage where fileid is not null  order by storage, path
;

/* 	Une vue qui donne les repertoires ne contenant pas de partage
	pour tout les comptes initialisés dans
					recia_init_nopartage_temp
	utilise aussi : recia_direct_partages,
					recia_rep_avec_partage.

    utilisé dans scripts/removeOldUser.pl:446
*/
create or replace view recia_rep_sans_partage as
select  f.storage, f.fileid, f.parent, f.path
from recia_init_nopartage_temp t, oc_filecache f left join recia_rep_avec_partage r on f.fileid = r.fileid
where t.storage = f.storage
and f.mimetype = t.mimetype
and r.fileid is null
order by f.storage, f.path;

/* 	Vue qui donne les fichiers et repertoires non partagés ayant un path = 'files/...'
	Ils ne doivent pas être dans un répertoire partagé.
	Attention un répertoire non partagé peut contenir des partages.
	Fait donc un parcour top down.

	utilisé dans scripts/removeOldUser.pl:491
*/
create or replace view recia_files_non_partage as 
with recursive nopartage as (
    select  f.fileid, f.storage , f.path, f.mimetype = r.mimetype isrep, f.mimetype
    from  recia_init_nopartage_temp r, oc_filecache f left join recia_direct_partages p on f.fileid = p.fileid
    where r.storage = f.storage
    and (f.parent = r.fileid or f.parent = -1)
    and f.path = 'files'
    and p.fileid is null 
    union 
    select f.fileid, f.storage , f.path, f.mimetype = n.mimetype isrep, f.mimetype
    from  nopartage n, oc_filecache f left join recia_direct_partages p on f.fileid = p.fileid 
    where f.storage = n.storage
    and f.parent = n.fileid
    and p.fileid is null
    ) select fileid, storage , isrep, path from nopartage where !isrep order by storage, path ;

