### les groupes folders du cd 18

- GF: entretiens pro ATTEE18
	- groupe: Evaluations professionelles.CONSEIL DEPARTEMENTAL DU CHER (Write Share Delete)
	- groupe: CHEF D ETABLISSEMENT.nomEtab_uai
	- groupe: GESTIONNAIRE.nomEtab_uai

- GFs: Évaluations pro ATTE18/nomEtab_uai
	- groupe: CHEF D ETABLISSEMENT.nomEtab_uai (W D)
	- groupe: GESTIONNAIRE.nomEtab_uai (W D)
	- groupe: Evaluations professionelles.CONSEIL DEPARTEMENTAL DU CHER (W D)

les groupes NC sont créés à partir des groupes grouper suivant:

- coll:Collectivites:(CONSEIL DEPARTEMENTAL DU CHER):groupes_locaux:Evaluations professionelles:Managers
- clg18:Etablissements:*:Administratifs:_DIRECTION:CHEF D ETABLISSEMENT
- clg18:Etablissements:*:Administratifs:_PERSONNELS ADMINISTRATIFS:GESTIONNAIRE

### ce que l'on pourrait faire

- GF:  ATTEE18
	- groupe: ATTEE18.CONSEIL DEPARTEMENTAL DU CHER (Write Share Delete)
	- groupe: CHEF D ETABLISSEMENT.nomEtab_uai
	- groupe: GESTIONNAIRE.nomEtab_uai

- GF: ATTEE18/nomEtab_uai
	- groupe: CHEF D ETABLISSEMENT.nomEtab_uai (W D)
	- groupe: GESTIONNAIRE.nomEtab_uai (W D)
	- groupe: ATTEE18.CONSEIL DEPARTEMENTAL DU CHER (W D)


avec création dans chaque GF de deux répertoires:
	- entretiens pro
	- planning
qui créé les répertoires et copie les données ?
j'ai pas compris ou se place "Agents volents" !

si c'est "ATTEE18/Agents volents" ca peut être un simple répertoire (en fonction des droits),

si c'est un groupFolder sur quel groupe (grouper) il est basé et qui l'alimente ?
