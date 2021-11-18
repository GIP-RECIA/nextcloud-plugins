#!/usr/bin/perl
# scipt pour supprimer les fichiers en trop dans l'arborécense de NC (EXTRA_FILE)
# certaint de ces fichiers peuvent poser des problèmes.

use strict;
use utf8;
binmode STDOUT, ':encoding(UTF-8)';

my $logRep = $ENV{'NC_LOG'};
my $wwwRep = $ENV{'NC_WWW'};

$wwwRep = $ENV{'HOME'}.'/web' unless $wwwRep ;
chdir $wwwRep;

unless ($logRep) {
	$logRep = $ENV{'HOME'} . '/logs-esco'
}

# la commande pour recuperer les fichiers en trop EXTRA_FILE:
my $checkAppCom = 'php occ integrity:check-app -n --output=json_pretty ';
# $checkAppCom = 'cat testExtraFile.json '
my $checkCoreCom = 'php occ integrity:check-core -n --output=json_pretty ';

# nos applis qu'il ne faut absolument pas traiter 
my @ownApps = qw ( cssjsloader files_sharing ldapimporter );
# Pattern des fichiers a exclure du traitement, pour core essentiellement et le terminaison de fichie créer par nous.
my $regexExclus = '((^CAS-1.4.0)|(recia)|(esco)|(gip)|(\.old|\.org|\.save?|\.new)$)';


# la liste des applie a traiter 
my @allApps = qw (
	accessibility
	activity
	admin_audit
	cloud_federation_api
	comments
	contactsinteraction
	dav
	federatedfilesharing
	federation
	files
	files_external
	files_pdfviewer
	files_rightclick
	files_sharing
	files_trashbin
	files_versions
	files_videoplayer
	firstrunwizard
	logreader
	lookup_server_connector
	nextcloud_announcements
	notifications
	password_policy
	photos
	privacy
	provisioning_api
	recommendations
	serverinfo
	settings
	sharebymail
	support
	survey_client
	systemtags
	text
	theming
	twofactor_backupcodes
	updatenotification
	user_ldap
	viewer
	workflowengine
	);

my %protectApps;
foreach my $app (@ownApps) { $protectApps{$app} = 1 }; 

foreach my $app (@allApps) {
	if ($protectApps{$app}) {
		print "application $app non traité\n";
		next;
	} else {
		&traitementOneJson($checkAppCom, $app);
	}
}

# traitement du core
&traitementOneJson($checkCoreCom);

# on tar les fichiers .SAV générés
my $tarFileName = $logRep . '/EXTRA_FILE.' . &dateHeure4file() . '.tgz';

my $tarCommande = "find $wwwRep -name '*.SAV' | xargs /bin/tar -cvzf $tarFileName" ;
print $tarCommande , "\n";
system ($tarCommande) == 0 or die "$!"; 
print ("les fichiers à supprimer sont des .SAV et sauvegarder dans  $tarFileName \n");
print ("pour les supprimer de NC faire :\n\t find  $wwwRep -name '*.SAV' -delete \n");
print ("pour les restaures faire :\n\ttar -xvzf $tarFileName  ;\n\t find  $wwwRep -name '*.SAV' -exec restoreSAV.sh \\{\\}\\;\n ou qqchose du genre\n");

###### Fin #######

sub dateHeure4file(){
	my @local = localtime(time);
	return sprintf "%02d.%02d.%02d.%02d.%02d.%02d" , $local[5] - 100,  $local[4]+1, $local[3], $local[2], $local[1], $local[0];
}

sub traitementOneJson {
	my $com = shift;
	my $app = shift;
	print "$com $app\n";
	open JSON, "$com $app|" or die $!;
	while (<JSON>) {
		if (/"EXTRA_FILE": \{/) {
			&extraFiles($app);
		}
	}
	close JSON;
}

sub extraFiles {
	my $app = shift;
	print;
	while (<JSON>) {
		if (/"([^"]+)":\s*\{/) {
			&oneFile($1, $app);
			next;
		}
		#&passToFermante;
	}
}

sub passToFermante {
	my $nbOpen = 1 ;
	while (<JSON>) {
		if (/\{/) {$nbOpen++};
		if (/\}/) {return unless --$nbOpen};
	}
}

sub oneFile {
	my $fileName=shift;
	my $app = shift;
	if ($fileName =~ /$regexExclus/i) {
		print "$fileName : non traité\n";
		return 
	} 

	$fileName =~ s(\\/)(/)g;
	if ($app) {
		$fileName = "apps/$app/".$fileName;
	} 
	if (-w $fileName) {
		rename $fileName, $fileName . ".SAV" or die "$fileName :: $!";
	} else {
		print "can't delete $fileName\n";
	}
	&passToFermante;
}
