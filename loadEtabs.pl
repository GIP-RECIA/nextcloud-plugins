#! /usr/bin/perl
use strict;
my $logRep = $ENV{'HOME'} . '/logs/nextcloud';

my $nbThread = 3;
my $delai = 60; // delai entre 2 thread en seconde

my $commande = "/usr/bin/php occ ldap:import-users-ad -vvv -d 1 " ;
$commande = "echo " .  $commande;

my @allEtab;

unless (@ARGV) {
	print STDERR "manque d'argument\n" ;
	exit 1;
}

if ($ARGV[0] eq 'all' ) {
	print "chargement de tous les établissements\n";
	@allEtab = qw(0371418R 0410899E 0180010N 0280925D 0451067R 0370051E 0370769K 0371159J 0450782F)
}



sub heure(){
	my @local = localtime(shift);
	return sprintf "%d/%02d/%02d %02d:%02d:%02d " , $local[5] + 1900,  $local[4]+1, $local[3], $local[2], $local[1], $local[0];
}

sub temps() {
	my @local = gmtime (shift);
	return sprintf "%02d:%02d:%02d " , $local[2], $local[1], $local[0];
}	

sub traitementEtab() {
	my $etab = shift;
	my $LOG;
	my $COM;
	
	print $etab , "\n";
	open $LOG , "> $logRep/$etab.log" || die $!;
	my $create = 0;
	my $update = 0;
	my $debut = time;
	
	
	print $LOG &heure($debut), $etab , "\n" || die "$!";
	open  $COM , "$commande --ldap-filter='(ESCOUAI=$etab)' |" ;
	while (<$COM>) {
		if (/ldap:create-user/) {
				$create++;
		}
		if (/ldap:update-user/) {
			$update++;
		}
		print $LOG $_;
	}
	close $COM;
	my $fin = time;
	my $nbuser = $create + $update; 
	my $duree = $fin - $debut;
	print $LOG &heure($fin), " durée=", &temps($duree ), "\n";
	if ($nbuser) {
		print $LOG " create-user=$create ", " update-user=$update ", " time by users=" , $duree / $nbuser, "\n";
	}
	close $LOG;
}

sub oneThread(){
	my @listEtab = @_;
	foreach my $etab (@listEtab) {
		&traitementEtab($etab);
	}
}

my $nbEtab = @allEtab;

my $nbEtabRestant = $nbEtab % $nbThread;
my $nbEtabByThread = ($nbEtab - $nbEtabRestant) / $nbThread;

print $nbEtabByThread, " ", $nbEtabRestant, "\n";

my $firstEtab = 0;

for (my $noThread = 0 ; $noThread < $nbThread; $noThread++) {
	my $lastEtab = $firstEtab + $nbEtabByThread-1;
	
	if ($noThread < $nbEtabRestant) {
		$lastEtab++;
	}
	print $firstEtab, " ", $lastEtab,  "\n";
	
	unless (fork ) {
		&oneThread(@allEtab[$firstEtab .. $lastEtab]);
		last;
	} 
	
	$firstEtab = $lastEtab+1;
	sleep $delai; ls
}

