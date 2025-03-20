#!/usr/bin/perl
# supprime les groupes vide dans NC
# en tenant comptes des comptes désactivés (on supprime le groupe si il ne contient que des desactivés)

use strict;
use utf8;
use DBI();
binmode STDOUT, ':encoding(UTF-8)';
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

unless ($ARGV[0] eq 'all') {
	if  ($ARGV[0] eq 'LDAP' ) {
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


# requete de mise a jour de recia_group_history
# fixe la datFin si elle n'y est pas deja et si le groupe n'a pas de membre non obsolète
# met datFin à null si elle n'y est pas déjà et le groupe a des membre non obsolète 
my $sqlQuery = q/
	update  recia_group_history rgh,
	(
	select g.gid gid1, u.gid gid2
	from  oc_groups g left join (
		  select u.gid
		  from  oc_group_user u, oc_recia_user_history h
		  where h.uid = u.uid
		  and h.isdel < 2
		) u on u.gid = g.gid
	group by g.gid, u.gid
	) gu
	set datFin = if (datFin is null, now(),  null)
	where gid = gid1
	and (datFin is null or gid2 is not null)
	and (datFin is not null or gid2 is null)
/;

print "update recia_group_history\n";
$sql->do($sqlQuery) or die $sql->errstr;

print "ok\n";
# 
# recupère les groupes à supprimer ceux dont datFin > 10
$sqlQuery = q/	select gid
				from recia_group_history
				where datediff(now() , datFin )> 10
			/;
 
print "suppression des vieux groupes vides\n";
my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
$sqlStatement->execute() or die $sqlStatement->errstr;

my $deleteStatement = $sql->prepare(q/delete from recia_group_history where gid = ?/);

my $cpt = 0;
while (my ($gid ) =  $sqlStatement->fetchrow_array) {
	next if ($groupSuffix and rindex($gid, $groupSuffix) < 0 );
	unless ($gid eq 'admin') { 
#		print "$commande '$gid' \n";
		system ("$commande '$gid'") == 0 or die "$!\n";
		$cpt++;
		$deleteStatement->execute($gid);
	}
}
print " Nombre de groupe supprimés = $cpt\n";


# insert les nouveaux groupes dans l'historique
print "insert nouveaux groupes dans recia_group_history\n";
$sqlQuery = q/	insert IGNORE
				into recia_group_history (gid, datDebut, datFin)
				select gid, now(), null
				from oc_groups
				where gid like ?
			/;
$sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
$sqlStatement->execute('%' . $groupSuffix) or die $sqlStatement->errstr;

print "ok\n";
