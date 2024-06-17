
CREATE TABLE oc_etablissements (
	id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
	name VARCHAR(255),
	uai VARCHAR(255),
	siren VARCHAR(255),
	unique (siren),
	unique (uai)
);

CREATE TABLE oc_asso_uai_user_group (
	id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
	id_etablissement VARCHAR(255),
	user_group VARCHAR(255)
);

-- attention sur ncprod cette requete ne donne pas un resultat vide et donc on ne peut pas passer le alter table suivant
select id_etablissement, user_group, count(id) from oc_asso_uai_user_group group by id_etablissement, user_group having count(id) > 1;
alter table oc_asso_uai_user_group add constraint uk_etabGroup unique (id_etablissement, user_group);


-- create table recia_user_history as (select * from oc_recia_user_history);
-- drop table oc_recia_user_history; 

CREATE TABLE oc_recia_user_history (
	uid char(8) PRIMARY KEY,
	siren varchar(15), 
	dat date, 
	eta varchar(32),
	isadd tinyint(1),
	isdel tinyint(1),
	hasRep tinyint(1),
	name varchar(100),
	UNIQUE (siren, isdel, uid)
);

insert into oc_recia_user_history select uid, siren, dat, eta, isadd, isdel, 1, name from recia_user_history;


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

-- le reste devrait etre inutile pour le gip

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
|         13 | -> deck a des personne resemble au 2 avec de groupe a la deck et parent avec share_type 12
+------------+
*/ 
create or replace view recia_direct_partages as (
	select f.fileid, f.path, p.uid_owner, (p.item_type = 'folder') isFolder, f.mimetype, regexp_substr(f.path, '(?<=__groupfolders/)\\d+') gfid, share_type
	from oc_share p, oc_filecache f
	where f.fileid = item_source
	and share_type in (0, 2, 13)
);
