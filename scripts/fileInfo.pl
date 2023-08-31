#!/usr/bin/perl

=encoding utf8

=head1 NAME fileInfo.pl
	Donne les infos utiles d'un fichier Nextcloud .

=head1 SYNOPSIS fileInfo.pl [ fileId | fileName ]
avec
	fileId 	: recherche du fichier par son fileId
	fileName: recherche du fichier par son nom peut contenir des % 
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

#Getopt::Long::Configure ("bundling"); #permet les abréviations

BEGIN { $Pod::Usage::Formatter = 'Pod::Text::Termcap'; }
use Pod::Usage qw(pod2usage);

my $idFile;
my $nameFile;

if (@ARGV) {
	$nameFile = shift @ARGV;
	if ($nameFile =~ /^\d+$/) {
		$idFile = $nameFile;
	}
} else {
	my $myself = $FindBin::Bin . "/" . $FindBin::Script ;
	$ENV{'MANPAGER'} = 'cat';
	pod2usage(-verbose => 3, -exitval => 1 , -input => $myself, -noperldoc => 0);
}


my $sql = connectSql();
my $sqlQuery;

if ($idFile) {
	$sqlQuery = q(
			select s.id, f.fileid , f.path , f.mimetype, f.mimepart, f.name, f.size
			from oc_storages s, oc_filecache f
			where f.fileid = ?
			and f.storage = s.numeric_id
		) ;
} else {
	$sqlQuery = q(
			select s.id, f.fileid , f.path , f.mimetype, f.mimepart, f.name, f.size
			from oc_storages s, oc_filecache f
			where f.name like ?
			and f.storage = s.numeric_id
		);
}


my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
$sqlStatement->execute($nameFile) or die $sqlStatement->errstr;

my $cpt = 0;

while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
	$cpt++;
	my $storageId = $tuple->{'id'};
	my $path = $tuple->{'path'};
	$idFile = $tuple->{'fileid'};
	my $fileName = $tuple->{'name'};
	my $size = &toGiga($tuple->{'size'});

	if ($storageId =~ /:(F\w{7})$/) {
		$storageId = $1;
	}
	print "$idFile :\t$storageId\t($size)\t$path\n";
}

if ($cpt == 1) {
	# on affiche les partages :
	#print "les partages du fichier :\n";
	print "\nLes partages ",&partagePermission(-1) , ":\n";
	$sqlQuery = q(
			select 	share_type ,
					uid_initiator,
					share_with,
					file_source,
					path ,
					permissions,
					token,
					FROM_UNIXTIME(stime) debut,
					 FROM_UNIXTIME(expiration) fin
			from recia_share
			where file_source = ?
			or item_source = ?
			order by path, share_type
		);
	$sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	$sqlStatement->execute($idFile, $idFile) or die $sqlStatement->errstr;
	while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
		my $uid_init =  $tuple->{'uid_initiator'};
		my $fileName = $tuple->{'path'};
		my $fileId = $tuple->{'file_source'};
		my $uidTarget = $tuple->{'share_with'};
		my $type = $tuple->{'share_type'};
		my $token = $tuple->{'token'};
		my $permission = &partagePermission( $tuple->{'permissions'});
		my $debut = $tuple->{'debut'};
		my $fin = $tuple->{'fin'};
		if ($token) {
			$uidTarget = $token;
		} else {
			$uidTarget .= "\t";
		}
		print "$uid_init => $uidTarget\t$permission\t($debut , $fin)\t$fileName\n";
	}
}
