#!/usr/bin/perl
# script qui prend en entré un bucket s3 et propose la suppressions ou le deplacement  des ses  fichiers qui ne sont pas réferencés dans la base de nextcloud (oc_filecache)
# pour le deplacement il faut parametré un bucket corbeille. les fichiers d'1 octet seront effacer et pas deplacé.
# une deuxieme entre sera le nombre de jours passé a partir duquel on delete ou deplace si pas de valeuril y a une valeur par defaut dans le script 


use strict;
use utf8;
use DBI();
# les 2 use suivant permette de trouver les libraries installées
#  dans le meme path que l'executable
use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;
binmode STDOUT, ':encoding(UTF-8)';

my $s3cmd = "/usr/bin/s3cmd ";
my $s3lsFormat = "$s3cmd ls %s";
my $s3rmFormat = "$s3cmd del %s/urn:oid:%s"; 
my $s3mvFormat = "$s3cmd mv %s/urn:oid:%s  %s";


my $defautBucket = $PARAM{'bucket'};
my $prefixBucket = "s3://$defautBucket";

my $bucketCorbeille = $prefixBucket . "corbeille";

my $nbJourDefaut = 30;

unless (@ARGV) {
	print STDERR  "manque d'argument\n" ;
	print STDERR  "$0 bucket [nbJour]"; 
	print STDERR  "bucket est  le bucket dont on veut supprimer les fichiers non référencés dans Nexcloud\n";
	print STDERR   "nbJour : les fichier plus récents que ce nombre de jour ne seront pas proposés au retrait ; defaut=$nbJourDefaut.\n";
	print STDERR  " la liste des buckets peut être obtenue par la commande suivante :\n";
	print STDERR  "s3cmd ls\n";
	exit 1;
}

my $bucket = $ARGV[0];
my $nbJour = $ARGV[1];

my $forceDelete = 0;
my $display;

unless ($bucket =~ /^$prefixBucket/) {
	die "Mauvais nom de bucket : doit commencer par $prefixBucket\n";
}
if ($bucket eq $bucketCorbeille) { 
	$forceDelete = 1;
}

if ($nbJour) {
	if ($nbJour =~ /^(\d+)$/) {
		$nbJour = $1;
	} else {
		die "Le nombre de jours ($nbJour) doit être un entier positif\n";
	}
} else {
	$nbJour = $nbJourDefaut;
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

my $datLimit = &date(time - $nbJour * 24 * 3600);

my $s3commande = sprintf($s3lsFormat, $bucket);

my $globalChoix = ''; #n == none; O == all
my $cptOk; 
my $cptKo;
my $cptDel;
open S3LS, "$s3commande |" or die "$!";
while (<S3LS>) {
	if (/^(\d{4}-\d{2}-\d{2})\s+(\S+)\s+(\d+)\s+($bucket\/urn:oid:(\d+))$/) {
		my $dateFile = $1;
		my $fileName = $4;
		my $fileId = $5;
		my $fileSize = $3;
		chop;
		if (&fileIdInbase($fileId)) {
			$cptOk++;
		} else {
			$cptKo++;
			
			if (($dateFile cmp $datLimit) < 0) {
				my $choix ;
				my $rmCommande;
				if ($forceDelete || ($fileSize <= 1 )) {
					$rmCommande = sprintf $s3rmFormat, $bucket, $fileId;
					$display = " delete "; 
				} else {
					$rmCommande = sprintf $s3mvFormat, $bucket, $fileId, $bucketCorbeille;
					$display = " move ";
				}
				if ($globalChoix) {
					$choix = $globalChoix;
					print "$_; $display ";
				} else {
					print "$_; $display :  O/n/all/none ? ";
					$choix = <STDIN>;
					chomp $choix;
					if ($choix eq 'none') {
						$choix = $globalChoix = 'n';
					} elsif ($choix eq 'all') {
						$choix = $globalChoix = 'O';
					}
				}
				if ($choix eq "O") {
						print " ... ";
						system ($rmCommande) == 0 and print "ok\n" or print "KO! $?\n";
						$cptDel ++;
				} else {
					print " abort \n";
				}
			} else {
				print "$_; none : $dateFile >= $datLimit\n";
			}
			
			
		}
	}
} 
print "ok = $cptOk; ko=$cptKo ; deleted=$cptDel\n";
