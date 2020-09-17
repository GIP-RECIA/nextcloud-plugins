#! /usr/bin/perl

# script donnant la difference entre les établissements en production et ceux de la liste versionnée.
use strict;
my  $dataRep = $ENV{'NC_DATA'};

my $scriptRep = $0;
$scriptRep =~ s/[^\/]+$//;

print $scriptRep . "\n";
$dataRep = $ENV{'HOME'} . '/data' unless $dataRep;

my 	$allEtabFile = $dataRep . '/allEtab.txt';

my $allEtabVide = $scriptRep . "allEtab.txt";

print "lecture de $allEtabFile \n";
open ETAB , "$allEtabFile"  or die "$!" ;

my $cpt;
my %etabEnProd;
while (<ETAB>) {
	s/^\s*\#.*$//; 				# suppression des commentaires
	next if (/^\s*$/); 		# suivant si ligne vide
							# la ligne est du type
							# etab [; num] 
							# etab peut etre un uai, siren un nom de groupe; num est un timestamp
	if (/^\s*([^;,#]+)(([;,]\s*)(\d{0,14}))?/) {
		my $etab = $1;
		my $ts = $4;
		$etab =~ s/\s+$//; 	#suppression de \s en fin d'etab
		if ($etab) {
			if (exists $etabEnProd{$etab}) {
					print STDERR "$etab en doublon en Prod\n";
			} else {
				$etabEnProd{$etab} = $_;
				$cpt++;
			}
		}
	}
} 
close ETAB or die $!;
print "$cpt etabs en prod \n";

print "lecture  $allEtabVide \n";
open ETAB , "$allEtabVide"  or die "$allEtabFile $!" ;
my %etabList;

print "Lignes manquantes en prod : \n";
while (<ETAB>) {
		s/^\s*\#.*$//; 				# suppression des commentaires
		next if (/^\s*$/); 		# suivant si ligne vide
								# la ligne est du type
								# etab [; num] 
								# etab peut etre un uai, siren un nom de groupe; num est un timestamp
		if (/^\s*([^;,#]+)(([;,]\s*)(\d{0,14}))?/) {
			my $etab = $1;
			my $ts = $4;
			$etab =~ s/\s+$//; 	#suppression de \s en fin d'etab
			if ($etab) {
				if (exists $etabList{$etab}) {
						print STDERR "$etab en doublon dans la liste\n";
				} else {
					$etabList{$etab} = $_;
					if (exists $etabEnProd{$etab}) {
						 delete $etabEnProd{$etab};
					} else {							
						print $_;
					}
				}
			}
		}
	} 
	close ETAB or die $!;

print "Lignes supplémentaires en prod : \n";
foreach my $line (values %etabEnProd) {
	print $line;
}
