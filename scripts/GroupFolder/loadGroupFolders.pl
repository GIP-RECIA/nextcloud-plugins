#! /usr/bin/perl

=encoding utf8

=head1 NAME loadGroupFolder.pl
charge les groupes ldap pour créer les groupes NC avec le groupFolders associés.

=cut

use strict;
use FindBin;
use lib $FindBin::Bin;
use DBI();
use Net::LDAP; #libnet-ldap-perl
use YAML::XS 'LoadFile'; #libyaml-libyaml-perl
use Data::Dumper;
use util;
use MyLogger;

MyLogger::level(5, 1);

use Getopt::Long;
use Pod::Usage qw(pod2usage);
use GroupFolder;
use Group;
use Etab;
my $fileYml = "config.yml";
my $test = 0;
use sigtrap 'handler' => \&END, 'HUP', 'INT','ABRT','QUIT','TERM';

unless (@ARGV || 1 and GetOptions ( "f=s" => \$fileYml, "t" => \$test) ) {
	my $myself = $FindBin::Bin . "/" . $FindBin::Script ;
	pod2usage(-verbose => 3, -exitval => 1 , -input => $myself);
}

my $configFile = $FindBin::Bin."/$fileYml";

my $config = LoadFile($configFile); #$yaml->[0];

if ($test) {
	INFO! "En Mode Test du fichier de conf";
	INFO! Dumper($config);
	exit;
}
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
	INFO! "Lecture des timestamp";
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
#INFO! Dumper(\%etabTimestamp);

GroupFolder->readNC;


my $cpt = 1;
while ($cpt--) {
	
	INFO! "------------------- nouvelle Itération $cpt ------------------"; 
	foreach my $etab (@{$config->{etabs}}) {
		$cpt |= &traitementEtab($etab);
	}
	INFO! "-------------------- fin Itération $cpt ------------------";
#	sleep 60 if  $cpt;
}

END {
	if (-f $timestampFile) {
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
	my $regex = shift;
	my $entryGrp =shift;
	my $regexGroupList = shift;

	foreach my $regexGroup (@{$regexGroupList}) {
		my $groupFormat = $regexGroup->{group};
		my $folderFormat = $regexGroup->{folder};
		my $adminFormat = $regexGroup->{admin};
		my $quotaF = $regexGroup->{quotaF};
		my $permF = $regexGroup->{permF};
		my $cn = $entryGrp->get_value ( 'cn' );
		if (my @res = $cn =~ /$regex/) {
			DEBUG! "\tGroup= $cn ";
#				TRACE! Dumper(@res);
			if ($groupFormat) {
				my $group = Group->getOrCreateGroup(sprintf($groupFormat, @res), $etabNC);

				DEBUG! "\t\t" , Dumper($group);

				if ($folderFormat) {
					my $folder = GroupFolder->updateOrCreateFolder(sprintf($folderFormat, @res), $quotaF);
					if ($folder) {
						$folder->addGroup($group, @$permF);
						DEBUG! "\t\t\tgroup folder ", Dumper($folder);
					}
				}

				if ($adminFormat) {
					my $folderAdmin = sprintf($adminFormat, @res);
					DEBUG! "\t\t\tgroup folder admin: ",  $folderAdmin;
					my $folder = GroupFolder->getFolder($folderAdmin);
					if ($folder) {
						DEBUG! "\t\t\t\tgroup folder admin add group";
						$folder->addAdminGroup($group);
					} else {
						if (index($folderAdmin, '^') == 0 ) {
							my @folderList = GroupFolder->findFolders($folderAdmin);
							foreach my $f (@folderList) {
								$f->addAdminGroup($group);
							}
						} 
					}
				}
			}
		} else {
#				TRACE! "$cn no match\n";
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

	my $filtreLdap =  $etab->{ldap};
	chomp $filtreLdap ;
	if ($lastTimeStampLdap) {
		$filtreLdap = sprintf( "(&%s(modifytimestamp>=%sZ))", $filtreLdap, $lastTimeStampLdap);
	}
	
	
	INFO! "filtre ldap =", $filtreLdap;
	my @ldapGroups = util->searchLDAP('ou=groups', $filtreLdap, 'cn');

	if (@ldapGroups) {
		INFO! $siren, " a des groupes";
		foreach my $regexGroup (@{$etab->{regexs}}) {
			my $regex = $regexGroup->{regex};
			my $groups = $regexGroup->{groups};
			
			unless ($groups) {
				$groups = [$regexGroup];
			}

			foreach my $entryGrp (@ldapGroups) {
				&traitementRegexGroup($etabNC, $regex, $entryGrp, $groups);
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
