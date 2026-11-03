#!/usr/bin/perl
# script qui vide les groupes des comptes desactivés 
#

=encoding utf8

=head1 NAME cleanGroup.pl
	Supprime les groupes des comptes NC désactivés .

=head1 SYNOPSIS userInfo.pl  [test] [all | uai]
avec
	all : supprime des groupes  tous les comptes désactivé dont l'uid est du type F.......
	test : affiche les actions sans les faire.
	uai : uai de l'établissement à traiter
=cut

use strict;
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

use DBI();
use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use lib $FindBin::Bin . "/GroupFolder";
use MyLogger ; # 'DEBUG';
use ncUtil;

BEGIN { $Pod::Usage::Formatter = 'Pod::Text::Termcap'; }
use Pod::Usage qw(pod2usage);
my $delGroupCommande= "/usr/bin/php occ group:removeuser '%s' '%s'";

MyLogger->level(3);

my $test = 0;
my $all = 0;
my @uids;
sub erreurParam {
	my $myself = $FindBin::Bin . "/" . $FindBin::Script ;
	$ENV{'MANPAGER'} = 'cat';
	pod2usage(-verbose => 3, -exitval => 1 , -input => $myself, -noperldoc => 0);
}
unless (@ARGV) {
	&erreurParam;
}
my $logRep = $PARAM{'NC_LOG'} . "/Loader";
my $wwwRep = $PARAM{'NC_WWW'};

my $uai;

$_ = shift;
if (/^test$/i) {
	$test = 1;
	$_=shift;
}
if ($_) {
	if (/^all$/i) {
		$all = 1;
	} elsif (/^0\d{6}\D$/) {
		$uai = $_;
	} else {
		&erreurParam;
	}
} else {
	&erreurParam unless $test;
}

if (@ARGV) {
	&erreurParam;
}

chdir $wwwRep;

my @allUids;
my $cpt = 0;
my $sql = connectSql();
#on ne desactive plus les comptes qui font des partages
#on cherche les comptes qui sont supprimés du LDAP:
my $sqlQuery;
if ($uai) {
	$sqlQuery = q/select gid, g.uid
				from oc_group_user g, oc_recia_user_history r
				where g.uid=r.uid
				and r.isDel > 1
				and gid like '%$uai'/;
} else {
	$sqlQuery = q/select gid, g.uid
				from oc_group_user g, oc_recia_user_history r
				where g.uid=r.uid
				and r.isDel > 1
				limit 20000/;
}


my $sqlStatement = $sql->prepare($sqlQuery) or §FATAL $sql->errstr;
$sqlStatement->execute() or §FATAL $sqlStatement->errstr;

while (my @tuple =  $sqlStatement->fetchrow_array) {
	my $commande = sprintf($delGroupCommande , @tuple) ;

	if ($test) {
		§PRINT $commande;
	} else {
		§SYSTEM $commande ;
		§INFO  join ("\t" , @tuple), " was removed";
	}

	$cpt++;
}

print "$cpt group user supprimés\n";
# on delete les tuples de oc_asso_uai_user_group inutiles

my @sqlQueries = ("delete from oc_asso_uai_user_group where exists (select * from oc_recia_user_history where  user_group =uid  and isDel > 1)",
			"delete from oc_asso_uai_user_group a where user_group not in (select gid from oc_groups where gid is not null) and user_group not in (select uid from oc_users where uid is not null)");

if ($all) {
	my $nb = 0;
	foreach $sqlQuery (@sqlQueries) {
		#piège : on ne peut pas faire la somme sur la même ligne car il faut differencié le '0E0' qui vaut 0 ou true, du '0' qui vaut 0 ou false;
		my $res =  $sql->do($sqlQuery) or §FATAL  $sql->errstr, " $sqlQuery";
		$nb += $res;
	}
	print "$nb lignes supprimées dans oc_asso_uai_user_group\n";
}

__END__







