#! /usr/bin/perl
use strict;
my $logRep = $ENV{'HOME'} . '/logs-esco/Loader';

my $nbThread = 4;
my $delai = 1; # delai entre 2 threads en secondes minimum 1

my $commande = "/usr/bin/php occ ldap:import-users-ad -vvv -d 1 " ;
#$commande = "echo " . $commande; # pour la dev

my $filterUai = "(ESCOUAI=%s)";
my $filterSiren = "(ESCOSIREN=%s)";
my $filterGroup = "(IsMemberOf=%s)";

my @allEtab;

unless (@ARGV) {
	print STDERR "manque d'argument\n" ;
	exit 1;
}
        #0180006J 0281047L 0410017W 0360019A 0451483T 0450064A 0450786K   0370024A  
        #0180006J 0281047L 0371418R 0371418R 0410017W 0360019A 0451483T 0450064A 0450786K 0370769K 0371159J 0370024A  

if ($ARGV[0] eq 'all' ) {
	print "chargement de tous les établissements\n"; #0450822X lycee fictif; 0377777U college fictif
	@allEtab = qw(0180006J 0281047L 0410017W 0360019A 0451483T 0450064A 0450786K   0370024A 
				0450782F 0371418R  0410899E 0371159J 0451067R 0180010N 0370769K 0280925D 0370051E 0450822X 0377777U)
} else {
	@allEtab = @ARGV;
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
	
	print "\n" , $etab;
	open $LOG , "> $logRep/$etab.log" || die $!;
	my $create = 0;
	my $update = 0;
	my $debut = time;
	
	my $filtre;
	print $LOG &heure($debut), $etab , "\n" || die "$!";
	if ($etab =~ /^\d{7}\w$/) {
			$filtre = $filterUai;
	} elsif ($etab =~ /^\d{14,15}$/) {
			$filtre = $filterSiren;
	} else {
		$filtre = $filterGroup;
	}
	$filtre = sprintf($filtre, $etab);
	
	open  $COM , "$commande --ldap-filter='$filtre' |" ;
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
	print $LOG &heure($fin), "\n durée=", &temps($duree );
	if ($nbuser) {
		print $LOG ", create-user=$create ", " update-user=$update ", " time by users=" , $duree / $nbuser, "\n";
	} else {
		print $LOG ", nb-user = 0 \n";
	}
	close $LOG;
	print "\n$etab $nbuser\n";
}

sub oneThread(){
	my @listEtab = @_;
	foreach my $etab (@listEtab) {
		&traitementEtab($etab);
	}
}

my $noThread = 1;
foreach my $etab (@allEtab) {
	
	unless (fork ) {
		&traitementEtab($etab);
		exit;
	} 
	
	if ( $noThread >= $nbThread) {
		wait;
	} else {
		$noThread++;
		sleep $delai;
	}
}
while (--$noThread) {
	wait;	
}

__END__

