# fait la lecture de parametre depuis config.php
# donne une connection a la base
# place l'execution dans le HOME de l'utilisateur

BEGIN {
        use Exporter   ();
		@EXPORT_OK   = qw(%PARAM);
    }

use utf8;
use vars      @EXPORT_OK;
use Cwd;

my $logRep = $ENV{'NC_LOG'};
my  $dataRep = $ENV{'NC_DATA'};
my $wwwRep = $ENV{'NC_WWW'};

$wwwRep = $ENV{'HOME'}.'/web' unless $wwwRep ;
$logRep = $ENV{'HOME'} . '/logs-esco' unless $logRep ;
$dataRep = $ENV{'HOME'} . '/data' unless $dataRep;

my $configFile = "$wwwRep/config/config.php";

my $dir = getcwd;
chdir;
our %PARAM;

$PARAM{'REP_ORG'} = $dir;
$PARAM{'NC_LOG'} = $logRep;
$PARAM{'NC_DATA'} = $dataRep;
$PARAM{'NC_WWW'} = $wwwRep;
	
	# lecture des paramatres de conf

	open CONFIG, "$configFile" or die $!;

	while (<CONFIG>)  {
			if (/'(\w+)'\s*=>\s*'([^']+)'/) {
					$PARAM{$1} = $2;
			}
	}


# ex: 'nc-recette-'
my $defautBucket = $PARAM{'bucket'};

# ex: s3://nc-recette-
my $prefixBucket = "s3://$defautBucket";

my $s3command = "/usr/bin/s3cmd ";

my $sqlHost = $PARAM{'dbhost'};
my $sqlDatabase = $PARAM{'dbname'};
my $sqlUsr=$PARAM{'dbuser'};
my $sqlPass=$PARAM{'dbpassword'};
my $sqlDataSource = "DBI:mysql:database=$sqlDatabase;host=$sqlHost";
my $SQL_CONNEXION;


sub newConnectSql {
	print "connexion sql: $sqlDataSource, $sqlUsr, ...:\n";
	my $sql_connexion = DBI->connect($sqlDataSource, $sqlUsr, $sqlPass) || die $!;
	print " OK \n";
	$sql_connexion->{'mysql_auto_reconnect'} = 1;
	$sql_connexion->{'mysql_enable_utf8'} = 1;
	$sql_connexion->do('SET NAMES utf8');
	return $sql_connexion ;
}
sub connectSql {
	if ($SQL_CONNEXION) {
		return $SQL_CONNEXION;
	}
	$SQL_CONNEXION = newConnectSql();
	return $SQL_CONNEXION ;
}


# si $name == nc-recette-name/... => s3://nc-recette-name
# si $name != null =>  s3://nc-recette-name
# sinon  => s3://nc-recette-0
sub getBucketName(){
	my $name = shift;
	unless ($name) {
		$name = "0";
	}
	if ($name =~ m{^($defautBucket([^/]*))}) {
		if ($2) {
			$name = $2;
		}
		$name = "0";
	}
	return $prefixBucket . $name;
}

# 
sub fileUrn (){
	return "/urn:oid:" . shift;
}


sub s3path() {
	my $bucket =  &getBucketName(shift);
	my $fileId = shift;
	
	if ($fileId) {
		$bucket .= &fileUrn($fileId);
	}
	return $bucket;
}

sub lsCommande() {
	return "$s3command ls ".shift;
}

sub duCommande() {
	return "$s3command du ".shift;
}

sub getS3command(){
	return $s3command;
}

sub promptCommande(){
	$commande = shift;
	$refGlobalChoix = shift;
	my $choix;
	if ($$refGlobalChoix) {
		print "$commande \n";
		$choix = $$refGlobalChoix;
	} else {
		print "$commande O/n/all/none/quit ? ";
		 $choix = <STDIN>;
		chomp $choix;
		if ($choix eq 'none') {
			$choix = $$refGlobalChoix = 'n';
		} elsif ($choix eq 'all') {
			$choix = $$refGlobalChoix = 'O';
		} elsif ($choix eq 'quit') {
			exit 0;
		}
	}
	return $choix eq 'O';
}

sub partagePermission {
	my $perm = shift;
	my $flags = "($perm";
	
	if ($perm < 0) {
		return  "(permission possible:  Modification Création Supression Repartage)";
	}
	if ($perm & 2 ) {
		$flags .= ' Mo'; # Modification
	}
	if ($perm & 4 ) {
		$flags .= ' Cr'; # création
	} 
	if ($perm & 8 ) {
		$flags .= ' Su'; # Supression
	}
	if ($perm & 16 ) {
		$flags .= ' Re'; # Repartage
	}
	return $flags . ')';
}

sub toGiga {
	my $val = shift;
	my $unit = shift;
	if ($val) {
		if (@_) {
			my $res = $val % 1024;
			if ($res) {
				return toGiga(int($val/1024),@_) . $res. "$unit";
			}
			return toGiga(int($val/1024),@_);
		} else {
			return $unit ? "$val$unit" : toGiga($val, 'o', 'Ko ', 'Mo ', 'Go ', 'To '); 
		}
	}
	return $unit ? "" : "0o";
}

1;
