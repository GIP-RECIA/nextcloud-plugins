

create table recia_bucket_history (
		bucket varchar(128) ,
		uid varchar(64),
		creation date,
		suppression date,
		primary key (bucket, uid)
	)

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
