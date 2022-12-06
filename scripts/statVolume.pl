#!/usr/bin/perl
# script qui fait des states de volumes utilisé par le utilisateurs
# 

use strict;
use utf8;
use DBI();
# les 2 use suivant permette de trouver les libraries installées
#  dans le meme path que l'executable
use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;
binmode STDOUT, ':encoding(UTF-8)';


my $sqlQuery = qq(select storage , sum(size) from oc_filecache where mimetype != 4 and storage != 1 group by storage);


my $sql = connectSql();


my @NbComptes;

my $unG = 1024 * 1024 * 1024;

my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
$sqlStatement->execute() or die $sqlStatement->errstr;

while (my @ary = $sqlStatement->fetchrow_array) {
	my $nbG = int(@ary[1] / $unG);
	$NbComptes[$nbG]++;

}

my $cpt=0;
for (@NbComptes) {
	print $cpt++, "\t", $_, "\n";
}
