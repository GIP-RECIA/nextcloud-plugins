#!/usr/bin/perl
# script qui prend en entré un bucket s3 et propose la suppressions des ses  fichiers qui ne sont pas réferencés dans la base de nextcloud (oc_filecache)
use strict;
use utf8;
use DBI();
# les 2 use suivant permette de trouver les libraries installées
#  dans le meme path que l'executable
use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;

my $s3lsFormat = "/usr/bin/s3cmd ls %s";
my $s3rmFormat = "/usr/bin/s3cmd del %s/urn:oid:%s"; 









my $defautBucket = $PARAM{'bucket'};
my $prefixBucket = "s3://$defautBucket";

unless (@ARGV) {
	print STDERR  "manque d'argument\n" ;
	print STDERR  "Donner le bucket dont on veut supprimer les fichiers non référencés dans Nexcloud\n";
	print STDERR  " la liste des buckets peut être obtenue par la commande suivante :\n";
	print STDERR  "s3cmd ls\n";
	exit 1;
}

my $bucket = $ARGV[0];
my $uid = $ARGV[1];

unless ($bucket =~ /^$prefixBucket/) {
	die "Mauvais nom de bucket : doit commencer par $prefixBucket\n";
}

sub date(){
	my @local = localtime(shift);
	return sprintf "%d-%02d-%02d" , $local[5] + 1900,  $local[4]+1, $local[3];
}


sub fileIdInbase() {
	my $fileId = shift;
	my $sql = &connectSql();
	my $sqlQuery = "select storage from oc_filecache where fileid = ?";
	my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	
	$sqlStatement->execute($fileId) or die $sqlStatement->errstr;
		
	my $ary_ref =  $sqlStatement->fetch;
	unless ($ary_ref) {
		return 0;
	}	
	return $$ary_ref[0];
}

my $dateJour = &date(time);

my $s3commande = sprintf($s3lsFormat, $bucket);

my $globalChoix = ''; #n == none; O == all
my $cptOk; 
my $cptKo;
my $cptDel;
open S3LS, "$s3commande |" or die "$!";
while (<S3LS>) {
	if (/^(\d{4}-\d{2}-\d{2}).*($bucket\/urn:oid:(\d+))$/) {
		my $dateFile = $1;
		my $fileName = $2;
		my $fileId = $3;
		if (&fileIdInbase($fileId)) {
			$cptOk++;
		} else {
			$cptKo++;
			my $choix ;
			my $rmCommande = sprintf $s3rmFormat, $bucket, $fileId;
			unless ($dateFile eq $dateJour) {
				if ($globalChoix) {
					$choix = $globalChoix;
					print "$rmCommande \n";
				} else {
					print "$rmCommande  O/n/all/none ? ";
					$choix = <STDIN>;
					chomp $choix;
					if ($choix eq 'none') {
						$choix = $globalChoix = 'n';
					} elsif ($choix eq 'all') {
						$choix = $globalChoix = 'O';
					}
				}
				if ($choix eq "O") {
						system $rmCommande;
						$cptDel ++;
				} 
				
			} else {
				print "no delete $dateFile\n";
			}
			
			
		}
	}
} 
print "ok = $cptOk; ko=$cptKo ; deleted=$cptDel\n";
