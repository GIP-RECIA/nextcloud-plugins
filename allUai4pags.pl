#! /usr/bin/perl

my $scriptRep = $0;
$scriptRep =~ s/[^\/]+$//;

my $allEtabVide = $scriptRep . "allEtab.txt";

print "$allEtabVide \n";
open ETAB , "$allEtabVide"  or die "$!" ;

my $cpt;
my %etabEnProd;
my $passer = 0;
while (<ETAB>) {
	if (/#(NOT )?IN PAGS/) {
		$passer = $1 ;
		next;
	}
	next if $passer;
	
	if (/#NEW LINE PAGS/) {
		print "\n";
		next;
	}
	
	s/^\s*\#.*$//; 				# suppression des commentaires
	next if (/^\s*$/); 		# suivant si ligne vide
							# la ligne est du type
							# etab [; num] 
							# etab peut etre un uai, siren un nom de groupe; num est un timestamp
	if (/^\s*([^;,#]+)(([;,]\s*)(\d{0,14}))?/) {
		my $etab = $1;
		$etab =~ s/\s+$//; 	#suppression de \s en fin d'etab
		if ($etab =~ /^(\d{7}\D)$/) {
			print "($1)|";
		}
		
	}
} 
print "\n";
close ETAB or die $!;
