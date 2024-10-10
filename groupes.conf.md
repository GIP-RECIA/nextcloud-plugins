#la conf des groupes Nextcloud gip

	php occ config:list ldapimporter
	"cas_import_map_groups_fonctionel": "{\"0\":{\"filter\":\"^coll:Collectivites:(GIP-RECIA):Services:([^:]+):(?:Tous_)([^:]+)$\",\"naming\":\"${2}.GIP-RECIA\",\"quota\":\"50\",\"uaiNumber\":\"1\"},\"1\":{\"filter\":\"coll:Collectivites:(GIP-RECIA):Services:([^:]+):([^:]+)$\",\"naming\":\"${3}.${1}\",\"quota\":\"50\",\"uaiNumber\":\"1\"},\"2\":{\"filter\":\"^coll:admin:central$\",\"naming\":\"admin.central\",\"quota\":\"1\"},\"3\":{\"filter\":\"coll:Collectivites:(GIP-RECIA):groupes_locaux:ASC:(ASC_[^:]+)\",\"naming\":\"${2}.${1}\",\"quota\":\"50\",\"uaiNumber\":\"1\"},\"4\":{\"filter\":\"^coll:Collectivites:(GIP-RECIA):groupes_locaux:ASC:(Membres_ASC)$\",\"naming\":\"ASC.GIP-RECIA\",\"quota\":\"50\",\"uaiNumber\":\"1\"},\"5\":{\"filter\":\"coll:Collectivites:(GIP-RECIA):PERSONNEL:Tous_PERSONNEL\",\"naming\":\"GIP-RECIA\",\"quota\":\"100\",\"uaiNumber\":\"1\"},\"6\":{\"filter\":\"coll:Collectivites:(GIP-RECIA):STAGIAIRE:Tous_STAGIAIRE\",\"naming\":\"GIP-RECIA\",\"quota\":\"50\",\"uaiNumber\":\"1\"},\"9\":{\"filter\":\"^coll:Applications:Nextcloud_GIP-RECIA:([^:]+):([^:]+):([^:]+)$\",\"naming\":\"${3}.${1}.${2}\",\"quota\":\"1\",\"uaiNumber\":\"2\"}}",
	"cas_import_map_regex_name_uai": "{\"0\":{\"nameUai\":\"coll:Collectivites:(GIP-RECIA):Tous_GIP-RECIA\",\"nameGroup\":\"1\"},\"1\":{\"nameUai\":\"^coll:Collectivites:(([^\\\\s:]+)\\\\sCentre):Tous_\\\\1$\",\"nameGroup\":\"1\"},\"2\":{\"nameUai\":\"^coll:Collectivites:(CONSEIL DEPARTEMENTAL([^:]+)):Tous_\\\\1$\",\"nameGroup\":\"1\"}}",




Les exemples qui doivent matcher pour dterminé les etabs:

	coll:Collectivites:CONSEIL DEPARTEMENTAL DE L INDRE:Tous_CONSEIL DEPARTEMENTAL DE L INDRE
	coll:Collectivites:Région Centre:Tous_Région Centre
	coll:Collectivites:DRAAF Centre:Tous_DRAAF Centre

| Regex de nommage d'établissement et du UAI | Numéro du groupement dans la regex correspondant au nom de l'établissement |
|--------------------------------------------|----------------------------------------------------------------------------|

	coll:Collectivites:(GIP-RECIA):Tous_GIP-RECIA | 1 |
	^coll:Collectivites:(([^\s:]+)\sCentre):Tous_\2 Centre$
	^coll:Collectivites:(CONSEIL DEPARTEMENTAL([^:]+)):Tous_\1$ 	1


	Regex de filtre 																				Nommage			 				Numéro du groupement de la regex pour l'UAI ou le nom 	Quota
	^coll:Collectivites:(GIP-RECIA):Services:([^:]+):(?:Tous_)([^:]+)$								${2}.GIP-RECIA					1														50
	coll:Collectivites:(GIP-RECIA):Services:([^:]+):([^:]+)$										${3}.${1}						1														50
	^coll:admin:central$																			admin.central					 														1
	coll:Collectivites:(GIP-RECIA):groupes_locaux:ASC:(ASC_[^:]+)									${2}.${1}						1														50
	^coll:Collectivites:(GIP-RECIA):groupes_locaux:ASC:(Membres_ASC)$								ASC.GIP-RECIA					1														50
	coll:Collectivites:(GIP-RECIA):PERSONNEL:Tous_PERSONNEL											GIP-RECIA						1														100
	coll:Collectivites:(GIP-RECIA):STAGIAIRE:Tous_STAGIAIRE											GIP-RECIA						1														50
	^coll:Collectivites:(Région Centre):services:DGEECVC - DEJS:NUMÉRIQUE EDUCATIF$					responsables-SNE.Region Centre	1														1
	^coll:Collectivites:(Région Centre):services:DGEECVC - DEJS:SNE - EQUIPE (NORD|EST|OUEST|SUD)$	equipes-SNE.Region Centre		1														1
	^coll:Applications:Nextcloud_GIP-RECIA:([^:]+):([^:]+):([^:]+)$ 								${3}.${2}.${1}					2														1
	^coll:Applications:Nextcloud_(GIP-RECIA):([^:]+):([^:]+)$										${2}.${3}						1														1
