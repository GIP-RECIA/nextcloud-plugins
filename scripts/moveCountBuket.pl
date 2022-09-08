#!/usr/bin/perl

=encoding utf8


=pod

Script qui permet de deplacer les fichiers pour un compte d'un bucket à un autre. 



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
use Digest::MD5 qw(md5_hex );

my $prefixUid = $ARGV[0];

unless ($prefixUid =~ /^F\w{1,7}/) {
	print "\nPour migrer des comptes du bucket 0 vers un bucket individuel:\n";
	print "usage $0 F...\n";
	print "L'argument doit être un prefix d'uid. On migrera donc tous les comptes avec ce prefix d'uid placés dans le bucket 0 \n\n";
	exit 1;
}

my $sql = connectSql();

my $sqlQueryUidIn0 = "select userid uid from oc_preferences where configkey = 'bucket' and configvalue = 'nc-prod-0'";

my $sqlStatement = $sql->prepare($sqlQueryUidIn0) or die $sql->errstr;

$sqlStatement->execute() or die $sqlStatement->errstr;

my $occCommande = "/usr/bin/php " . $PARAM{'NC_WWW'} . "/occ ";
my $occEnable = $occCommande . "user:enable ";
my $occDisable = $occCommande . "user:disable ";

my $prefixBucket = $PARAM{'bucket'};





while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
	my $uid = $tuple->{'uid'};
	if ($uid =~ /^$prefixUid/ ) {
		print ($uid . "\n");

		if (&disableUid($uid)) {
			
			my $newBucket = &newBucket($uid);
			print STDERR "$uid;  $newBucket\n";
			my @allUidFiles = &getNextcloudFiles($uid);
			my $ResteNbFile = @allUidFiles;
			foreach my $fileId (@allUidFiles) {
				if (&oneCopy($newBucket, $fileId) ) {
					$ResteNbFile --;
				} else {
					print STDERR "ereur de copie de $fileId dans $newBucket\n";
				}
			}
			#ensuite il faut modifier le bucket dans la base
			#attention il faut ajouter le prefixe nc-prod- au newBucket
			
			unless ($ResteNbFile) {
				print STDERR "$uid change oc_preferences\n";
				$sql->do(q{update oc_preferences set configvalue = ? where userid = ? and configkey = 'bucket' and appid = 'homeobjectstore' and configvalue = 'nc-prod-0' }, undef, $prefixBucket . $newBucket, $uid) or die $sql->errstr, " $uid => $newBucket ";
			} else {
				print STDERR "$uid NbFile restant à traiter = $ResteNbFile\n";
			}
			print STDERR "activation de $uid \n";
			system($occEnable . $uid) and die "$!\n";

			unless ($ResteNbFile ) {
				foreach my $fileId (@allUidFiles) {
					&oneDelete($newBucket, $fileId);
				}
			}
		}
	}
}



######################
#
# Les procedures
#
######################

sub movecompte {
	my $oldBucket = shift;
	my $uid = shift;
	
}
sub newBucket {
	return md5_hex(shift);
}


sub getNextcloudFiles{
	my $uid = shift;
	my $sql = connectSql();
	my @allFiles;
	
	my $sqlQueryFile = "select f.fileid from oc_storages s, oc_filecache f  where s.id like ? and f.storage = s.numeric_id and f.mimetype != 4" ;
	my $sqlStatement = $sql->prepare($sqlQueryFile) or die $sql->errstr;
	
	$sqlStatement->execute('%' . $uid) or die $sqlStatement->errstr;
	while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
		my $fileId = $tuple->{'fileid'};
		push (@allFiles, $fileId);
	}
	return @allFiles;
}

sub oneCopy(){
	my $newBucket = shift;
	my $fileId = shift;
	my $ok = 0;
	my ($oldPath, $bucketKo) =  &existS3File($fileId);
	if ($bucketKo) {
		die "Bucket 0 does not exists\n";
	}
	if ($oldPath) {
		my ($newPath, $bucketKo) =  &existS3File($fileId, $newBucket);
		unless ($newPath) {
			$newPath = &s3path($newBucket);
			if (!$bucketKo || &createBucket($newPath)) {
				$ok = &copyFile($oldPath, $newPath);
			}
			print "\n";
		} 
	}
	return $ok;
}
sub oneDelete() {
	my $newBucket = shift;
	my $fileId = shift;
		# on verifie que le fichier existe dans le new bucket
	my ($newPath, $bucketKo) =  &existS3File($fileId, $newBucket);
	if ($newPath) {
		# on verifie qu'il existe dans le bucket 0
		my ($oldPath, $bucketKo) =  &existS3File($fileId);
		if ($oldPath) {
			&deleteFile($oldPath);
			print "\n";
		}
	}
}

my $choixDisableUid = '';

sub disableUid(){
	my $uid = shift;
	my $commande = $occDisable . $uid;
	if (&promptCommande($commande, \$choixDisableUid)) {
		system $commande and die "$!\n";
		return 1;
	}
	return 0;
}

my $choixBucket = '';

sub createBucket(){
		my $bucket = shift;
		my $commande = getS3command() . " mb " . $bucket;
		
		if (&promptCommande($commande, \$choixBucket)) {
			system $commande and die "$!\n";
			return 1;
		}
		return 0;
}

my $choixCopyFile;

sub copyFile(){
	my $oldPath = shift;
	my $newPath = shift;
	my $commande = getS3command() . " cp " . $oldPath . " " . $newPath ;
	if (&promptCommande($commande, \$choixCopyFile)) {
		system $commande and die "$!\n";
			return 1;
	}
	return 0;
}

my $choixDelete;

sub deleteFile(){
	my $oldPath = shift;
	my $commande = getS3command() . " del " . $oldPath;
	if (&promptCommande($commande, \$choixDelete)) {
		system $commande and die "$!\n";
		return 1;
	}
	return 0;
}
	
sub existS3File() {
		my $fileId = shift;
		my $s3path = &s3path(shift , $fileId );
		my $commande = &lsCommande($s3path);
		#print "$commande \n";
		my $ok = 0;
		open LS ,  "$commande |" or die" $!";
		
		while (<LS>) {
			chomp;
			if (/$s3path$/) {
				$ok = $s3path;
			}
		}
		close LS;
		return $ok, $?;
}
