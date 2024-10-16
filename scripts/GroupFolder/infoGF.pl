#!/usr/bin/perl

=encoding utf8

=head1 NAME infoGF.pl
	Donne des info sur les GroupFolders

=head1 VERSION 1.0.1

=head1 SYNOPSIS

	infoGF.pl [-r] [-a] [-d tmp.file] [-l loglevel] [gfid|uid|TEXT]

	gfid: groupFolder id;
	-r : résume les listes de résultats (par défaut si pas de gfid);
	-a : ne résume pas les listes par défaut si gfid not null; donne aussi les groupes et permissions;
		si uid la liste de GF concernant la personne avec groupes et permissions.
		si TEXT affiche les GF contenant le TEXT  
	-d : mémorise la sortie dans tmp.file.new et ne renvoie sur stdout que les différences avec tmp.file;
		 si tmp.file n'existe pas il le crée;
	-l : fixe le log level,  1:error 2:warn 3:info 4:debug 5:trace ; par defaut est à 2.
  
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
my $loglevel;
my $diffFileOld;
my $diffFileNew;

unless (@ARGV && GetOptions ( "d=s" => \$diffFileOld ,"r" => \$resume, "a" => \$all, "l=i" => \$loglevel) ) {
	my $myself = $FindBin::Bin . "/" . $FindBin::Script ;
	#$ENV{'MANPAGER'}='cat';
	pod2usage( -message =>"ERROR:	manque d'arguments", -verbose => 1, -exitval => 1 , -input => $myself, -noperldoc => 1 );
}

if (defined $loglevel) {
	MyLogger->file($util::PARAM{'NC_LOG'}."/infoGF.log");
} else {
	$loglevel = 2;
}
MyLogger->level($loglevel);

if ($diffFileOld) {
	open $diffFileNew, ">:encoding(UTF-8)", $diffFileOld.'.new' or §FATAL $diffFileOld.'.new', $!;
	select $diffFileNew;
}
my $folderById = Folder->readNC;



if  (@ARGV) {
	my $fid = shift;
	if ($fid =~ /^F\w{7}$/) {
		# $fid est en fait un uid
		util->occ("groupfolders:list -u $fid", sub {print ;});
	} elsif ($fid =~ /^\d+/) {
		if ($all) {
			util->occ("groupfolders:list", sub {if (/^(\+|\| F|\|\s$fid)/) {print ;}} );
		}

		§ERROR "$fid n'est pas un id de groupFolders" unless ($fid =~ /^\d+$/);
		 my $folder = $$folderById{$fid};

		§ERROR "$fid n'existe pas en base" unless $folder;
		my $mount = diffGf($fid, $folder);
		if ($mount) {
			print "$mount ($fid): ok\n";
		}
	} elsif ($all) {
		util->occ("groupfolders:list", sub {if (/(^\+|^\| F|$fid)/) {print ;}} );
	}
} else {
	#~ while (my ($fid, $folder) = each %{$folderById}) {
		#~ diffGf ($fid, $folder);
	#~ }
		# le trie permet la comparaison des résultats
	if ($all) {
		util->occ("groupfolders:list", sub {print ;});
	}
	for my $fid (sort keys %{$folderById}) {
		diffGf ($fid, $$folderById{$fid});
	}

	if (defined $diffFileNew) {
		select STDOUT;
		close $diffFileNew;
		if (-e $diffFileOld) {
			#§SYSTEM "diff $diffFileOld $diffFileOld".'.new', OUT => sub {print;} ;
			system "diff $diffFileOld $diffFileOld".'.new';
		} else {
			open $diffFileNew , "<:encoding(UTF-8)", $diffFileOld.'.new' or §FATAL $diffFileOld.'.new ', $!;
			while (<$diffFileNew>) {print }; 
			rename $diffFileOld.'.new', $diffFileOld or §FATAL "mv $diffFileOld".'.new ', $diffFileOld, " ", $!;
		}
	}
}

sub diffGf {
	my ($fid, $folder) = @_;
	my ($notInBase, $notInDisque) = $folder->diffBaseDisque();

	my $mount = $folder->mount;
	if (@{$notInBase}) {
		print "$mount ($fid):\nPath not in base :\n";
		$mount = '';
		resumeList($notInBase, $resume);
	}
	if (@{$notInDisque}) {
		print "$mount ($fid):\nPath not in filesystem :\n";
		$mount = '';
		resumeList($notInDisque, $resume);
	}
	return $mount;
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
