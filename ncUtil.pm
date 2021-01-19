# fait la lecture de parametre depuis config.php
# donne une connection a la base
# place l'execution dans le HOME de l'utilisateur

BEGIN {
        use Exporter   ();
		@EXPORT_OK   = qw(%PARAM);
    }
use vars      @EXPORT_OK;

my $configFile = "web/config/config.php";

chdir;
our %PARAM;


	
	# lecture des paramatres de conf

	open CONFIG, "$configFile" or die $!;

	while (<CONFIG>)  {
			if (/'(\w+)'\s*=>\s*'([^']+)'/) {
					$PARAM{$1} = $2;
			}
	}
	
my $defautBucket = $PARAM{'bucket'};
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
1;
