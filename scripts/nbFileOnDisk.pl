#!/usr/bin/perl
use strict;
use utf8;

=encoding utf8
 Donne le nombre de fichiers dans le repertoire DATA et le volumme occupé

=head1 SYNOPSIS

 nbFileOndisk.pl [sousRep]

 exemple : nbFileOndisk.pl F080001us
=cut

use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use lib $FindBin::Bin . "/GroupFolder";
use ncUtil;
use MyLogger;

my $dir = $PARAM{NC_DATA};

my $cpt= 0;
$dir .=  "/" . $ARGV[0];
§SYSTEM "du -sh $dir" , OUT => sub {print;} ;
§SYSTEM "find $dir -type f ", OUT => sub { $cpt++ if $_;};
print "$cpt files\n"
