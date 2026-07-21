#!/usr/bin/perl

=encoding utf8

=head1 NAME infoGF.pl
	Donne des info sur les GroupFolders
	avec -g affiche les groupes.
	avec -r ou -a  affiche le nom puis le contenue des GF;
	en 3 categories:
		'Path in base and filesystem: ' ce qui est ok
		'Path not in filesystem: ': ce qui manque sur le disque
		'Path not in base: ' ce qui manque en base (pas possible en stockage object)

=head1 VERSION 1.0.1

=head1 SYNOPSIS

	infoGF.pl [-r] [-a] [-d tmp.file] [-l loglevel] [gfid|pattern]

	gfid: groupFolder id;
	pattern: pattern de recherche sur les points de montage des GFs.
	-g : affiche les groupes liés au GF (incompatible avec -r et -a)
	-r : calcul la difference entre le base et le S3 , résume les listes de résultats ;
	-a : calcul la difference entre le base et le S3, ne résume pas les listes;
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

my $withGroup;
my $resume;
my $all;
my $loglevel;
my $diffFileOld;
my $diffFileNew;

unless (@ARGV && GetOptions ( "d=s" => \$diffFileOld ,"r" => \$resume, "a" => \$all, "g" => \$withGroup, "l=i" => \$loglevel) ) {
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
	if ($fid =~ /^\d+$/) {
		my $folder = $$folderById{$fid};
		§FATAL "$fid n'existe pas en base" unless $folder;
		if ($resume || $all) {
			diffGf($fid, $folder);
		} else {
			printInfo($folder);
		}
	} else {
		for my $folder (sort {$a->mount cmp $b->mount} Folder->findFolders($fid)) {
			if ($resume || $all) {
				diffGf ($folder->idBase, $folder);
			} else {
				printInfo($folder);
			}
		}
	}
} else {
	#~ while (my ($fid, $folder) = each %{$folderById}) {
		#~ diffGf ($fid, $folder);
	#~ }
		# le trie permet la comparaison des résultats
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

sub printInfo {
	my $folder = shift;
	print $folder->idBase, "\t: ",  $folder->mount,  "\n";
	if ($withGroup) {
		my $groups = $folder->allGroups();
		
		for my $group (sort keys %$groups) {
			print "\t\t", $group , " : " , partagePermission($groups->{$group}), "\n";
		}
		print "\n";
	}
} 

sub diffGf {
	my ($fid, $folder) = @_;
	my ($notInBase, $notInDisque, $inBase) = $folder->diffBaseDisque();

	my $mount = $folder->mount;
	if (@{$notInBase}) {
		print "$mount:\nPath not in base :\n";
		$mount = '';
		resumeList($notInBase, $resume);
	}
	if (@{$inBase}) {
		print "$mount:\nPath in base and filesystem:\n";
		$mount='';
		resumeList($inBase, $resume);
	}
	if (@{$notInDisque}) {
		print "$mount:\nPath not in filesystem :\n";
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

sub partagePermission {
	my $perm = shift;
	my $flags = "($perm";
	
	if ($perm < 0) {
		return  "(permission possible:  Modification Création Supression Repartage)";
	}
	if ($perm & 2 ) {
		$flags .= ' Mo'; # Modification
	}
	if ($perm & 4 ) {
		$flags .= ' Cr'; # création
	} 
	if ($perm & 8 ) {
		$flags .= ' Su'; # Supression
	}
	if ($perm & 16 ) {
		$flags .= ' Re'; # Repartage
	}
	return $flags . ')';
}
