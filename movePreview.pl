#!/usr/bin/perl

=encoding utf8
Script de copie des fichiers .../preview/... du bucket 0 vers des buckets dedier : 0preview...

Il y aurra creation des buckets s'il n'existe pas.

=pod

=cut

use strict;
use utf8;
use DBI();

use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;

unless (@ARGV) {
	print STDERR  "manque d'argument\n" ;
	print STDERR  "synopsie : $0 [copy|delete|move] [all|none]\n";
	print STDERR  "           copy : copie les fichiers preview du bucket 0 dans leurs buckets dédiés , s'ils n'existent pas déjà\n";
	print STDERR  "           delete : supprime les fichiers preview du bucket 0 s'ils existent dans leurs buckets dédiés\n";
	print STDERR  "           move : déplace les fichiers preview du bucket 0 dans leurs buckets dédiés; s'ils existaient déjà supprime seulement du bucket 0. \n";
	exit 1;
}

my $job = $ARGV[0];

my $arg = $ARGV[1];


my $isFork = 0;
my $choixFile;

if ($arg) {
	if ($arg eq 'all' or $arg eq 'none') {
		$choixFile = $arg;
		$isFork = 1;
	} else {
		die "Erreur 2 eme argument doit être all ou none ! \n";
	}
}
my $instanceid = $PARAM{'instanceid'} ;

my $nbPreviewBuckets = 0;

if ($instanceid eq 'ocbzxyiyokc9') {
		# la recette
	$nbPreviewBuckets = 10;
} elsif ($instanceid eq 'ocbk2hu122fd') {
		# La prod
 	$nbPreviewBuckets = 1000;
} else {
	die "instance incorrecte \n";
}

my $isCopy;
my $isDelete;
my $isMove;

if ($job eq 'copy') {	
	$isCopy = 1;
} elsif ($job eq 'delete') {
	$isDelete = 1;
} elsif ($job eq 'move') {
	$isMove = 1 ;
} else {
	die "invalide argument \n";
}

my $prefixPath = 'appdata_'. $instanceid . '/preview/';
my $prefixNewBucket = '0preview'; 



sub oneThread {
	my $numProc = shift; #chifre de 1 ... 9 ou vide 
	my $sql = newConnectSql();
	my $sqlQuery = "select fileId , path from oc_filecache where path like '${prefixPath}${numProc}%' ";
	print "$sqlQuery\n";

	my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;

	$sqlStatement->execute() or die $sqlStatement->errstr;

	while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
		my $path = $tuple->{'path'};
		my $fileId = $tuple->{'fileId'};
		
		if ($path =~ /$prefixPath(\d+)\//) {
			
			my $idBucket = $1 % $nbPreviewBuckets; 
			
			my $newBucket= $prefixNewBucket . $idBucket;
			
			
			if ($isCopy) {			
				
				&oneCopy($newBucket, $fileId);
				
			} elsif ($isDelete) {
				&oneDelete($newBucket, $fileId);
			} elsif ($isMove) {
				&oneMove($newBucket, $fileId);
			}
		}
	}
	return 0;
}

if ($isFork) {
	for (my $numProc = 1; $numProc < 10; $numProc++) {
		if ( fork ) { 
			sleep 60;	
		} else {
			exit &oneThread($numProc);
		}
	}
} else {
	&oneThread();
}
# fin des traitements

sub oneCopy(){
	my $newBucket = shift;
	my $fileId = shift;
		# on verifie qu'il existe dans le bucket 0
	my ($oldPath, $bucketKo) =  &existS3File($fileId);
	if ($bucketKo) {
		die "Bucket 0 does not exists\n";
	}
	if ($oldPath) {
			# on verifie qu'il n'existe pas deja dans le new bucket
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

sub oneMove(){
	my $newBucket = shift;
	my $fileId = shift;
		# on verifie qu'il existe dans le bucket 0
	my ($oldPath, $bucketKo) =  &existS3File($fileId);
	if ($bucketKo) {
		die "Bucket 0 does not exists\n";
	}
	if ($oldPath) {
			# on verifie s'il existe  deja dans le new bucket
		my ($newPath, $bucketKo) =  &existS3File($fileId, $newBucket);
		if ($newPath) {
			&deleteFile($oldPath);
			print "\n";
		} else {
			$newPath = &s3path($newBucket);
			if (!$bucketKo || &createBucket($newPath)) {
				&moveFile($oldPath, $newPath);
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



sub copyFile(){
	my $oldPath = shift;
	my $newPath = shift;
	my $commande = getS3command() . " cp " . $oldPath . " " . $newPath ;
	if (&promptCommande($commande, \$choixFile)) {
		system $commande and die "$!\n";
			return 1;
	}
	return 0;
}


sub moveFile(){
	my $oldPath = shift;
	my $newPath = shift;
	my $commande = getS3command() . " mv " . $oldPath . " " . $newPath ;
	if (&promptCommande($commande, \$choixFile)) {
		system $commande and die "$!\n";
			return 1;
	}
	return 0;
}


sub deleteFile(){
	my $oldPath = shift;
	my $commande = getS3command() . " del " . $oldPath;
	if (&promptCommande($commande, \$choixFile)) {
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
