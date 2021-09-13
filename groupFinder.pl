use strict;
use utf8;
use DBI();
# les 2 use suivant permette de trouver les libraries installées
#  dans le meme path que l'executable
use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;
binmode STDOUT, ':encoding(UTF-8)';

# un script pour afficher/rechercher les utilisateurs d'un groupe.

unless (@ARGV) {
	print "usage :\t$0 [-m] groupePattern \n";
	print "\t si -m on affiche les membres\n";
	print "\t groupePattern est un pattern de groupe à la SQL (avec éventuelement des % ou _)\n"; 
	exit 1;
}

my $withUser = 0;
my $grpPattern;
if ($ARGV[0] eq '-m' ) {
	$withUser = 1;
	$grpPattern = $ARGV[1];
} else {
	$grpPattern = $ARGV[0];
}

my $sqlGroup = "select gid from  oc_groups where gid like ?";

my $sqlMembre = "select u.uid, u.displayname, g.gid from oc_users u , oc_group_user g where g.gid = ? and g.uid = u.uid ";

my $sql = connectSql();

my $sqlStatement = $sql->prepare($sqlGroup) or die $sql->errstr;

$sqlStatement->execute($grpPattern) or die $sqlStatement->errstr;

my @allGroups;

while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
	my $gid = $tuple->{'gid'};
	push @allGroups, $gid;
}

$sqlStatement = $sql->prepare($sqlMembre) or die $sql->errstr;
if (@allGroups) {
	foreach my $gid (@allGroups) {
		print "$gid : \n";
		if ($withUser) {
			$sqlStatement->execute($gid) or die $sqlStatement->errstr;
			while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
				print "\t\t$tuple->{'uid'} $tuple->{displayname}\n";
			}
		}
	}
}
print "\n", scalar @allGroups,  " groupes trouvés\n";
