#!/usr/bin/perl


=encoding utf8

=head1 NAME

	loadGroupFolder.pl

	charge les groupes ldap pour créer les groupes NC avec leurs groupFolders associés.

=head1 SYNOPSIS

 loadGroupFolder.pl [-t] [-f filename.yml] [all | siren+]

 Options:
	-t test la conf uniquement
	-f donne le fichier de conf avec les regexs
	all traite tous les étabs ayant un timestamp dans le fichier des timstamps
	siren des fichiers à traiter.

=cut

use strict;
use FindBin;
use lib $FindBin::Bin;
use DBI();
use Net::LDAP; #libnet-ldap-perl
use Pod::Usage qw(pod2usage);
use YAML::XS 'LoadFile'; #libyaml-libyaml-perl
use Data::Dumper;
use Getopt::Long;
use sigtrap 'handler' => \&END, 'HUP', 'INT','ABRT','QUIT','TERM';

use util;
use MyLogger;
use Folder;
use Group;
use Etab;
use GroupFolder;

MyLogger::level(5, 1);

my $fileYml = "config.yml";
my $test = 0;

unless (@ARGV && GetOptions ( "f=s" => \$fileYml, "t" => \$test) ) {
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
	$logsFile = ${util::PARAM}{'NC_LOG'}. '/groupFolders.log'
}
MyLogger->file($logsFile);

INFO! "configFile= ", $configFile;
INFO! "logsFile= ", $logsFile;

my $timestampFile = $config->{timestampFile};
unless ($timestampFile) {
	$timestampFile = ${util::PARAM}{'NC_LOG'}. '/groupeFolderTime.csv'
}

INFO! "timestampFile= ", $timestampFile;

my %etabTimestamp;
if (-f $timestampFile) {
	INFO! "Lecture des timestamps";
	open TS, $timestampFile or FATAL!  $!, " $timestampFile" ;
	while (<TS>) {
		chomp ;
		my ($siren, $time, $nom) = split('\s*;\s*');
		if ($siren) {
			$time =~ s/\s*//g;
			$etabTimestamp{$siren} = $time;
		}
	}
	close TS;
}

if ($test) {
	MyLogger::level(5, 1);
	INFO! "Mode Test : Affichage des timestamps : ";
	INFO! Dumper(\%etabTimestamp);
	INFO! "Mode Test : Dump du fichier de conf";
	INFO! Dumper($config);

	INFO! "Mode Test : on fait les calculs sans executer les commandes occ ";
	util->testMode();
} else {
	MyLogger::level(5, 0);
}

##### debut du travail ######

Folder->readNC;

my %etabForLoad;


my $isChange;
my $cpt = 2;
while (--$cpt) {
	DEBUG! "------------------- nouvelle Itération $cpt ------------------"; 
	foreach my $etab (@{$config->{etabs}}) {
		if (&traitementEtab($etab)) {
			$etabForLoad{$etab->{siren}} = 1;
			$cpt = 1;
			$isChange = 1;
		}
	}
	DEBUG! "-------------------- fin Itération $cpt ------------------";
}

if ($isChange && !$test) {
	SYSTEM! $loadUserCommande . join(" ", keys(%etabForLoad)); 
}
END {
	if (! $test && -f $timestampFile) {
		INFO! "écriture des timestamps";
		my $oldFile = $timestampFile . "old";
		rename $timestampFile, $oldFile;
		open OLD, $oldFile or FATAL!  $!, " $oldFile" ;
		open NEW, ">$timestampFile" or FATAL! $!, " " , $timestampFile;
		while (<OLD>) {
			my ($siren, $time, $nom) = split('\s*;\s*');
			if ($siren) {
				my  $etab = Etab->getEtab($siren);
				if ($etab && $etab->timestamp) {
					printf NEW "%s; %s; %s\n", $siren, $etab->timestamp, $etab->name;
					$etab->releaseEtab;
					next;
				}
			}
			print NEW;
		}
		while (my $etab = Etab->nextEtab) {
			printf NEW "%s; %s; %s\n", $etab->siren, $etab->timestamp, $etab->name;
		}
	}
}

sub traitementRegexGroup {
	my $etabNC = shift;
	my $regexGroupList = shift;
	my @grpRegexMatches = @_;
	
	# TRACE! Dumper(@res);
	foreach my $regexGroup (@{$regexGroupList}) {
		my $groupFormat = $regexGroup->{group};

		if ($groupFormat) {
			GroupFolder->createGroupAndFolder(
					$etabNC,
					$groupFormat,
					$regexGroup->{folder},
					$regexGroup->{admin},
					$regexGroup->{quotaF},
					$regexGroup->{permF},
					@grpRegexMatches
				);
		}
	}
}

#return 1 si ldap ramene des groups 0 sinon
sub traitementEtab {
	my $etab = shift;
	my $siren = $etab->{siren};
	my $etabNC = Etab->readNC($siren);
	
	my $newTimeStampLdap = util->timestampLdap(time);
	
	unless ($etabNC) {
		$etabNC = Etab->addEtab($siren, $etab->{nom})
	}
	
	my $lastTimeStampLdap  = $etabNC->timestamp;
	unless ($lastTimeStampLdap) {
		$lastTimeStampLdap=$etabTimestamp{$siren};
	}
	
	Group->readNC($etabNC);
	#faire la requete ldap

	my $filtreLdap =  $etab->{ldapFilterGroups};
	chomp $filtreLdap ;
	if ($lastTimeStampLdap) {
		$filtreLdap = sprintf( "(&%s(modifytimestamp>=%sZ))", $filtreLdap, $lastTimeStampLdap);
	}
	
	INFO! "filtre ldap =", $filtreLdap;
	my @ldapGroups = util->searchLDAP('ou=groups', $filtreLdap, 'cn');

	if (@ldapGroups) {
		INFO! $siren, " a des groupes: " ;
		foreach my $regexGroup (@{$etab->{regexs}}) {
			my $regex = $regexGroup->{regex};
			my $groups = $regexGroup->{groups};
			my $last = $regexGroup->{last};
			my $lastIfMatch;
			my $lastIfNotMatch;
			
			INFO! "REGEX = $regex";
			
			unless ($groups) {
				$groups = [$regexGroup];
			}
			if ($last) {
				 # dans last seulement deux terms autorisés les autres sont ignorés
				if  ($last =~ /^ifMatch$/) {
					$lastIfMatch = 1;
				} elsif ($last =~ /^ifNoMatch$/) {
					$lastIfNotMatch = 1;
				} else {
					WARN! "Ingnore last: $last";
				}
			}
			foreach my $entryGrp (@ldapGroups) {
				next unless $entryGrp;
				my $cnGroup = $entryGrp->get_value ( 'cn' );

				if (my @res = ($cnGroup =~ /$regex/)) {
					INFO! "\tGrouper Group= $cnGroup ";
					&traitementRegexGroup($etabNC,$groups, @res);
					$entryGrp = '' if $lastIfMatch;
				} else {
					$entryGrp = '' if $lastIfNotMatch;
				}
			}
			#DEBUG! $cn;
		}
		# si tout est ok on met a jour le  timestamp
		$etabNC->timestamp($newTimeStampLdap);
		return 1;
	} 
	INFO! "pas de groupe LDAP";
	$etabNC->timestamp($lastTimeStampLdap);
	return 0;
}

#util->occ("user:list");
__END__
