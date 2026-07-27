#!/usr/bin/perl

=encoding utf8
=head1 NAME

	saveConf.pl
	sauvegarde la conf NC: config.php, la definition des groups de ldpadimporter.

=head1 SYNOPSIS

	saveConf.pl (-g|-c) [-d directory]
	
=cut

use strict;
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use open qw( :std :encoding(UTF-8) );

use FindBin;
#use Filter::sh "tee " . __FILE__ . ".pl"; # pour  debuger les macros
use DBI();
use Pod::Usage qw(pod2usage);
use Data::Dumper;
use Getopt::Long;

use lib $FindBin::Bin . "/GroupFolder";
use MyLogger  'DEBUG';
use util;

MyLogger->level(2, 1);

my $directory;
my $config;
my $groups;

my $aVersionner;

unless (@ARGV && GetOptions ( "d=s" => \$directory, "c" => \$config, "g" => \$groups, "v", "git" => \$aVersionner) ) {
	my $myself = $FindBin::Bin . "/" . $FindBin::Script ;
	#$ENV{'MANPAGER'}='cat';
	pod2usage( -message =>"ERROR:	manque d'arguments", -verbose => 1, -exitval => 1 , -input => $myself, -noperldoc => 1 );
}


if ($config) {
	my $confRep = ${util::PARAM}{'NC_WWW'}. '/config';
	if ($directory) {
		§SYSTEM "cp -uv $confRep/*.php $directory" ;
		$aVersionner++ if $aVersionner;
	} else {
		§SYSTEM "cat $confRep/config.php", OUT => sub {print $_;}, MOD => 0;
	}
}

if ($groups) {
	my $sqlRes = util->executeSql(
		q/select  configkey, configvalue
		from oc_appconfig
		where appid = 'ldapimporter'
		and  configkey in ('cas_import_map_groups_fonctionel', 'cas_import_map_groups_pedagogic', 'cas_import_map_regex_name_uai')
		order by configkey/);

	if ($sqlRes) {
		if ($directory) {
			open FILE , ">$directory/ldapimporter" or die $!, " $directory/ldapimporter";
			while (my @tuple =  $sqlRes->fetchrow_array()) {
				print FILE $tuple[0],"\t", $tuple[1], "\n";
			}
			$aVersionner++ if $aVersionner;
			close FILE
		} else {
			while (my @tuple =  $sqlRes->fetchrow_array()) {
				print $tuple[0],":\n";
#				§SYSTEM "/usr/bin/jq -C .", INIT => [$tuple[1]], OUT => sub { print ;} , ERR => sub { print ;};
				open FILE, "|/usr/bin/jq -C .";
				print FILE  $tuple[1], "\n";
				close FILE;
			}
			
		}
	}
}

if ($aVersionner > 1) {
	chdir $directory;
	my @status;
	§SYSTEM "git status --short -u no" , OUT => \@status ;
	my $message = join "", map ({s/\s+/ /g; $_}  @status);
	§SYSTEM "git commit -a -m '$message'" if $message;
}

