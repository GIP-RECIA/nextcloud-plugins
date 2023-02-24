#!/usr/bin/perl
# supprime les groupes vide dans NC
# en tenant comptes des comptes désactivés (on supprime le groupe si il ne contient que des desactivés)

use strict;
use utf8;
use DBI();

use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;

my $logRep = $ENV{'NC_LOG'};
my  $dataRep = $ENV{'NC_DATA'};
my $wwwRep = $ENV{'NC_WWW'};

$wwwRep = $ENV{'HOME'}.'/web' unless $wwwRep ;

chdir $wwwRep;
my $commande = "/usr/bin/php occ group:delete -vvv " ;

unless (@ARGV) {
	print STDERR  "manque d'argument\n" ;
	exit 1;
}

my $groupSuffix;

unless (@ARGV[0] eq 'all') {
	if  (@ARGV[0] eq 'LDAP' ) {
		$groupSuffix = ':LDAP';
	} else {
		print STDERR  "argument illégal\n";
		exit 1;
	}
	
}

##################
#
# Debut des traitements
#
##################
my $sql = connectSql();

# 

my $sqlQuery = q/select g.gid from  oc_groups g left join (select u.gid, u.uid from  oc_group_user u, oc_recia_user_history h where h.uid = u.uid and h.isdel < 2) u on u.gid = g.gid where u.uid is null/;
 
print "$sqlQuery\n";
my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
$sqlStatement->execute() or die $sqlStatement->errstr;

my $cpt = 0;
while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
	my $gid = $tuple->{'gid'};

	next if ($groupSuffix and rindex($gid, $groupSuffix) < 0 );
	unless ($gid eq 'admin') { 
#		print "$commande '$gid' \n";
		system ("$commande '$gid'") == 0 or die "$!\n";
		$cpt++;
	}
}

print " Nombre de groupe supprimés = $cpt\n";
