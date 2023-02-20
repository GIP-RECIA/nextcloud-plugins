#!/usr/bin/perl

=encoding utf8

=head1 NAME copyObjectToFs.pl
	Copie des fichiers du stockage Object vers un répertoire (FS)
	script en cours de dev ne pas utilisé en prod

=head1 SYNOPSIS

copyObjectToFs.pl

=cut

use strict;
use utf8;
use DBI();

use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;
binmode STDOUT, ':encoding(UTF-8)';
use Getopt::Long;
Getopt::Long::Configure ("bundling");
use Pod::Usage;

unless (@ARGV) {
	chdir $PARAM{'REP_ORG'};
	pod2usage(-verbose => 3, -exitval => 0 );
}


my $bucketQuery = qq[
    select userid, configvalue
    from oc_preferences
    where configkey = 'bucket'
    and appid = 'homeobjectstore'
];

my $filesQuery = qq[
    select st.id , fc.fileid, fc.path, fc.name , fc.mimetype
    from oc_filecache fc,
        oc_storages st
    where st.numeric_id = fc.storage
    and mimetype != 2
];

my $sql = connectSql();
my $sqlStatement = $sql->prepare($bucketQuery) or die $sql->errstr;

$sqlStatement->execute() or die $sqlStatement->errstr;

my %uid2bucket;
while (my @ary = $sqlStatement->fetchrow_array) {
	print (@ary);
	print "\n";
	$uid2bucket{$ary[0]} = $ary[1];
}

$sqlStatement = $sql->prepare($filesQuery) or die $sql->errstr;
$sqlStatement->execute() or die $sqlStatement->errstr;

=pod

on recupere pour chaque nom de fichier dans oc_filecache
le bucket ou le trouver

TODO trouver le chemin ou le déplacer et faire la copie 

=cut

while (my @ary = $sqlStatement->fetchrow_array) {
	my $bucketName = storage2BucketName($ary[0]);
	if ($bucketName) {
		print $bucketName, "\n";
	}
}

sub storage2BucketName {
	my $idBucket = shift;
	if ($idBucket =~ /object::user:([^:]+)/) {
		my $bucket = $uid2bucket{$1};
		if ($bucket) {
			return &getBucketName($bucket);
		}
	} else {
		if ($idBucket =~ /object::appdata::preview:(\d+)/ ) {
			return &getBucketName('-preview-' . $1);
		} elsif ($idBucket =~ /object::store:amazon::(nc-gip-0)/) {
			return &getBucketName($1);
		}
	}
	print STDERR "pas de bucket for $idBucket\n";
	return 0;
}
