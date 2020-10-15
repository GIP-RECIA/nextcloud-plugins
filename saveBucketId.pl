#!/usr/bin/perl
# script qui permet de sauvegarder la liste des bucket utilisés associé aux uid. 


use strict;
use utf8;
use DBI();
# les 2 use suivant permette de trouver les libraries installées
#  dans le meme path que l'executable
use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;

#create table recia_bucket (
#	bucket varchar(128) primary key,
#	uid varchar(64) unique key
#)


my $sql = connectSql();

# on recupere les buckets pas encore dans recia_bucket

my $sqlQuery = "select userid uid, configvalue bucket  from oc_preferences where configkey = 'bucket' and configvalue not in (select bucket from recia_bucket)" ;	
my $sqlInsert1 = "insert into recia_bucket (bucket) values (?)";
my $sqlInsert2 = "insert into recia_bucket (bucket, uid) values (?, ? )";

my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	
$sqlStatement->execute() or die $sqlStatement->errstr;
while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
	my $bucket = $tuple->{'bucket'};
	my $uid = $tuple->{'uid'};
	my $sth;
	
	if (length($bucket) <= 12 ) {
		$sth = $sql->prepare($sqlInsert1);
		$sth->execute($bucket) or die $DBI::errstr;
	} else {
		$sth = $sql->prepare($sqlInsert2);
		$sth->execute($bucket, $uid) or die $DBI::errstr . $DBI::error;
	}
	$sth->finish();
}
