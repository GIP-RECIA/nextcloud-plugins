#! /usr/bin/perl
use strict;
use FindBin;
use lib $FindBin::Bin;
use DBI();
use Net::LDAP; #libnet-ldap-perl
use util;
use YAML::XS 'LoadFile'; #libyaml-libyaml-perl
use Data::Dumper;
use MyLogger;

MyLogger::level(4)
;my $config = LoadFile($FindBin::Bin.'/config.yml'); #$yaml->[0];
print "l'entrée: ", Dumper($config);


my $RegexGroup;

#my $sql = connectSql();

my $ldap = connectLdap();

foreach my $etab (@$config) {
	$RegexGroup = $etab->{groups};
	print Dumper($RegexGroup);
}
