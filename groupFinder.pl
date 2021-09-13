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
	print "usage :\t$0 [-m][-p] groupePattern \n";
	print "\t -m => affiche les membres\n";
	print "\t -p => affiche les partage\n";
	print "\t groupePattern est un pattern de groupe à la SQL (avec éventuelement des % ou _)\n"; 
	exit 1;
}

my $withUser = 0;
my $withPartage = 0;
my $grpPattern;
foreach my $param (@ARGV) {
	if ($param =~ /^-/) {
		$withUser = 1 if $param eq '-m';
		$withPartage = 1 if $param eq '-p';
	} else {
		$grpPattern = $param;
	} 
} 

unless ($grpPattern) {
	print "Error: manque le patterne de groupe\n";
	exit 1;
}

my $sqlGroup = "select gid from  oc_groups where gid like ?";



my $sql = connectSql();

my $sqlStatement = $sql->prepare($sqlGroup) or die $sql->errstr;

$sqlStatement->execute($grpPattern) or die $sqlStatement->errstr;

my @allGroups;

while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
	my $gid = $tuple->{'gid'};
	push @allGroups, $gid;
}


if (@allGroups) {
	foreach my $gid (@allGroups) {
		print "$gid : \n";
		if ($withUser) {
			&printMembers ($gid);
		}
		if ($withPartage) {
			printPartage($gid);
		}
	}
}
print "\n", scalar @allGroups,  " groupes trouvés\n";


sub printMembers {
	my $gid = shift;
	our $sqlMemberStatement;
	unless ($sqlMemberStatement) {
		my $sqlMembre = "select u.uid, u.displayname, g.gid from oc_users u , oc_group_user g where g.gid = ? and g.uid = u.uid ";
		$sqlMemberStatement = $sql->prepare($sqlMembre) or die $sql->errstr;
	}
	
	$sqlMemberStatement->execute($gid) or die $sqlMemberStatement->errstr;
	while (my $tuple =  $sqlMemberStatement->fetchrow_hashref()) {
		print "\t\t$tuple->{'uid'} $tuple->{displayname}\n";
	}
}

sub printPartage {
	my $gid = shift;
	our $sqlPartageStatment;
	unless ($sqlPartageStatment) {
		my $sqlQuery = "select uid_owner, file_source, file_target, item_type, permissions from oc_share  where share_with = ? order by file_target, file_source";
		$sqlPartageStatment = $sql->prepare($sqlQuery) or die $sql->errstr;
	}
	$sqlPartageStatment->execute($gid) or die $sqlStatement->errstr;
	
	while (my $tuple =  $sqlPartageStatment->fetchrow_hashref()) {
		my $fileName = $tuple->{'file_target'};
		my $fileId = $tuple->{'file_source'};
		my $uidOwner = $tuple->{'uid_owner'};
		my $type = $tuple->{'item_type'};
		my $perm = &permissionDecode($tuple->{'permissions'});
		print "\t$fileId : $type $fileName <- $uidOwner $perm\n";
	}
}
sub permissionDecode {
	my $perm = shift;
	my $flags = "($perm";
	
	if ($perm < 0) {
		return  "(permission possible:  Modification Création Supression Repartage)";
	}
	if ($perm & 2 ) {
		$flags .= ' Mo'; # Modification
	}
	if ($perm & 4 ) {
		$flags .= ' Cr'; # création
	} 
	if ($perm & 8 ) {
		$flags .= ' Su'; # Supression
	}
	if ($perm & 16 ) {
		$flags .= ' Re'; # Repartage
	}
	return $flags . ')';
}
