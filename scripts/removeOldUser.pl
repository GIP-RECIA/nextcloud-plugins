#!/usr/bin/perl

=encoding utf8

=head1 NAME

	removeOldUser.pl
	Supprime les plus vieux comptes obsolètes 

=head1 SYNOPSIS

	removeOldUser.pl -n nbCompteASupprimer [-l loglevel]

=cut

use strict;
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

use FindBin;
use lib $FindBin::Bin;
use lib $FindBin::Bin . "/GroupFolder";
#use ncUtil;
use MyLogger 'DEBUG';
#use Filter::sh "tee " . __FILE__ . ".pl"; # pour  debuger les macros
use DBI();
use Pod::Usage qw(pod2usage);
use Getopt::Long;
use ncUtil;


my $nbRemovedUserMax;
my $nbJourDelay = 60;
my $loglevel = 4;

unless (@ARGV && GetOptions ( "n=i" => \$nbRemovedUserMax, "l=i" => \$loglevel ) ) {
	my $myself = $FindBin::Bin . "/" . $FindBin::Script ;
	#$ENV{'MANPAGER'}='cat';
	pod2usage( -message =>"ERROR:	manque d'arguments", -verbose => 1, -exitval => 1 , -input => $myself, -noperldoc => 1 );
}

if (@ARGV) {
	§FATAL "Unknow ", @ARGV;
}

if ($nbRemovedUserMax > 1000) {
	§FATAL "User Max to remove > 1000" ;
}

my $jour = ( (localtime)[3] );
my $logsFile = $FindBin::Script;

$logsFile =~ s/\.pl$/\.$jour.log/;
 $logsFile = $PARAM{'NC_LOG'} . "/" . $logsFile ;

MyLogger->file('>>' . $logsFile);

if ($loglevel) {
		MyLogger->level($loglevel, 2);
}

§INFO $FindBin::Script, " -n $nbRemovedUserMax -l $loglevel";
my $sql = connectSql;

# suppression des comptes déjà marqué à supprimer.
&deleteComptes;

# suppression des partages vers des comptes obsolètes.
&delPartage;

# marque les comptes que l'on peut supprimer. 
&markToDelete;

# suppression des partages vers des comptes obsolètes
sub delPartage {
	my $delShareRequete = q/delete from oc_share where share_with like 'F_______' and share_with in (select uid from oc_recia_user_history u where u.isDel >= 2 and datediff(now(), dat) > 60) limit ?/;

	§INFO "delete from oc_share ";
	my $sqlStatement = $sql->prepare($delShareRequete) or §FATAL $sql->errstr;

	my $nbLines = $sqlStatement->execute($nbRemovedUserMax) or §FATAL $sqlStatement->errstr;

	§INFO "\t", 0 + $nbLines, " suppressions";
}

# Marquer les comptes sans partage candidat a la suppression
sub markToDelete {
	my $shareLessRequete = q/update oc_recia_user_history set isDel = 3 where isDel = 2 and datediff(now(), dat) > 60 and uid not in (select uid_owner from recia_direct_partages where uid_owner is not null) order by dat  limit ?/;
	§INFO "update oc_recia_user_history set isDel = 3 ...";
	my $sqlStatement = $sql->prepare($shareLessRequete) or §FATAL $sql->errstr;
	my $nbLines = $sqlStatement->execute($nbRemovedUserMax) or §FATAL $sqlStatement->errstr;
	§INFO "\t", 0 + $nbLines, " mise à jours";
	§INFO "Nombre de partages restants  : ", isDelPartage(3);
}

#donne les partages des comptes en fonction de la valeurs de isDel 
sub isDelPartage {
	my $isDel = shift;
	$isDel = 3 unless $isDel;
	my $req= q/select s.share_type, s.share_with, s.uid_owner, s.item_source, s.file_target, s.expiration from oc_recia_user_history r , oc_users u, oc_share s where r.isDel = ? and r.uid = u.uid and s.uid_owner = r.uid/;
	my $sta = $sql->prepare($req) or §FATAL $sql->errstr;
	my $nb = $sta->execute($isDel) or §FATAL $sta->errstr;
	while (my @tuple =  $sta->fetchrow_array) {
		§LOG @tuple;
	}
	return 0 + $nb;
}

# Suppression des comptes marqués isDel = 3
sub deleteComptes{
	my $wwwRep = $PARAM{'NC_WWW'};
	chdir $wwwRep;
	my $nbSuppression;
	§SYSTEM "/usr/bin/php occ ldap:remove-disabled-user -vvv ", OUT => sub { $nbSuppression++ if /User\ with\ uid\ :F\w{7}\ was\ deleted/;};
	§INFO "nombre de suppressions de compte : $nbSuppression";
}

__END__

begin;
select share_with from oc_share where share_with like 'F_______' and share_with in (select uid from oc_recia_user_history u where u.isDel >= 2 and datediff(now(), dat) > 60) limit 10;
delete from oc_share where share_with like 'F_______' and share_with in (select uid from oc_recia_user_history u where u.isDel >= 2 and datediff(now(), dat) > 60) limit 10;
select share_with from oc_share where share_with like 'F_______' and share_with in (select uid from oc_recia_user_history u where u.isDel >= 2 and datediff(now(), dat) > 60) limit 10;
rollback;

select uid, dat from  oc_recia_user_history where isDel = 2 and datediff(now(), dat) > 60 and uid not in (select uid_owner from recia_direct_partages where uid_owner is not null) order by dat  limit 10;

begin;
select uid, isDel, dat from  oc_recia_user_history where isDel = 2 and datediff(now(), dat) > 60 and uid not in (select uid_owner from recia_direct_partages where uid_owner is not null) order by dat  limit 10;
update oc_recia_user_history set isDel = 3 where isDel = 2 and datediff(now(), dat) > 60 and uid not in (select uid_owner from recia_direct_partages where uid_owner is not null) order by dat  limit 10;
select uid, isDel, dat from  oc_recia_user_history where isDel >= 2 and datediff(now(), dat) > 60 and uid not in (select uid_owner from recia_direct_partages where uid_owner is not null) order by dat  limit 10;
select * from oc_recia_user_history where isDel = 3;
rollback;

requete pour voir qui va être enlevé a la  prochaine suppression 
select * from oc_recia_user_history r , oc_users u where r.isDel = 3 and r.uid = u.uid;
pour voir si il reste de partage :
select s.* from oc_recia_user_history r , oc_users u, oc_share s where r.isDel = 3 and r.uid = u.uid and s.uid_owner = r.uid;
