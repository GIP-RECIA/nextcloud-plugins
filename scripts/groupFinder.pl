#!/usr/bin/perl
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
 #"select gid from  oc_groups where gid like ?";
my $sqlGroup = q/	select g.gid, e.uai, e.siren, e.name
					from  oc_groups g
					left join oc_asso_uai_user_group a on (a.user_group = g.gid)
					left join oc_etablissements e on (a.id_etablissement = e.id)
					where g.gid like ?/;

my %uid2name;

my $sql = connectSql();

my $sqlStatement = $sql->prepare($sqlGroup) or die $sql->errstr;

$sqlStatement->execute($grpPattern) or die $sqlStatement->errstr;

my @allGroups;

while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
	my $gid = $tuple->{'gid'};
	push @allGroups, $gid;
	unless ($withUser || $withPartage) {
		my $name = $tuple->{'name'};
		if ($name) {
			my $uai = $tuple->{'uai'};
			my $siren = $tuple->{'siren'};
			print "$gid\n\t\t $name; ", $uai ? $uai : $siren, "\n\n";
		} else {
			print "$gid\n\t\t etab not in oc_asso_uai_user_group\n\n";
		}
	}
}

if ($withUser || $withPartage) {
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
}
print "\n", scalar @allGroups,  " groupes trouvés\n";


sub printMembers {
	my $gid = shift;
	our $sqlMemberStatement;
	unless ($sqlMemberStatement) {
		my $sqlMembre = "select u.uid, u.displayname, g.gid from oc_users u , oc_group_user g where g.gid = ? and g.uid = u.uid order by uid";
		$sqlMemberStatement = $sql->prepare($sqlMembre) or die $sql->errstr;
	}
	
	print "\tLes membres : ";
	
	$sqlMemberStatement->execute($gid) or die $sqlMemberStatement->errstr;
	my $cpt = 0;
	my $text ='';
	while (my $tuple =  $sqlMemberStatement->fetchrow_hashref()) {
		my $uid = $tuple->{'uid'};
		my $name = $tuple->{displayname};
		my $tab;
		
		$uid2name{$uid} = $name;
		
		unless ($cpt++ % 4) {
			$tab = "\n\t\t";
		} else {
			$tab = (" " x int((40-length($text))));
		}
		
		$text = "$uid $name";
		print "$tab$text";
	}
	print "\n";
}

sub printPartage {
	my $gid = shift;
	our $sqlPartageStatment;
	our $sqlPartagesUserStatement;
	unless ($sqlPartageStatment) {
		my $sqlQuery = "select uid_owner, file_source, path, item_type, permissions , id from recia_share  where share_with = ? and share_type = 1 order by path , uid_owner";
		$sqlPartageStatment = $sql->prepare($sqlQuery) or die $sql->errstr;
		$sqlQuery = "select share_with,  permissions, id from oc_share where file_source = ? and share_type = 2 and parent = ? order by share_with";
		$sqlPartagesUserStatement =  $sql->prepare($sqlQuery) or die $sql->errstr;
	}
	$sqlPartageStatment->execute($gid) or die $sqlStatement->errstr;
	print "\t les partages :\n" ;
	
	my $text ='';
	
	while (my $partageFile =  $sqlPartageStatment->fetchrow_hashref()) {
		my $fileName = $partageFile->{'path'};
		my $fileId = $partageFile->{'file_source'};
		my $uidOwner = $partageFile->{'uid_owner'};
		my $type = $partageFile->{'item_type'};
		my $perm = &permissionDecode($partageFile->{'permissions'});
		my $nameOwner = $uid2name{$uidOwner};
		my $partageId = $partageFile->{'id'};
		my $tab;
		
		print "\t\t$fileId : $type $fileName <-- $uidOwner $nameOwner $perm"."[$partageId] ";
		
		$sqlPartagesUserStatement->execute($fileId , $partageId) or die $sqlPartagesUserStatement->errstr; 
		my $cpt = 0;
		
		while (my $partageUser =  $sqlPartagesUserStatement->fetchrow_hashref()) {
			my $uid = $partageUser->{'share_with'};
			my $perm = &permissionDecode($partageUser->{'permissions'});
			my $name = $uid2name{$uid};
			my $partageId = $partageUser->{'id'};
			
			unless ($cpt++ % 4 ) {
				$tab = "\n\t\t--> ";
			} else {
				$tab = (" " x int((40-length($text))));
			}
			$text = "$uid $name $perm"."[$partageId] ";
			print "$tab$text";
		}
		print "\n";
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
