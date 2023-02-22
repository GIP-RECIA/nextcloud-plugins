#! /usr/bin/perl
use strict;
use IPC::Open3;
use IO::Select;
use Symbol 'gensym';

use DBI();
# les 2 use suivant permette de trouver les libraries installées
#  dans le meme path que l'executable
use FindBin; 			# ou est mon executable
use lib $FindBin::Bin; 	# chercher les lib au meme endroit
use ncUtil;

my $logRep = $PARAM{'NC_LOG'} . "/Loader";
my  $dataRep = $PARAM{'NC_DATA'};
my $wwwRep = $PARAM{'NC_WWW'};

chdir $wwwRep;


my 	$allEtabFile = $dataRep . '/allEtab.txt';

my $nbThread = 8;
my $delai = 1; # delai entre 2 threads en secondes minimum 1

my $commande = "/usr/bin/php occ ldap:import-users-ad -vvv -d 3 " ;
my $commandeDel = "/usr/bin/php occ ldap:disable-deleted-user -vvv  ";
# $commande = "echo " . $commande; # pour la dev

my $filterUai = "(ESCOUAI=%s)";
my $filterSiren = "(ESCOSIREN=%s)";
my $filterGroup = "(IsMemberOf=%s)";
my $filterUid = "(uid=%s)";

my @allEtab;
my %etabTimestamp;
my $saveTimestamp = 0;

my %pid2etab;

my $noThread = 1;

my $debug = 0; #pour supprimer les debugs des logs

my $modifytimestamp = &timestampLdap(time);

unless (@ARGV) {
	print STDERR "manque d'argument\n" ;
	print "usage : $0 all \n\t\t recharge tout les établissements tient compte du timestamp.\n\n";
	print "\t $0 all PATTERN \n\t\t recharge les membres des groupes matchant le PATTERN ldap pour tous les etab \n\t\t le PATTERN doit contenir %UAI% (sera remplacé par tous les uais)\n\t\t Ne tient pas comptes des timestamps.\n\n";  
	print "\t $0 [UAI ...] [SIREN ...] [UID...] [GROUPE...] \n\t\trecharge que les UAI SIREN UID ou GROUPE donnés , tient compte du timestamp si prédéfinit.\n";
	exit 1;
}

unless (-d $logRep) {
	die "erreur sur le repertoire des logs : $logRep\n";
}
unless (-d $dataRep) {
	die "erreur sur le repertoire des data :  $dataRep\n";
}

        #0180006J 0281047L 0410017W 0360019A 0451483T 0450064A 0450786K   0370024A  
        #0180006J 0281047L 0371418R 0371418R 0410017W 0360019A 0451483T 0450064A 0450786K 0370769K 0371159J 0370024A  

my %etabATraiter; # ensembles des etabs a traiter pour ne pas en oublier

	# lecture du fichier contenant les timestamps;   
if (-r $allEtabFile) {
		open ETAB, $allEtabFile or die "$!" ;
		while (<ETAB>) {
			s/\#.*$//; 				# suppression des commentaires
			next if (/^\s*$/); 		# suivant si ligne vide
									# la ligne est du type
									# etab [; num] 
									# etab peut etre un uai, siren un nom de groupe; num est un timestamp
			if (/^\s*([^;,#]+)(([;,]\s*)(\d{0,14}))?/) {
				my $etab = $1;
				my $ts = $4;
				$etab =~ s/\s+$//; 	#suppression de \s en fin d'etab
				if ($etab) {
					
					if ($ts) { 		# si on a un timestamp il est normalisé à 14 chifres
						my $size = 10 ** (14 - length($ts));
						$ts = $ts * $size; 	# on complete avec des 0
						$etabTimestamp{$etab} = $ts;
						$etabATraiter{$etab} = 1;
					} else {
						# les etab sans timestamp sont placé en tete de liste pour etre traiter en premier
						# les autres seront ordonnés en fonction de leurs tailles si besoin dans le traitement du param 'all'
						push @allEtab ,$etab;
					}
				}
			}
		} 
		close ETAB or die $!;
		$saveTimestamp = 1;
} else {
	$saveTimestamp = 0;
}

if ($ARGV[0] eq 'all' ) {
	print "chargement de tous les établissements\n"; #0450822X lycee fictif; 0377777U college fictif
	unless ($saveTimestamp) {
		# si on traite tous les etab alors que l'on  pas trouvé le fichier en donnant la liste
		die "fichier non lisible $allEtabFile\n";
	}
	my $groupe = $ARGV[1] ;
	if ($groupe) {
		my @ALLGRP ;
		if ($groupe =~ /\%UAI\%/) {
			
			foreach my $uai (keys %etabATraiter) {
				if ($uai =~ /^\d{7}\w$/) {
					my $newGroup = $groupe;
					$newGroup =~ s/\%UAI\%/$uai/g;
					push @ALLGRP , $newGroup;
					print "filtre : $newGroup\n";
				}
			}
		}
		if (@ALLGRP) {
			@allEtab = @ALLGRP;
			$saveTimestamp = 0;
		} else {
			die "l'association groupe etab a produit une liste vide \n";
		}
	} else { # on doit mettre les etabs avec timestamp dans @allEtab par ordre de taille décroissante.
		my $sql = connectSql();
		my $sqlQuery = q/select uai, siren  from  recia_etab_par_taille/;
		print "$sqlQuery\n";
		my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
		$sqlStatement->execute() or die $sqlStatement->errstr;
		my $cpt = 0;
		while (my $tuple =  $sqlStatement->fetchrow_hashref()) {
			my $uai = $tuple->{'uai'};
			my $siren = $tuple->{'siren'};
			if ($uai) {
				if (delete $etabATraiter{$uai}) {
					push @allEtab , $uai;
				} elsif (delete $etabATraiter{$siren}) {
					push @allEtab , $siren;
				}
			} else {
				if (delete $etabATraiter{$siren}) {
					push @allEtab , $siren;
				}
			}
		}
		# on complete avec ceux restant a traiter;
		push @allEtab , keys %etabATraiter;
	}
} else {
		# traitement que d'un etab ou un groupe si on a pas son timestamp on traite entierement
	@allEtab = @ARGV;
	$debug = 1; # on passe en mode debug
}


sub dateHeure(){
	my @local = localtime(shift);
	return sprintf "%d/%02d/%02d %02d:%02d:%02d " , $local[5] + 1900,  $local[4]+1, $local[3], $local[2], $local[1], $local[0];
}

sub heure(){
	my @local = localtime(shift);
	return sprintf "%02d:%02d:%02d " , $local[2], $local[1], $local[0];
}

sub temps() {
	my @local = gmtime (shift);
	return sprintf "%02d:%02d:%02d " , $local[2], $local[1], $local[0];
}	

sub timestampLdap() {
		# calcul du timestamp courant donné a la minute
	my @local = gmtime (shift);
	return sprintf "%d%02d%02d%02d%02d00 " , $local[5] + 1900,  $local[4]+1, $local[3], $local[2], $local[1];
}	


sub executeWithLogFilter {
	my $commande= shift;
	my $etab = shift;
	my $LOG = shift;
	my @regexes = @_;
	
	my $COM;
	my $ERR = gensym;
	
	my @res;
	
	
	my $select = IO::Select->new();
	
	print $LOG "$commande \n"; 
		
		# voir avec open3 et IO::Select pour filtrer les erreurs 
	open3(undef,  $COM , $ERR, $commande );
	
	$select->add($ERR);
	
	while (<$COM>) {
		for (my $i=0; $i < @regexes; $i++){
			if (/$regexes[$i]/) {
				$res[$i]++;
			}
		}
		
		if ($select->can_read(0)) {
			my $err = <$ERR>;
			chop $err;
			if ($err) {
				print STDERR &heure(time), " $etab ", $err;
			} 
			print STDERR "\n";
			
		}
		if ($debug) {
			print $LOG $_;
		} else { 
			unless (/^\[debug\]/) {
				print $LOG $_;
			}
		}
	}
	if ($select->can_read(0)) {
		while (<$ERR>) {
			print STDERR &heure(time), " $etab ", $_;
		}
	}
	close $ERR;
	close $COM;
	return @res;
}


sub traitementEtab() {
	my $etab = shift;
	my $timeStamp = shift;
	my $LOG;
	
	
	
	my $debut = time;
	print "\n" , &heure($debut), " $etab \n";
	
	my $logFileName = "$logRep/$etab.log";
	open $LOG , "> $logFileName" or die $!;
	
	my $filtre;
	my $typeKey;
	
	print $LOG &dateHeure($debut), $etab , "\n" or die "$!";
	if ($etab =~ /^\d{7}\w$/) {
			$filtre = $filterUai;
			$typeKey = "uai";
	} elsif ($etab =~ /^\d{14,15}$/) {
			$filtre = $filterSiren;
			$typeKey = "siren";
	} elsif ($etab =~ /^F\w{7}$/) {
		$filtre = $filterUid;
		$typeKey = "users";   
	} elsif ($etab eq 'HORS_ETAB') {
		$filtre = '';
	} else {
		$filtre = $filterGroup;
		# ici $etab peut etre un nom de groupe (contenant des ()) on les vire.
		$etab =~ s/\(/\\28/g;
		 $etab =~ s/\)/\\29/g;
	}
	my $disable = 0;
	my $create = 0;
	my $update = 0;
	
	if ($filtre) {
		$filtre = sprintf($filtre, $etab);
		if ($timeStamp) {
			$filtre = sprintf( "(&%s(modifytimestamp>=%sZ))", $filtre, $timeStamp);
		}
		($create, $update) = &executeWithLogFilter("$commande --ldap-filter='$filtre'", $etab, $LOG, qr/ldap:create-user/, qr/ldap:update-user/);
	}
	
	if ($typeKey) { # Desctivation des comptes supprimés:
		($disable) = &executeWithLogFilter("$commandeDel --$typeKey $etab", $etab, $LOG, qr/ldap:disable-user/);
	} else { 
		unless ($filtre) {
			# on est dans le cas HORS_ETAB
			($disable) = &executeWithLogFilter("$commandeDel", $etab, $LOG, qr/ldap:disable-user/);
		}
	}
	my $fin = time;
	my $nbuser = $create + $update; 
	my $duree = $fin - $debut;
	print $LOG &dateHeure($fin), "\n durée=", &temps($duree );
	if ($nbuser) {
		print $LOG ", create-user=$create ", " update-user=$update ", "disable-user=$disable ", " time by users=" , $duree / $nbuser, "\n";
	} else {
		print $LOG ", disable-user=$disable ","nb-user = 0 \n";
	}
	close $LOG;
	system "/bin/gzip -f $logFileName" unless ($debug) ;
	print "\n", &heure(time), " $etab $nbuser",  $disable ? " - $disable\n" : "\n";
	
	return $nbuser ? 0 : 1;
}

sub oneThread(){
	my @listEtab = @_;
	foreach my $etab (@listEtab) {
		&traitementEtab($etab);
	}
}

sub updateTimeStamp() {
	my $pid= shift;
	my $resultOk = shift;
	if ($pid > 0) {
		#print "\ndebug $pid \t";
		unless ($resultOk) {
			#print  " ok \n";
			my $etab = $pid2etab{$pid} ;
			$etabTimestamp{$etab} = $modifytimestamp;
		} 
	}
	return $pid;
}

#my %etab2pid;


foreach my $etab (@allEtab) {
	my $pid;
	my $etabTS = $etabTimestamp{$etab};
	if ( $pid = fork ) { 
		$pid2etab{$pid} = $etab;
	} else {
		exit &traitementEtab($etab, $etabTS);
	} 
	
	if ( $noThread >= $nbThread) {
		$pid = wait;
		
		&updateTimeStamp($pid, $? );
	} else {
		$noThread++;
		sleep $delai;
	}
}

while () {
	my $pid = wait;
	last unless &updateTimeStamp($pid, $?) > 0;
}

if ($saveTimestamp) {
	my $oldFile = $allEtabFile . ".old";
	rename $allEtabFile, $oldFile or die "$!";
	open OLD , $oldFile or die "$!" ;
	open NEW , "> $allEtabFile" or die "$!";
	while (<OLD>) {
		chop;
		if (/^\s*([^;,#]+)([;,]\s*\d*)?(\s*(#.*)?)$/) {
			my $etab = $1;
			my $comment = $4;
			$etab =~ s/(\s+)$//; # suppression des blancs finaux 
			if ($etab) {
				print NEW $etab . " ; " . $etabTimestamp{$etab} . " $comment\n";
				next;
			} 
		} 
		print NEW $_."\n";
	}
}

# on fait le menage dans les comptes hors étab ou pas modifiés depuis longtemps.
&traitementEtab('HORS_ETAB', 0);

unless (isObjectStore()) {
	# creation des répertoires manquants
	# recherche des comptes créés sans répertoires.
	my $sql = connectSql();
	my $sqlQuery = q/select uid from oc_recia_user_history where hasRep is null and isadd = 1 and isdel = 0/;
	print "$sqlQuery\n";
	my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
	$sqlStatement->execute() or die $sqlStatement->errstr;
	my $cpt = 0;
	my $dir = $PARAM{'NC_DATA'} ;
	my $sqlUpdate = $sql->prepare(q/update oc_recia_user_history set hasRep = 1 where uid = ?/);
	while (my $uid =  ($sqlStatement->fetchrow_array)[0]) {
		my $newRep = "$dir/$uid";
		if  (-d $newRep) {
			print "$newRep existe déjà \n";
		} else {
			print "création de $newRep  ";
			mkdir($newRep, 0755) or die $!;
			print "\n";
		}
		$sqlUpdate->execute($uid) or die $sqlUpdate->errstr ;
	}
}


__END__
attribut ldap de detection des changement modifytimestamp>=20080601070000
