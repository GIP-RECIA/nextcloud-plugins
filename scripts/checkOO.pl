#!/usr/bin/perl
use strict;
use utf8;
use DBI();
# les 2 use suivant permette de trouver les libraries installées
#  dans le meme path que l'executable
use FindBin; 			# ou est mon executable
use lib "$FindBin::Bin/GroupFolder"; 	# chercher les lib au meme endroit
use util;
binmode STDOUT, ':encoding(UTF-8)';
package MyLogger;


my $sql = util->connectSql();

my @row_ary = $sql->selectrow_array("select configvalue from oc_appconfig where appid = 'onlyoffice' and configkey = 'settings_error'");

if (@row_ary) {
	my $erreur = $row_ary[0];
	if ($erreur) {
		print $erreur, "\n";
		util->occ("onlyoffice:documentserver --check", sub {print $_, "\n"}) ;
	}
}
