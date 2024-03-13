#!/usr/bin/perl

=encoding utf8

=head1 NAME infoGF.pl
	Donne des info sur les GroupFolders

=head1 VERSION 0.0 

=head1 SYNOPSIS

	infoGF.pl [-r] [-a] [-l loglevel] [gfid]

	gfid: groupFolder id
	-r : résume les listes de resultats (par défaut si pas de gfid)
	-a : ne résume pas les listes par défaut si gfid not null.
	-l : fixe le log level
  
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
use List::Util qw(reduce);
use util;
use Folder;

my $resume;
my $all;
my $loglevel = 2;

unless (@ARGV && GetOptions ( "r" => \$resume, "a" => \$all, "l=i" => \$loglevel) ) {
	my $myself = $FindBin::Bin . "/" . $FindBin::Script ;
	#$ENV{'MANPAGER'}='cat';
	pod2usage( -message =>"ERROR:	manque d'arguments", -verbose => 1, -exitval => 1 , -input => $myself, -noperldoc => 1 );
}


my $folderById = Folder->readNC;

MyLogger->level($loglevel);
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
		print "\nPath not in base :\n";
		resumeList($notInBase, $resume);
	}
	if (@{$notInDisque}) {
		print "\nPath not in filesystem :\n";
		resumeList($notInDisque, $resume);
	}
}

sub resumeList {
	my $ary = shift;
	my $filtre = shift;
	if ($filtre) {
		my $last = '$';
		for (grep /^$last/ ? 0 : ($last = $_), @{$ary}) {
			print "'$_'\n";
		}
	} else {
		for (@{$ary}) {
			print "'$_'\n";
		}
	}
}
