#!/usr/bin/perl

=encoding utf8

=head1 NAME infoGF.pl
	Donne des info sur les GroupFolders

=head1 VERSION 0.0 


=cut

use strict;
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

use FindBin;
use lib $FindBin::Bin;
use MyLogger ; # 'DEBUG';
#use Filter::sh "tee " . __FILE__ . ".pl"; # pour  debuger les macros
use DBI();
use Pod::Usage qw(pod2usage);
use Getopt::Long;

use util;
use Folder;


my $folderById = Folder->readNC;
MyLogger->level(2);
while (my ($fid, $folder) = each %{$folderById}) {
	#print $fid, "\t", $folder->mount, "\n";
	
	my ($notInBase, $notInDisque) = $folder->diffBaseDisque();

	if (@{$notInBase}) {
		print "Path on __groupefolders but not in base :\n";
		for (@{$notInBase}) {print $_."_n"};
	}
	if ((@{$notInDisque})) {
		print "Path not on __groupefolders but in base :\n";
		for (@{$notInDisque}) {print $_."_n"};
	}
}
