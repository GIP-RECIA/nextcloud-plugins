## La conf de loadGroupFolders.
La déclaration des groupes et de leurs associations aux GroupFolders ce fait dans le fichier 'config.yml'.

### Micro rappel de la syntaxe yaml et conventions.
Les paramètres sont déclarés avec la syntaxe "clé: valeur";
ainsi 

	nom: GIP-RECIA

associe la valeur "GIP-RECIA" à la clé *nom*.
La valeur peut être une liste de valeurs ordonnées, l'ordre a de l'importance !

Ainsi 

	permF:
		- write
		- delete
		- share

déclare une liste de droit, chaque élément d'une liste est indenté (2 espaces au moins) et signalé par un '-', à ne pas oublier.

Une liste vide doit avoir pour valeur []:

	permF: []

Chaque élément d'une liste de valeurs peut être un sous-ensemble de "cle:valeur", par exemple:

	etabs:
		- nom: GIP-RECIA
		  siren: 18450311800020
		  ldapFilterGroups: ....
	      regexs: ...

Ici l'ordre des clés *nom*, *siren*, *ldapFilterGroups* et *regexs* n'a pas d'importance sémantique , mais pour plus de lisibilité, on respectera toujours le même ordre.


Les traitements respecteront les ordres des listes.
Ainsi les établissements seront traités  dans l'ordre de leurs déclarations.
De même pour les regexs, c'est important : chaque regex filtre tous les groupes Grouper avant de passer à la suivante, donc les groupes NC et GroupFolders sont créés dans l'ordre de leurs déclarations.

### Les paramètres:
Dans l'ordre d'utilisation (avec la bonne indentation):

**etabs**: Liste des établissements à traiter.  
	C'est la racine de l'arborecence des paramètres.

- **nom**: Nom de l'établissement.

- **siren**: siren de l'établissement.

- **ladpFiltrerGroups**: filtre ldap pour retrouver les groupes, de l'établissement, qui nous intéresses.  
	La recherche se fait sur la branche "ou=groups".

- **regexs**: liste de **regex** pour filtrer les groupes Grouper obtenus par la recherche donnée par **ladpFiltrerGroups**.

	- **regex**: une regex 

	- **last**: permet de sortir le groupe Grouper testé, avec les **regex** de même niveau (), de la liste des groupes.  
	2 valeurs possibles:
		- *ifMatch*:	le groupe est sorti après les traitements ssi il vérifie la **regex** de même niveau;  
		Il ne sera donc pas testé avec les regexs suivantes.
		- *ifNoMatch*: le groupe est sorti sans traitements ssi il ne vérifie pas la **regex** de même niveau.  
	Permet de sortir des traitements suivants un groupe ne respectant la **regex**.

	- **groups**: liste des groupes NC à créer ssi la **regex** match le groupe Grouper.  
		- **group**: Format (à la printf du C) pour déduire le nom du groupe NC à créer, à partir des groupements de la **regex** qui match le groupe Grouper. 

		- **folders**: liste des GroupFolder à créer associés aux groupes NC donnés par **group**.
			- **folder**: Format (à la printf du C) pour déduire le nom du GroupFolder à créer (point de montage).

			- **permF**: liste des permisions du groupe NC sur le GF;  
					3 valeurs possibles:
				- *write*
				- *delete*
				- *share*
			
				sans **permF** le GF ne sera pas créé, si aucune permission mettre la liste vide [].
			- **quotaF**: Quota en Go associé au GF, obligatoire pour créer le GF.

		- **admin**: regex qui filtre parmis tous des GroupFolders existant ceux sur lesquels le groupe NC donné par **group** aurra des droits d'administration.

### Exemple et raccoursi.
Pour les paramètres de listes **groups** et **folders**, si la liste contient qu'un élément
on peut omettre le paramètre de liste et déclarer son contenu directement dans son contenant (resp **regex** et **group**)
Par exemple:

      - regex: '^coll:Collectivites:(GIP-RECIA):groupes_locaux:(ASC):(ASC_[^:]+)$'
        groups:
          - group: '%2$s.%1$s'
            folders:
              - folder: 'ASC'
                permF: []
                quotaF: 1
          - group: '%3$s.%1$s'
            folders:
              - folder: 'ASC/%3$s'
                permF:
                  - write
                  - share
                  - delete
                quotaF: 100
      - regex: '^coll:Collectivites:(GIP-RECIA):groupes_locaux:(ASC):(ASC_Bureau)$'
        groups:
          - group: '%3$s.%1$s'
            admin: '^ASC(/.*)?$'

Peut se réécrir en:      

      - regex: '^coll:Collectivites:(GIP-RECIA):groupes_locaux:(ASC):(ASC_[^:]+)$'
        groups:
          - group: '%2$s.%1$s'
            folder: 'ASC'
            permF: []
            quotaF: 1
          - group: '%3$s.%1$s'
            folder: 'ASC/%3$s'
            permF:
              - write
              - share
              - delete
            quotaF: 100
	  - regex: '^coll:Collectivites:(GIP-RECIA):groupes_locaux:(ASC):(ASC_Bureau)$'
        group: '%3$s.%1$s'
        admin: '^ASC(/.*)?$'

Dans cette exemple, on voit que tous les groupes Grouper qui match la 1re regex vont créer le GroupFolder *ASC* et un autre, fonction de son nom (*ASC/...*).  
Le GF *ASC* ne sera créé qu'une fois, avec le 1er groupe  Grouper, qui match, mais tous les groupes compatibles suivants lui seront associés.  
C'est la façon pour associer plusieurs groupes Grouper à un même GF.

La dernière regex ne créé pas de GF, mais elle permet de donner les droits admin aux membres de *ASC_Bureau* sur tous les GF créés par la 1re regex.
Elle doit être positionée en dernier pour que les GF soient créés avant son application.
