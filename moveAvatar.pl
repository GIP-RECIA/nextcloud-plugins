#!/usr/bin/perl
use strict;
use utf8;
use DBI();

use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;

# recherche du path des avatars dans la base et fait la copie du bucket 0 dans le bucket aproprié.

unless (@ARGV) {
	print STDERR  "manque d'argument\n" ;
	exit 1;
}

my $job = @ARGV[0];


#while (my ($k, $v) = each %PARAM) {	
#	print "$k => $v \n";
#}
##################
#
# Debut des traitements
#
##################
my $sql = connectSql();

my $prefixPath = 'appdata_'. $PARAM{'instanceid'} . '/avatar/';

my $sqlQuery = "select fileId , path from oc_filecache where path like '${prefixPath}%' ";
print "$sqlQuery\n";
my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;

$sqlStatement->execute() or die $sqlStatement->errstr;

		
while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
	my $path = $tuple->{'path'};
	my $fileId = $tuple->{'fileId'};
	
	if ($path =~ /$prefixPath(F\w{7})\//) {
		
		my $newBucket=lc("0$1");
		
		
		if ($job eq 'copy') {			
			
			&oneCopy($newBucket, $fileId);
			
		} elsif ($job eq 'delete') {
			&oneDelete($newBucket, $fileId);
		} else {
			die "parametre inconu ! \n";
		}
	}
}
################
#
# Fin des traitements
#
################
sub oneCopy(){
	my $newBucket = shift;
	my $fileId = shift;
	
	my ($oldPath, $bucketKo) =  &existS3File($fileId);
	if ($bucketKo) {
		die "Bucket 0 does not exists\n";
	}
	if ($oldPath) {
		my ($newPath, $bucketKo) =  &existS3File($fileId, $newBucket);
		unless ($newPath) {
			$newPath = &s3path($newBucket);
			if (!$bucketKo || &createBucket($newPath)) {
				&copyFile($oldPath, $newPath);
			}
			print "\n";
		}
	}
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
