#!/usr/bin/perl

=encoding utf8

=head1 NAME userInfo.pl
	Donne les infos utiles d'un compte Nextcloud .

=head1 SYNOPSIS userInfo.pl [ -a | -b [-m] | -f | -p ] [ uid | displayname | bucket | fileId ]
avec
	-a : toutes les infos
	-b : affiche les buckets du compte
	-m : affiche seulement les fichiers dans le bucket manquant  dans la base (va avec -b)
	-f : les fichiers du compte
	-p : les partages du compte
	uid : uid du compte
	displayname : Nom complet de la personne peut contenir de % pour chercher avec like sql
	bucket : bucket lié au compte recherché
	fileId : recherche du compte propriétaire du fichier corespondant a l'fileId 
=cut

use strict;
use utf8;
use DBI();
# les 2 use suivant permette de trouver les libraries installées
#  dans le meme path que l'executable
use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;
binmode STDOUT, ':encoding(UTF-8)';
use Getopt::Long;
Getopt::Long::Configure ("bundling"); #permet les abréviations

BEGIN { $Pod::Usage::Formatter = 'Pod::Text::Termcap'; }
use Pod::Usage qw(pod2usage);

my $s3lsFormat = "/usr/bin/s3cmd ls %s";

my $reportCommande = "/usr/bin/php occ usage-report:generate ";

my $defautBucket = $PARAM{'bucket'};
my $prefixBucket = "s3://$defautBucket";


my $bucket;
my $uid;

my $bucket = 0;
my $file = 0;
my $partage = 0;
my $all;
my $manquantSeulement = 0;

unless (@ARGV and GetOptions ( "a" => \$all, "b" =>  \$bucket, "m" => \$manquantSeulement,  "f" => \$file, "p" => \$partage)) {
	my $myself = $FindBin::Bin . "/" . $FindBin::Script ;
	$ENV{'MANPAGER'} = 'cat';
	pod2usage(-verbose => 3, -exitval => 1 , -input => $myself, -noperldoc => 0);
}

if ($all) {
	$bucket = 1;
	$file = 1;
	$partage = 1;
}


my $arg1 = shift @ARGV;

unless ($defautBucket) {
	$bucket = 0;
}

my $info = $all || !( $bucket || $file || $partage );



if ($defautBucket && $arg1 =~ /^$defautBucket/){
	# on passe un bucket il faut trouver a qui il est 
	$bucket = $arg1;
	$uid = getUidByBucket($bucket);
} elsif ($arg1 =~ /^\d+$/) {
	# si on a un fichier on chercher a qui il appartient.
	$uid = getOwnerUid($arg1);
} elsif ($arg1 =~/^F\d{2}\w{5}$/) {
    $uid = $arg1;
} else {
	$uid = getUidByName($arg1);
}


if ($uid) {
	print "UID = $uid\n" if $info; 
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
sub getUidByName {
	my $name = shift;
	my $sql = connectSql();
	my $sqlQuery= "select uid, displayname from oc_users where lower(displayname) like lower(?)";
	my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	my $nbUid = $sqlStatement->execute($name)  or die $sqlStatement->errstr;
	my $ary_ref;
	if ($nbUid != 1) {
		while ($ary_ref =  $sqlStatement->fetch) {
			print "uid trouvé $$ary_ref[0] $$ary_ref[1]\n";
		}
		return 0;
	} 
	my $ary_ref =  $sqlStatement->fetch;
	if ($ary_ref) {
		return $$ary_ref[0];
	}
	return 0;
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



my @share_type = qw(user group usergroup link email contact remote circle gues remote_group room userroom deck deck_user);

my @share_status = qw(pending accepted rejected);



sub printPartage {
	
	my $uid = shift;
	my $sql = connectSql();
	
	my $lastFile;
	my $lastType;
	my $cpt;
	
	my $sqlQuery = "select share_type , share_with, file_source, path , permissions, token  from recia_share where uid_owner = ? order by path, share_type";
	my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	
	$sqlStatement->execute($uid) or die $sqlStatement->errstr;
	
	print "\n\nLes partages de l'utilisateur " . &partagePermission(-1) . ":\n";
	while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
		my $fileName = $tuple->{'path'};
		my $fileId = $tuple->{'file_source'};
		my $uidTarget = $tuple->{'share_with'};
		my $type = $tuple->{'share_type'};
		my $token = $tuple->{'token'};
		$uidTarget .= &partagePermission( $tuple->{'permissions'});
		if ($lastFile ne $fileId ) {
			$lastFile = $fileId;
			 print "\n $fileId : $fileName";
			 $cpt = 0;
			 $lastType = '';
		}
		if ($lastType ne $type) {
			print "\n\t". $share_type[$type]. ' -->' ;
			$cpt = 0;
			$lastType = $type;
		}
		if ($cpt++ % 5) {
			print ", $token\t$uidTarget";
		} else {
			print "\n\t$token\t$uidTarget";
		}
	}
	print "\n\n";
	
	$sqlQuery = "select share_type, uid_owner, file_source, path, permissions from recia_share  where share_with = ? order by path, share_type";
	$sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	$sqlStatement->execute($uid) or die $sqlStatement->errstr;
	
	while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
		my $fileName = $tuple->{'path'};
		my $fileId = $tuple->{'file_source'};
		my $uidOwner = $tuple->{'uid_owner'};
		my $type = $tuple->{'share_type'};
		$type = $share_type[$type];
		my $perm = &partagePermission($tuple->{'permissions'});
		print "$fileId \t: $fileName\n\t$type <-- $uidOwner $perm\n";
	}
	print "\n";
}



my $nom = getUserName($uid);
if ($nom) {
	print "Nom = $nom\n" if $info ;
} else {
	die "pas de compte pour $uid\n";
}

if ($info) {
	print "Les groupes Nextcloud : \n";
	foreach my $group (&getNexcloudGroups($uid)) {
		print "\t $group\n";
	}
}


if ($bucket) {
	my $bucketId = getBucket($uid);
	if ($bucketId) {
		getNextcloudFiles($uid);

		print "lecture du bucket \n";
		open S3 , &duCommande($bucketId) . "|"  || die "$!";
		while (<S3>) {
			print;
			if (/(\d+)/) {
				print " soit: " . &toGiga($1). "\n";
			}
		}
		close S3;
		open S3 , &lsCommande($bucketId) . "|"  || die "$!";
		
		print "Fichier dans le bucket manquants dans la base :\n" if $manquantSeulement;
		while (<S3>) {
			chop;
			unless ($manquantSeulement) {
				print;
			}
			if (/urn:oid:(\d+)$/) {
				my $fileId = $1;
				my $path = $allFiles{$fileId};
				if ($path) {
					print "\t$path" unless $manquantSeulement;
					delete $allFiles{$fileId};
				} else {
					print $_, "\n" if $manquantSeulement;
				}
			}
			print "\n" unless $manquantSeulement;
		}
		close S3;
		print "\nFichier Nextcloud hors bucket\n";
		while (my ($id, $path) = each (%allFiles)) {
			print "\t$id\t$path\n";
		} 
	} else {
		print "Pas de bucket ";
	}	
	$bucketId = $prefixBucket . "0". lc($uid);
	print "\nLecture du bucket des avatars $bucketId \n";
	open S3 , &lsCommande($bucketId) . "|"  || die "$!";
	while (<S3>) {
		print;
	}
	close S3; 
} elsif ($file) {
	getNextcloudFiles($uid);
	print "les fichiers :\n";
	while (my ($id, $path) = each (%allFiles)) {
		print "\t$id\t$path\n";
	}
}

if ($partage) {
	&printPartage($uid);
}

if ($info) {

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
