BEGIN {
        use Exporter   ();
		@EXPORT_OK   = qw(%PARAM);
    }
use vars      @EXPORT_OK;
use Cwd;
use MyLogger;

my $logRep = $ENV{'NC_LOG'};
my $wwwRep = $ENV{'NC_WWW'};

$wwwRep = $ENV{'HOME'}.'/web' unless $wwwRep ;
$logRep = $ENV{'HOME'} . '/logs-esco' unless $logRep ;


my $configFile = "$wwwRep/config/config.php";

my $dir = getcwd;
chdir;
our %PARAM;

$PARAM{'NC_LOG'} = $logRep;
$PARAM{'NC_WWW'} = $wwwRep;
	
	# lecture des paramatres de conf

	open CONFIG, "$configFile" or die $!;

	while (<CONFIG>)  {
		if (/'(\w+)'\s*=>\s*'([^']+)'/) {
			$PARAM{$1} = $2;
		}
	}
$PARAM{'NC_DATA'} = $PARAM{'datadirectory'};

my $sqlHost = $PARAM{'dbhost'};
my $sqlDatabase = $PARAM{'dbname'};
my $sqlUsr=$PARAM{'dbuser'};
my $sqlPass=$PARAM{'dbpassword'};
my $sqlDataSource = "DBI:mysql:database=$sqlDatabase;host=$sqlHost";
my $SQL_CONNEXION;

my $ldapHost;
my $ldapUsr;
my $ldapPass;
my $ldapBaseDn;

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

sub connectLdap {
	unless ($ldapHost && $ldpaUsr && $ldapPass) {
		my $sql = connectSql();
		my $sqlQuery = q(select configkey, configvalue from oc_appconfig where configkey like 'cas_import_ad%' and appid = 'ldapimporter');
		INFO! "$sqlQuery\n";
		my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
		$sqlStatement->execute() or die $sqlStatement->errstr;

		my $host = 'localhost';
		my $port = ':389';
		my $proto = 'ldap//';
		
		while (my @tuple =  $sqlStatement->fetchrow_array()) {
			if ($tuple[0] eq 'cas_import_ad_base_dn') {
				$ldapBaseDn = $tuple[1];
			} elsif ($tuple[0] eq 'cas_import_ad_host') {
				$host = $tuple[1];
			} elsif ($tuple[0] eq 'cas_import_ad_password') {
				$ldapPass = $tuple[1];
			} elsif ($tuple[0] eq 'cas_import_ad_port') {
				$port = ':' . $tuple[1];
			} elsif ($tuple[0] eq 'cas_import_ad_user') {
				$ldapUser = $tuple[1];
			} elsif ($tuple[0] eq 'cas_import_ad_protocol') {
				$proto = $tuple[1];
			}
		}
		$ldapHost = $proto . $host . $port;
	}
	INFO! 'Ldap connexion: ', $ldapHost, $ldapUser;
		# le parametre raw est un regex qui filtre  les attributs binaires. 
		# Les attributs qui ne verifie pas la regex seront en utf-8.
		# si on ne met rien les attribut utf-8 seront considérés comme binaire
		# et l'encodage sera incorecte.
		# Nous n'avons pas d'attribut binaire d'ou la valeur choisie qui ne doit matcher aucun attribut
	my $ldap = Net::LDAP->new($ldapHost,  async => 1,
						raw => '^UTF-8$' ) or die "$@";
	
	$ldap->debug(0);
	
	
	my $mesg = $ldap->bind( $ldapUsr,
	                      password => $ldapPass
	                    );
	
	$mesg->code && die $mesg->error;
	
	INFO! "Ldap bind: ", $ldapUsr;
	return $ldap;
}

1;
