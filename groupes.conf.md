#la conf des groupes Nextcloud gip

php occ config:list ldapimporter

"cas_import_map_groups_fonctionel": "{\"0\":{\"filter\":\"^coll:Collectivites:(GIP-RECIA):Services:([^:]+):(?:Tous_)([^:]+)$\",\"naming\":\"${2}.GIP-RECIA\",\"quota\":\"50\",\"uaiNumber\":\"1\"},\"1\":{\"filter\":\"coll:Collectivites:(GIP-RECIA):Services:([^:]+):([^:]+)$\",\"naming\":\"${3}.${1}\",\"quota\":\"50\",\"uaiNumber\":\"1\"},\"2\":{\"filter\":\"^coll:admin:central$\",\"naming\":\"admin.central\",\"quota\":\"1\"},\"3\":{\"filter\":\"coll:Collectivites:(GIP-RECIA):groupes_locaux:ASC:(ASC_[^:]+)\",\"naming\":\"${2}.${1}\",\"quota\":\"50\",\"uaiNumber\":\"1\"},\"4\":{\"filter\":\"^coll:Collectivites:(GIP-RECIA):groupes_locaux:ASC:(Membres_ASC)$\",\"naming\":\"ASC.GIP-RECIA\",\"quota\":\"50\",\"uaiNumber\":\"1\"},\"5\":{\"filter\":\"coll:Collectivites:(GIP-RECIA):PERSONNEL:Tous_PERSONNEL\",\"naming\":\"GIP-RECIA\",\"quota\":\"100\",\"uaiNumber\":\"1\"},\"6\":{\"filter\":\"coll:Collectivites:(GIP-RECIA):STAGIAIRE:Tous_STAGIAIRE\",\"naming\":\"GIP-RECIA\",\"quota\":\"50\",\"uaiNumber\":\"1\"},\"7\":{\"filter\":\"^coll:Collectivites:(R\u00e9gion Centre):services:DGEECVC - DEJS:NUM\u00c9RIQUE EDUCATIF$\",\"naming\":\"responsables-SNE.Region Centre\",\"quota\":\"1\",\"uaiNumber\":\"1\"},\"8\":{\"filter\":\"^coll:Collectivites:(R\u00e9gion Centre):services:DGEECVC - DEJS:SNE - EQUIPE (NORD|EST|OUEST|SUD)$\",\"naming\":\"equipes-SNE.Region Centre\",\"quota\":\"1\",\"uaiNumber\":\"1\"}}",

"cas_import_map_regex_name_uai": "{\"0\":{\"nameUai\":\"coll:Collectivites:(GIP-RECIA):Tous_GIP-RECIA\",\"nameGroup\":\"1\"},\"1\":{\"nameUai\":\"coll:Collectivites:(R\u00e9gion Centre):Tous_R\u00e9gion Centre\",\"nameGroup\":\"1\"}}",


| Regex de nommage d'établissement et du UAI | Numéro du groupement dans la regex correspondant au nom de l'établissement |
|--------------------------------------------|----------------------------------------------------------------------------|
| coll:Collectivites:(GIP-RECIA):Tous_GIP-RECIA | 1 |
| coll:Collectivites:(Région Centre):Tous_Région Centre | 1 |


 Regex de filtre 																				Nommage			 				Numéro du groupement de la regex pour l'UAI ou le nom 	Quota

 ^coll:Collectivites:(GIP-RECIA):Services:([^:]+):(?:Tous_)([^:]+)$								${2}.GIP-RECIA					1														50
 coll:Collectivites:(GIP-RECIA):Services:([^:]+):([^:]+)$										${3}.${1}						1														50
 ^coll:admin:central$																			admin.central																			1
 coll:Collectivites:(GIP-RECIA):groupes_locaux:ASC:(ASC_[^:]+)									${2}.${1}						1														50
 ^coll:Collectivites:(GIP-RECIA):groupes_locaux:ASC:(Membres_ASC)$								ASC.GIP-RECIA					1														50
 coll:Collectivites:(GIP-RECIA):PERSONNEL:Tous_PERSONNEL										GIP-RECIA						1														100
 coll:Collectivites:(GIP-RECIA):STAGIAIRE:Tous_STAGIAIRE										GIP-RECIA						1														50
 ^coll:Collectivites:(Région Centre):services:DGEECVC - DEJS:NUMÉRIQUE EDUCATIF$				responsables-SNE.Region Centre	1														1
 ^coll:Collectivites:(Région Centre):services:DGEECVC - DEJS:SNE - EQUIPE (NORD|EST|OUEST|SUD)$	equipes-SNE.Region Centre		1														1
