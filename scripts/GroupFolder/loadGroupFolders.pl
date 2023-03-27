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

MyLogger::level(5, 2);
MyLogger->file('/home/esco/scripts/loadGroupFolder.log');

use Getopt::Long;
use Pod::Usage qw(pod2usage);
use GroupFolder;
use Group;
use Etab;
my $fileYml = "config.yml";
my $test = 0;

unless (@ARGV || 1 and GetOptions ( "f=s" => \$fileYml, "t" => \$test) ) {
	my $myself = $FindBin::Bin . "/" . $FindBin::Script ;
	pod2usage(-verbose => 3, -exitval => 1 , -input => $myself);
}

my $config = LoadFile($FindBin::Bin."/$fileYml"); #$yaml->[0];
#print "l'entrée: ", Dumper($config);




GroupFolder->readNC;

foreach my $etab (@$config) {
	my $etabNC = Etab->readNC($etab->{siren});
	unless ($etabNC) {
		$etabNC = Etab->addEtab($etab->{siren}, $etab->{nom})
	}
	Group->readNC($etabNC);
	#faire la requete ldap
	my @ldapGroups = util->searchLDAP('ou=groups', $etab->{ldap}, 'cn');

	foreach my $regexGroup (@{$etab->{groups}}) {
		my $regex = $regexGroup->{regex};
		my $groupFormat = $regexGroup->{group};
		my $folderFormat = $regexGroup->{folder};
		my $adminFormat = $regexGroup->{admin};
		my $quotaF = $regexGroup->{quotaF};
		my $permF = $regexGroup->{permF};

		DEBUG! "REGEX= ", $regex , "; permF=" , Dumper($permF);

		foreach my $entryGrp (@ldapGroups) {
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
						}
					}
				}
			} else {
#				TRACE! "$cn no match\n";
			}
		}
		#DEBUG! $cn;
	}
#	TRACE! Dumper(@ldapGroups);
#my	$RegexGroup = $etab->{groups};
#	TRACE! Dumper($RegexGroup);
}

#util->occ("user:list");
