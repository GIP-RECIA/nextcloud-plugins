#!/usr/bin/perl
# script qui vide les groupes des comptes desactivés 
#

=encoding utf8

=head1 NAME cleanGroup.pl
	Supprime les groupes des comptes NC désactive .

=head1 SYNOPSIS userInfo.pl  [test | all ]
avec
	all : supprime des groupes  tous les comptes désactivé dont l'uid est du type F.......
	test : affiche les action sans les faire. 
=cut

use strict;
use utf8;
use DBI();
use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;
binmode STDOUT, ':encoding(UTF-8)';


BEGIN { $Pod::Usage::Formatter = 'Pod::Text::Termcap'; }
use Pod::Usage qw(pod2usage);
my $delGroupCommande= "/usr/bin/php occ group:removeuser '%s' '%s'";

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



$_ = shift;
	if (/^test$/i) {
		$test = 1;
	} elsif (/all/i) {
		$all = 1;
	} else {
		&erreurParam;
	}
if (@ARGV) {
	&erreurParam;
}

chdir $wwwRep;

my @allUids;

my $sql = connectSql();
#on cherche les comptes désactivés
my $sqlQuery = "select gid, uid from oc_group_user, oc_preferences where uid=userid and appid = 'core' and configkey = 'enabled' and configvalue = false" ;
my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
$sqlStatement->execute() or die $sqlStatement->errstr;
while (my @tuple =  $sqlStatement->fetchrow_array) {
	my $commande = sprintf($delGroupCommande , @tuple) ;
	print (join ("\t" , @tuple), "\n");
	if ($test) {
		print STDERR $commande, "\n";
	} else {
		system ($commande ) == 0 or die $!;
	}
}

# on delete les 
$sqlQuery = "delete from oc_asso_uai_user_group where exists (select * from oc_preferences where  user_group =userid and appid = 'core' and configkey = 'enabled' and configvalue = false)";
my $nb =$sql->do($sqlQuery) or die $!;
print "$nb lignes supprimé dans oc_asso_uai_user_group \n";


#select * from oc_group_user where uid =  'F22102o7';
#select * from oc_asso_uai_user_group where user_group = 'F22102o7';

#select * from oc_preferences where userid = 'F22102o7';

#select * from oc_preferences where appid = 'core' and configkey = 'enabled' and configvalue = false
