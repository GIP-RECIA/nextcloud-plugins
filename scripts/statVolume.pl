#!/usr/bin/perl
# script qui fait des states de volumes utilisé par le utilisateurs
# 

use strict;
use utf8;
use DBI();
# les 2 use suivant permette de trouver les libraries installées
#  dans le meme path que l'executable
use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;
binmode STDOUT, ':encoding(UTF-8)';
use Getopt::Long;
Getopt::Long::Configure ("bundling");
use Pod::Usage;


my $statEleve;
my $statPersonnel;
my $calculStat;
my $abrege;
GetOptions( "p|personnel" => \$statPersonnel,
			"e|eleve" => \$statEleve,
			"c|calcul"=> \$calculStat,
			"a|abrege" => \$abrege
		);

unless ($statEleve || $statPersonnel) {
	chdir $PARAM{'REP_ORG'};
	pod2usage(1);
}


my $eleveQuery = qq[
    insert IGNORE
    into recia_storage (storage, uid, categorie)
    select s.id, g.uid , 'E'
    from
        (   select distinct uid
            from oc_group_user 
            where  gid like 'Eleves%'
        ) g,
        (   select SUBSTRING_INDEX(id, ':', -1) uid , numeric_id id
            from oc_storages
        ) s
    where g.uid = s.uid
];

my $personnelQuery= qq[
    insert IGNORE
    into recia_storage (storage, uid, categorie)
    select s.id, g.uid, 'P'
    from
        (   select distinct uid
            from oc_group_user 
            where  gid like 'administratif.%'
            or gid like 'Agents_Coll_Ter.%'
            or gid like 'Profs.%'
            or gid like 'Maitre.%'
            or gid like 'administratif%'
            or gid like 'CONSEIL DEPARTEMENTA%'
            or gid in ('Academie', 'Inspecteurs', 'Dane', 'GIP-RECIA')
        ) g,
        (   select SUBSTRING_INDEX(id, ':', -1) uid , numeric_id id
            from oc_storages
        ) s
    where g.uid = s.uid
];

my $volumeQuery= qq[
    update  IGNORE
        recia_storage rs,
        (   select storage , sum(size) vol
            from oc_filecache
            where mimetype != 4 and storage != 1 group by storage
        ) st
    set rs.volume = st.vol
    where rs.storage = st.storage
    and rs.categorie = ?;
];

my $resultatQuery = qq[select storage, volume size from recia_storage where volume is not null and categorie = ?];

#my $sqlQuery = qq(select storage , sum(size) from oc_filecache where mimetype != 4 and storage != 1 group by storage);


my $sql = connectSql();


my $unM = 1024 * 1024;
my $unG = $unM * 1024;

my $sqlStatement ;
if ($calculStat) {
	if ($statEleve) {
		print "Init des éleves en base: \n";
		$sql->do($eleveQuery) or die $sql->errstr;

		print "Calcul des volumes Eleves:\n";
		$sqlStatement = $sql->prepare($volumeQuery) or die $sql->errstr;
		$sqlStatement->execute('E') or die $sqlStatement->errstr;
	}
	if ($statPersonnel) {
		print "Init des personnels en base: \n";
		$sql->do($personnelQuery) or die $sql->errstr;

		print "Calcul des volumes Personnel:\n";
		$sqlStatement = $sql->prepare($volumeQuery) or die $sql->errstr;
		$sqlStatement->execute('P') or die $sqlStatement->errstr;
	}
}

$sqlStatement = $sql->prepare($resultatQuery) or die $sql->errstr;

if ($statEleve) {
	print "\nStatistique Elèves :\n";
	print "Mo \tComptes\n";
	printStats('E', $unM);
}
if ($statPersonnel) {
	print "\nStatistique Personnels :\n";
	print "Go \tComptes\n";
	printStats('P', $unG);
}

sub printStats {
	my $cat = shift;
	my $unit = shift;
	my @NbComptes;
	$sqlStatement->execute($cat) or die $sqlStatement->errstr;
	
	while (my @ary = $sqlStatement->fetchrow_array) {
		my $nbG = int($ary[1] / $unit);
		$NbComptes[$nbG]++;
	}
	if ($abrege) {
		my $vide=0;
		for (my $cpt = 0 ; $cpt < @NbComptes; $cpt++) {
			my $nb = $NbComptes[$cpt];
			if ($nb) {
				if ($vide) {
					print $cpt - $vide , "\n";
					if ($vide > 2) {
						print "...\n";
					}
					if ($vide > 1) {
						print $cpt - 1, "\n";
					}
					$vide = 0;
				}
				print $cpt, "\t", $nb, "\n";
			} else {
				$vide++;
			}
		}
	} else {
		my $cpt=0;
		for (@NbComptes) {
			print $cpt++, "\t", $_, "\n";
		}
	}
}


__END__

=head1 SYNOPSIS

statVolume (-p | -e) [-c] [-a] 

 Options:
   -p            stat pour le personnel
   -e            stat pour les eleves
   -c            recalcul les stats en base, sinon ne fait que les afficher
   -a            présentation abrégée (sans toutes les colonnes vides)
=cut
