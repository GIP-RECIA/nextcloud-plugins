#!/usr/bin/perl
# verification des comptes les plus aciennement mise a jours.
# sudo -u www-data php occ config:list "ldapimporter" | grep pass

use strict;
use utf8;
use DBI();

use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;


unless (@ARGV) {
	print STDERR  "manque d'argument\n" ;
	exit 1;
}

my $nbCompte = @ARGV[0];

##################
#
# Debut des traitements
#
##################
my $sql = connectSql();

# on cherche les infos de connexion ldap dans la base

my $sqlQuery = q(select configkey key , configvalue val from oc_appconfig where appid = "ldapimporter" and configkey like "cas_import_ad%");
 
print "$sqlQuery\n";
my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
$sqlStatement->execute() or die $sqlStatement->errstr;

while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
	my $key = $tuple->{'key'};
	my $val = $tuple->{'val'};
	
	if ($key =~ s/cas_import_ad_//){
		$ldapKey{$key} = $val;
	}
	 
	
 


