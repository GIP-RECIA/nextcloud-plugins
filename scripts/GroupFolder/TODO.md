#### TODO liste pour l'alimentation des groupes folders.

ajouter dans l'alim des groupes pour le cher le groupe service relation collège

il existe déjà : ^coll:Applications:Nextcloud:(CONSEIL[^:]+)$

il fauta ajouter :  coll:Collectivites:CONSEIL DEPARTEMENTAL DU CHER:AGENT DU SIEGE:Tous_AGENT DU SIEGE
=> entretiens professionnels CD18


- remplacer la vielle synchro des comptes et groups


- metre dans l'ancienne synchro la creation des groupes suivant

^coll:Collectivites:(CONSEIL DEPARTEMENTAL DU CHER):groupes_locaux:Evaluations professionelles:Managers
Evaluations professionelles.CONSEIL DEPARTEMENTAL DU CHER

clg18:Etablissements:([^_:]+\_(\d{7}\w)):Administratifs:\_DIRECTION:CHEF D ETABLISSEMENT( ADJOINT)?
CHEF D ETABLISSEMENT.%2$s
CHEF D ETABLISSEMENT.${1}

clg18:Etablissements:([^_:]+\_(\d{7}\w)):Administratifs:\_PERSONNELS ADMINISTRATIFS:GESTIONNAIRE
GESTIONNAIRE.%2$s
GESTIONNAIRE.${1}
