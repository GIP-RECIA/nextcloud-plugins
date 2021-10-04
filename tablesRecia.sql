

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
    
