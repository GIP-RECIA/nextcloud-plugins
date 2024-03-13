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
if  (@ARGV) {
	my $fid = shift;
	§ERROR "$fid n'est pas un id de groupFolders" unless ($fid =~ /^\d+$/);
	 my $folder = $$folderById{$fid};

	§ERROR "$fid n'existe pas en base" unless $folder;
	diffGf($fid, $folder);
	 
} else {
	while (my ($fid, $folder) = each %{$folderById}) {
		diffGf ($fid, $folder);
	}
}

sub diffGf {
	my ($fid, $folder) = @_;
	my ($notInBase, $notInDisque) = $folder->diffBaseDisque();

	if (@{$notInBase}) {
		print "\nPath on __groupefolders but not in base :\n";
		for (@{$notInBase}) {
			print "'$_'\n";
			§DEBUG  "'$_'", "not in base";
		};
	}
	if (@{$notInDisque}) {
		print "\nPath not on __groupefolders but in base :\n";
		for (@{$notInDisque}) {
				print "'$_'\n";
				§DEBUG  "'$_'", "not in disque";
		};
	}
}
