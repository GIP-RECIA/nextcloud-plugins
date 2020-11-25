#!/usr/bin/perl
# script qui prend en entré un uid 
# et donne toutes info nexcloud utile 

use strict;
use utf8;
use DBI();
# les 2 use suivant permette de trouver les libraries installées
#  dans le meme path que l'executable
use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;

my $s3lsFormat = "/usr/bin/s3cmd ls %s";


my $defautBucket = $PARAM{'bucket'};
my $prefixBucket = "s3://$defautBucket";

my $uid = $ARGV[0];

sub getBucket{
	my $uid = shift;
	my $sql = connectSql();
	
	my $sqlQuery= "select userid, concat('s3://' , configvalue) bucket  from oc_preferences where userid = ? and configkey = 'bucket'" ;
	my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	
	$sqlStatement->execute($uid) or die $sqlStatement->errstr;
	
	my $ary_ref =  $sqlStatement->fetch;
	unless ($ary_ref) {
		return 0;
	}	
	return $$ary_ref[1];		
}

my %allFiles;

sub getUserName {
	my $uid = shift;
	my $sql = connectSql();
	
	my $sqlQuery= "select uid, displayname from oc_users where uid = ? " ;
	my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	
	$sqlStatement->execute($uid) or die $sqlStatement->errstr;
	my $ary_ref =  $sqlStatement->fetch;
	unless ($ary_ref) {
		return 0;
	}
	return  $$ary_ref[1];
}

sub getNextcloudFile{
	my $uid = shift;
	my $sql = connectSql();
	
	
	my $sqlQuery = "select f.fileid , f.path , f.mimetype, f.mimepart from oc_storages s, oc_filecache f  where s.id like ? and f.storage = s.numeric_id and f.mimetype != 4" ;
	my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	
	$sqlStatement->execute('%' . $uid) or die $sqlStatement->errstr;
	while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
		my $fileId = $tuple->{'fileid'};
		my $path = $tuple->{'path'};
		$allFiles{$fileId} = $path;
		#print "$path \n";
	}	
}

sub getNexcloudGroups{
	my $uid = shift;
	my $sql = connectSql();
	
	my $sqlQuery = "select gid from oc_group_user where uid = ?";
	my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	
	$sqlStatement->execute($uid) or die $sqlStatement->errstr;
	my @groups;
	while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
		my $group = $tuple->{'gid'};
		push @groups, $group;
	}
	return @groups;
}

my $nom = getUserName($uid);
unless ($nom) {
	die "pas de compte pour $uid\n";	
}

print "Les groupes Nextcloud : \n";
foreach my $group (&getNexcloudGroups($uid)) {
	print "\t $group\n";
}

my $bucket = getBucket($uid);

if ($bucket) {
	getNextcloudFile($uid);

	print "lecture du bucket $bucket\n";

	open S3 , &lsCommande($bucket) . "|"  || die "$!";

	while (<S3>) {
		chop;
		print ;
		if (/urn:oid:(\d+)$/) {
			my $fileId = $1;
			my $path = $allFiles{$fileId};
			if ($path) {
				print "\t$path";
				delete $allFiles{$fileId};
			}
		}
		print "\n";
	}
	close S3;
	print "\nFichier Nextcloud hors bucket\n";
	while (my ($id, $path) = each (%allFiles)) {
		print "\t$id\t$path\n";
	} 
} else {
	print "Pas de bucket ";
}	
	$bucket = $prefixBucket . "0". lc($uid);
	print "\nLecture du bucket des avatars $bucket \n";
	open S3 , &lsCommande($bucket) . "|"  || die "$!";
	while (<S3>) {
		print;
	}
	close S3;

	
