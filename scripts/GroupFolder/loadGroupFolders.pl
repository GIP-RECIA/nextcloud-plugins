#!/usr/bin/perl

=encoding utf8

=head1 NAME

	loadGroupFolder.pl

	charge les groupes ldap pour créer les groupes NC avec leurs groupFolders associés.

=head1 SYNOPSIS

	loadGroupFolder.pl [-t] [-q] [-f filename.yml] [-l loglevel] up|all|siren...

	Options:
	-t test la conf uniquement
	-f donne le fichier de conf avec les regexes
	-l niveau de log : 1:error 2:warn 3:info 4:debug 5:trace ; par defaut est à 2.
	-q force la mise a jour des quotas sinon les quotas de la conf sont les quotas minimums (ne peuvent pas faire diminuer les quotas de la base)
	-u importe les utilisateurs des établissements modifiés à l'aide de loadEtab.pl.      
	up traite les étabs du fichier des timestamps ayant des groupes modifiés.
	all traite tous les étabs du fichier de conf, sans verifier les timestamps. 
	siren des étabs à traiter sans verifier les timestamps.

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
use Net::LDAP; #libnet-ldap-perl
use Pod::Usage qw(pod2usage);
use YAML::XS 'LoadFile'; #libyaml-libyaml-perl
use Data::Dumper;
use Getopt::Long;
use sigtrap 'handler' => \&END, 'HUP', 'INT','ABRT','QUIT','TERM';


use util;

use Folder;
use Group;
use Etab;
use GroupFolder;

my $fileYml = "config.yml";
my $test = 0;
my $loglevel;
my $forceQuota;
my $userLoad;

MyLogger->level(2, 1);

unless (@ARGV && GetOptions ( "f=s" => \$fileYml, "t" => \$test, "l=i" => \$loglevel, "q" => \$forceQuota, "u" => \$userLoad) ) {
	my $myself = $FindBin::Bin . "/" . $FindBin::Script ;
	#$ENV{'MANPAGER'}='cat';
	pod2usage( -message =>"ERROR:	manque d'arguments", -verbose => 1, -exitval => 1 , -input => $myself, -noperldoc => 1 );
}

my $configFile = $FindBin::Bin."/$fileYml";

my $config = LoadFile($configFile);



my $loadUserCommande = ${util::PARAM}{'NC_SCRIPTS'}. '/loadEtabs.pl ';
#print "l'entrée: ", Dumper($config);

my $logsFile = $config->{logsFile};

unless ($logsFile) {
	$logsFile = ${util::PARAM}{'NC_LOG'}. '/Loader/groupFolders.log'
}
my $jour = util->jour();
$logsFile =~ s/\.log/\.$jour\.log/;

MyLogger->file('>>' . $logsFile);

if ($test) {
	MyLogger->level(5, 1);
} else {
	if ($loglevel) {
		MyLogger->level($loglevel, 2);
	}
}

my $sirenList;
my $traitementComplet=0;
my $useTimeStamp = $ARGV[0] eq 'up';

unless ($useTimeStamp) {
	if ($ARGV[0] eq 'all') {
		$traitementComplet = 1;
	} else {
		$sirenList = join " " , @ARGV;
	}
}

§LOG "-------- Start $0 " , join(" ", @ARGV), ' --------';
§INFO "configFile= ", $configFile;
§INFO "logsFile= ", $logsFile;

my $timestampFile = $config->{timestampFile};
unless ($timestampFile) {
	$timestampFile = ${util::PARAM}{'NC_LOG'}. '/groupFoldersTime.csv'
}

§INFO "timestampFile= ", $timestampFile;


my %etabTimestamp;
if (-f $timestampFile ) {

	open TS, $timestampFile or §FATAL  $!, " $timestampFile" ;
	while (<TS>) {
		chomp ;
		my ($siren, $time, $nom) = split('\s*;\s*');
		if ($siren) {
			$time =~ s/\s*//g;
			if (! exists $etabTimestamp{$siren} || $etabTimestamp{$siren} lt $time) { 
				$etabTimestamp{$siren} = $time;
			}
		}
	}
	close TS;
} else {
	§WARN "timestampFile inexistant !\n";
}
my $newTimeStampLdap = util->timestampLdap(time);


if ($test) {
	§INFO "Mode Test : Affichage des timestamps : ";
	§INFO Dumper(\%etabTimestamp);
	§INFO "Mode Test : Dump du fichier de conf";
	§INFO Dumper($config);

	§INFO "Mode Test : on fait les calculs sans executer les commandes occ ";
	util->testMode();
} 

if ($forceQuota) {
	GroupFolder->forceQuota(1);
}


my $suffixGroup = $config->{suffixGroup};
##### debut du travail ######

Folder->readNC;

my %etabForLoad;


my $cpt = 0;
my $fin = 0;
until ($fin++) {
	$cpt++; # multiples iterations, au cas ou l'annuaire est en cours de mise a jour 
	§DEBUG "------------------- nouvelle Itération $cpt ------------------"; 
	foreach my $confEtab (@{$config->{etabs}}) {
		if (&traitementEtab($confEtab)) {
			$fin = 0 if $useTimeStamp;
		}
	}
	§DEBUG "-------------------- fin Itération $cpt ------------------";
}


if  ($traitementComplet ) {
	# on ne supprime pas les folders qui n'existe plus mais il faut supprimer les associations des groupes aux folders qui n'ont plus lieux d'être
	# ce traitement ne peut pas être fait sur les differentiels, il faut un traitement complets.
	Folder->cleanAllFolder();
	if ($userLoad) {
		§SYSTEM $loadUserCommande . " all";
	}

} elsif (!$test ) {
	my @etabList = keys(%etabForLoad);
	if (@etabList && $userLoad) {
		§SYSTEM $loadUserCommande . join(" ", @etabList);
	}
}

END {
	if (! $test && -f $timestampFile) {
		§INFO "écriture des timestamps";
		my $oldFile = $timestampFile . ".old";
		rename $timestampFile, $oldFile;
		open OLD, $oldFile or §FATAL  $!, " $oldFile" ;
		open NEW, ">$timestampFile" or §FATAL $!, " " , $timestampFile;
		while (<OLD>) {
			my ($siren, $time, $nom) = split('\s*;\s*');
			# attention $nom finit par \n
			if ($siren) {
				my  $etab = Etab->getEtab($siren);
				if ($etab) {
					if ($etab->timestamp()) {
						printf NEW "%s; %s; %s\n", $siren, $etab->timestamp, $etab->name;
					} else {
						printf NEW "%s; %s; %s", $siren, $time, $nom;
					}
					$etab->releaseEtab();
					next;
				}
			}
			print NEW;
		}
		while (my $etab = Etab->nextEtab()) {
			printf NEW "%s; %s; %s\n", $etab->siren, $etab->timestamp, $etab->name;
		}
	}
	§LOG "-------- Stop $0 ---------\n";
}


sub traitementRegexGroup {
	my $etabNC = shift;
	my $confGroupsList = shift;
	my @grpRegexMatches = @_;

	# §TRACE Dumper(@res);
	#§DEBUG "traitementRegexGroup :" ,Dumper($confGroupsList);
	foreach my $confGroup (@{$confGroupsList}) {

		§DEBUG Dumper($confGroup);
		my $groupFormat = $confGroup->{group};
		
		if ($groupFormat) {

			my $groupNC = Group->getOrCreateGroup(sprintf($groupFormat, @grpRegexMatches), $etabNC, $suffixGroup);

			my $confFoldersList = $confGroup->{folders};

			unless ($confFoldersList) {
				$confFoldersList = [$confGroup];
			}
			
			foreach my $confFolder (@{$confFoldersList}) {
				my $folderName = $confFolder->{folder};
				if (ref($folderName) eq  'ARRAY') {
					$folderName = join "/", @$folderName;
				}
				§DEBUG "foldername = ", Dumper($folderName);
				GroupFolder->createFolder4Group(
						$etabNC,
						$folderName,
						$confFolder->{quotaF},
						$confFolder->{permF},
						$groupNC,
						@grpRegexMatches
					);
			}
			
			my $adminFolderFormat = $confGroup->{admin};

			if ($adminFolderFormat) {
				GroupFolder->addGroup4AdminFolder(
						$etabNC,
						$groupNC,
						$adminFolderFormat,
						@grpRegexMatches
					);
			}
		}
	}
}


sub traitementEtabGroup {
	my $confEtab = shift;
	my $etabNCdefault = shift;
	my $allLdapGroups = shift;

	my $regexes =  $confEtab->{regexes};

	unless ($regexes) {
		$regexes = [$confEtab];
	}

	my $etabReload = 0;
	#§DEBUG Dumper($confEtab);
	§DEBUG Dumper($regexes);
	foreach my $confRegexGroup (@{$regexes}) {
		my $regex = $confRegexGroup->{regex};
		my $confGroups = $confRegexGroup->{groups};
		my $last = $confRegexGroup->{last};
		my $uaiFormat = $confRegexGroup->{uai};
		my $lastIfMatch;
		my $lastIfNotMatch;
		
		§INFO "REGEX = $regex";
		
		unless ($confGroups) {
			$confGroups = [$confRegexGroup];
		}
		if ($last) {
			 # dans last seulement deux terms autorisés les autres sont ignorés
			if  ($last =~ /^ifMatch$/) {
				$lastIfMatch = 1;
			} elsif ($last =~ /^ifNoMatch$/) {
				$lastIfNotMatch = 1;
			} else {
				§WARN "Ingnore last: $last";
			}
		}

		#s'il y a un uai on traite sur un autre etab que celui passé en parametre
		
		
GROUPLDAP:
		foreach my $entryGrp (@{$allLdapGroups}) {
			next unless $entryGrp;
			my $etabNC;
			my $uai;
			#§DEBUG "entryGrp=", Dumper($entryGrp);
			my $cnGroup = $entryGrp->get_value ( 'cn' );

			§DEBUG "avant regex $cnGroup ";
			if (my @res = ($cnGroup =~ /$regex/)) {
				§INFO "\tGrouper Group= $cnGroup ";
				
				if ($uaiFormat) { #si on a un uai tiré du groupe on le calcul
					$uai = sprintf($uaiFormat, @res);
					$etabNC = Etab->etabNCbyUai($uai);
					unless ($etabNC) {
						§WARN "Etab non trouvé, uaiFormat=$uaiFormat => uai = $uai";
						next GROUPLDAP ;
					}
				} else { # si pas d'uai le groupe est crée dans l'etab par défaut
					$etabNC = $etabNCdefault;
				}
				&traitementRegexGroup($etabNC,$confGroups, @res);
				$entryGrp = '' if $lastIfMatch;
				if ($uai) {
					$etabForLoad{$uai} = 1;
					$etabNC->timestamp($newTimeStampLdap);
				} else {
					$etabForLoad{$etabNC->siren()} = 1;
				}
				$etabReload = 1;
			} else {
				$entryGrp = '' if $lastIfNotMatch;
			}
			
		}
		
	}
	return $etabReload;
}
#return 1 si ldap rammene des groups 0 sinon
sub traitementEtab {
	my $confEtab = shift;
	my $siren = $confEtab->{siren};
	my $filtreLdapList = $confEtab->{ldapFilterList};

	unless ( $filtreLdapList ) {
				$filtreLdapList = [ $confEtab->{ldapFilterGroups} ];
	}
		
	if ($siren) { 
		my $etabNC = Etab->readNC($siren);

		if (! $useTimeStamp && $sirenList && ! $sirenList =~ /$siren/) {
			return 0;
		}

		

		unless ($etabNC) {
			$etabNC = Etab->addEtab($siren, $confEtab->{nom})
		}

		my $lastTimeStampLdap  = $etabNC->timestamp;

		unless ($lastTimeStampLdap) {
			$lastTimeStampLdap=$etabTimestamp{$siren};
		}

		Group->readNC($etabNC);

		my $reloadEtab = 0;
		foreach my $confFiltreLdap (@$filtreLdapList) {
			#faire la requete ldap
			my $filtreLdap =  $confFiltreLdap->{ldapFilterGroups};
			chomp $filtreLdap ;

			if ($useTimeStamp && $lastTimeStampLdap) {
				$filtreLdap = sprintf( "(&%s(modifytimestamp>=%sZ))", $filtreLdap, $lastTimeStampLdap);
			}

			§DEBUG "filtre ldap =", $filtreLdap;
			my @ldapGroups = util->searchLDAP('ou=groups', $filtreLdap, 'cn');

			§DEBUG "nb ldapGroups =", scalar @ldapGroups;
			if (@ldapGroups) {
				$reloadEtab += &traitementEtabGroup($confFiltreLdap, $etabNC, \@ldapGroups);
				# si tout est ok on met a jour le  timestamp

				#TODO faire le traitement des utilisateurs ici car on a des groups modifiés
				$etabNC->timestamp($newTimeStampLdap);

			} else {
				§INFO "pas de groupe LDAP";
			}
		}
		
		return $reloadEtab;
	}
	return 0;
}

#util->occ("user:list");
__END__
