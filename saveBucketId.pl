#!/usr/bin/perl

=encoding utf8


=pod

Script qui permet de sauvegarder la liste des buckets utilisés associés aux uid. 

Il faut créer la table avant utilisation:

=cut

=pod

	create table recia_bucket_history (
		bucket varchar(128) ,
		uid varchar(64),
		creation date,
		suppression date,
		primary key (bucket, uid)
	)

=cut

use strict;
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
use DBI();
# les 2 use suivant permette de trouver les libraries installées
#  dans le meme path que l'executable
use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;



my @date = localtime time;

my $date = sprintf ("%4d-%.2d-%.2d", $date[5]+1900, $date[4]+1, $date[3]);

my %history;

my $sql = connectSql();


# insertion d'un bucket dans l'historique. 
my $sqlInsert = "insert into recia_bucket_history (bucket, uid, creation) values (?, ?, ?)";

# donne les buckets déjà dans l'historique.
my $sqlQueryOld = "select bucket, uid  from recia_bucket_history";

# donne les buckets déclarés dans Nextcloud.
my $sqlQueryExist = "select userid uid, configvalue bucket  from oc_preferences where configkey = 'bucket'";

# Donne le nombre de compte déclarés.
my $sqlQueryUidNumber = "select count(uid) from oc_users";

my $sqlStatement = $sql->prepare($sqlQueryOld) or die $sql->errstr;
$sqlStatement->execute() or die $sqlStatement->errstr;

my $nbUid = 0;

while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
	my $bucket = $tuple->{'bucket'};
	my $uid = $tuple->{'uid'};
	$history{$bucket} .= " $uid ";
	
}

my $nbBucketOld =  scalar keys %history;

print "Nb Bucket présents : $nbBucketOld\n";

$sqlStatement = $sql->prepare($sqlQueryExist) or die $sql->errstr;
$sqlStatement->execute() or die $sqlStatement->errstr;

while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
	my $bucket = $tuple->{'bucket'};
	my $uid = $tuple->{'uid'};
	$nbUid++;
	
	my $uids = $history{$bucket};
	if (!$uids || $uids !~ /\s$uid\s/) {
		&insert($bucket, $uid);
		$history{$bucket} .= " $uid ";
	} 
}


my ($nbCount)= $sql->selectrow_array($sqlQueryUidNumber) or die $sql->errstr;

my $nbBucket =  scalar keys %history;
print "Nb Bucket ajouté : ", $nbBucket - $nbBucketOld, "\n";
print "Soit $nbBucket buckets pour $nbUid uids sur $nbCount comptes; total buckets y comprit avatar : ", $nbBucket + $nbUid,  "\n";



sub insert {
	my $bucket = shift;
	my $uid = shift;
	my $sth = $sql->prepare($sqlInsert);
	
	$sth->execute($bucket, $uid, $date) or die $DBI::errstr . $DBI::error;
	$sth->finish();
}

