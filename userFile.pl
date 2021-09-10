#!/usr/bin/perl
# script qui prend en entré un uid 
# et donne toutes info nextcloud utile 

use strict;
use utf8;
use DBI();
# les 2 use suivant permette de trouver les libraries installées
#  dans le meme path que l'executable
use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;
binmode STDOUT, ':encoding(UTF-8)';

my $s3lsFormat = "/usr/bin/s3cmd ls %s";

my $reportCommande = "/usr/bin/php occ usage-report:generate ";

my $defautBucket = $PARAM{'bucket'};
my $prefixBucket = "s3://$defautBucket";


my $bucket;
my $uid;

my $noarg = 0; 
my $bucketOnly = 0;
my $bucketLess = 0;

unless (@ARGV) {
	print "usage :\t$0 [-b|+b] (uid|bucket|file)\n";
	print "\t prend en entré un uid , un bucket ou un nom de fichier\n";
	print "\t et donne la liste des fichiers correspondant au compte et d'autres infos utiles\n";
	print "\t si -b ne donne que les infos complémentaire (sans les fichiers/bucket).\n";
	print "\t si +b ne donne que les fichiers dans ou hors bucket.\n";
	exit 1;
}

if ($ARGV[$noarg] =~ /([+-])b/){
	$noarg=1;
	if ($1 eq '+') {
		$bucketOnly = 1;
	} else {
		$bucketLess = 1;
	}
}

if ($ARGV[$noarg] =~ /^$defautBucket/){
	# on passe un bucket il faut trouver a qui il est 
	$bucket = $ARGV[$noarg];
	$uid = getUidByBucket($bucket);
} elsif ($ARGV[$noarg] =~ /^\d+$/) {
	# si on a un fichier on chercher a qui il appartient.
	$uid = getOwnerUid($ARGV[$noarg]);
} else {
    $uid = $ARGV[$noarg];
}

if ($uid) {
	print "UID = $uid\n";
} else {
	die "pas de compte correspondant \n";
}
#nc-prod-c3pb36tyb5wgocok4c4k480wg
sub getOwnerUid{
	my $fileId = shift;
	my $sql = connectSql();
	
	my $uid;
	my $sqlQuery = "select s.id , f.path from oc_storages s, oc_filecache f  where f.fileid = ? and f.storage = s.numeric_id " ;
	my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	
	$sqlStatement->execute($fileId) or die $sqlStatement->errstr;
	while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
		my $storageId = $tuple->{'id'};
		my $path = $tuple->{'path'};
		print "$storageId \t $fileId : $path \n";
		if ($storageId =~ /object::user:(\w{8})$/) {
			$uid = $1;
		}
	}	
	return  $uid;
}

sub getUidByBucket{
	my $bucket = shift;
	my $sql = connectSql();
	my $sqlQuery= "select userid from oc_preferences where configvalue = ? and configkey = 'bucket'" ;
	my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	$sqlStatement->execute($bucket)  or die $sqlStatement->errstr;
	my $ary_ref =  $sqlStatement->fetch;
	unless ($ary_ref) {
		return 0;
	}	
	return $$ary_ref[0];
}

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

sub getNextcloudFiles{
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

sub permissionDecode {
	my $perm = shift;
	my $flags = "($perm";
	
	if ($perm < 0) {
		return  "(permission possible:  Modification Création Supression Repartage)";
	}
	if ($perm & 2 ) {
		$flags .= ' Mo'; # Modification
	}
	if ($perm & 4 ) {
		$flags .= ' Cr'; # création
	} 
	if ($perm & 8 ) {
		$flags .= ' Su'; # Supression
	}
	if ($perm & 16 ) {
		$flags .= ' Re'; # Repartage
	}
	return $flags . ')';
}
sub printPartage {
	my $uid = shift;
	my $sql = connectSql();
	
	my $lastFile;
	my $cpt;
	
	my $sqlQuery = "select share_with, file_source, file_target , item_type , permissions from oc_share where uid_owner = ? order by file_target, file_source";
	my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	
	$sqlStatement->execute($uid) or die $sqlStatement->errstr;
	
	print "\n\nLes partages de l'utilisateur " . &permissionDecode(-1) . ":\n";
	while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
		my $fileName = $tuple->{'file_target'};
		my $fileId = $tuple->{'file_source'};
		my $uidTarget = $tuple->{'share_with'};
		my $type = $tuple->{'item_type'};
		$uidTarget .= &permissionDecode( $tuple->{'permissions'});
		if ($lastFile ne $fileId ) {
			$lastFile = $fileId;
			 print "\n $fileId : $type  $fileName";
			 $cpt = 0;
		}
		if ($cpt++ % 5) {
			print ", $uidTarget"
		} else {
			print "\n\t-> $uidTarget"
		}
	}
	print "\n\n";
	
	$sqlQuery = "select uid_owner, file_source, file_target, item_type, permissions from oc_share  where share_with = ? order by file_target, file_source";
	$sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	$sqlStatement->execute($uid) or die $sqlStatement->errstr;
	
	while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
		my $fileName = $tuple->{'file_target'};
		my $fileId = $tuple->{'file_source'};
		my $uidOwner = $tuple->{'uid_owner'};
		my $type = $tuple->{'item_type'};
		my $perm = &permissionDecode($tuple->{'permissions'});
		print "$fileId : $type $fileName <- $uidOwner $perm\n";
	}
}


sub toGiga {
	my $val = shift;
	my $unit = shift;
	if ($val) {
		if (@_) {
			return toGiga(int($val/1024),@_) . $val % 1024 . "$unit ";
		} else {
			return $unit ? "$val$unit " : toGiga($val, ' o ', ' Ko ', ' Mo ', ' Go ', ' To '); 
		}
	}
	return $unit ? "" : " 0 o ";
}


my $nom = getUserName($uid);
if ($nom) {
	print "Nom = $nom\n";
} else {
	die "pas de compte pour $uid\n";	
}

unless ($bucketOnly) {
	print "Les groupes Nextcloud : \n";
	foreach my $group (&getNexcloudGroups($uid)) {
		print "\t $group\n";
	}
}

$bucket = getBucket($uid);

unless ($bucketLess) {
	if ($bucket) {
		getNextcloudFiles($uid);

		print "lecture du bucket \n";
		open S3 , &duCommande($bucket) . "|"  || die "$!";
		while (<S3>) {
			print;
			if (/(\d+)/) {
				print " soit: " . &toGiga($1). "\n";
			}
		}
		close S3;
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
}

unless ($bucketOnly) {
	&printPartage($uid);

	
	## on finit par executer le usage-report:
	chdir 'web';
	#'"User","Quota","Space used","Number of Files","Number of Shares","Newly created files","Downloaded/Viewed"'
	open REPORT , "$reportCommande $uid |"  || die "$!";
	while (<REPORT>) {
		chop;
		my @tab = split ',';
		if (@tab > 7) {
			print "Quota : " . &toGiga($tab[2]) . "; Utilisé : " . &toGiga($tab[3]) . "; Fichiers : " . $tab[4] . "; Partagés : " . $tab[5] . "; Récents : " .  $tab[6] . "; Visités : " .   $tab[7] . ".";
		}
	}
	close REPORT;
}
