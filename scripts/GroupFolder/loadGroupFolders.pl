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
	Group->readNC(Etab->readNC($etab->{siren}));
	#faire la requete ldap
	my @entries = util->searchLDAP('ou=groups', $etab->{ldap}, 'cn');

	foreach my $regexGroup (@{$etab->{groups}}) {
		my $regex = $regexGroup->{regex};
		my $groupFormat = $regexGroup->{group};
		my $folderFormat = $regexGroup->{folder};
		my $adminFormat = $regexGroup->{admin};

		foreach my $entry (@entries) {
			my $cn = $entry->get_value ( 'cn' );
				if (my @res = $cn =~ /$regex/) {
					DEBUG! "$cn ", $regex;
					TRACE! Dumper(@res);
					
					if ($groupFormat) {
						my $group = sprintf($groupFormat, @res);
						DEBUG! $group;
						
						if ($folderFormat) {
							my $folder = sprintf($folderFormat, @res);
							DEBUG! "group folder", $folder;
						}
						
						if ($adminFormat) {
							my $folderAdmin = sprintf($adminFormat, @res);
							DEBUG! "Admin " , $folderAdmin;
						}
					}
				}
			}
		#DEBUG! $cn;
	} 
#	TRACE! Dumper(@entries);
#my	$RegexGroup = $etab->{groups};
#	TRACE! Dumper($RegexGroup);
}
