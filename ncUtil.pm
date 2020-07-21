
BEGIN {
        use Exporter   ();
		@EXPORT_OK   = qw(%PARAM);
    }
use vars      @EXPORT_OK;

my $configFile = "web/config/config.php";

chdir;
my %PARAM;


	
	# lecture des paramatres de conf

	open CONFIG, "$configFile" or die $!;

	while (<CONFIG>)  {
			if (/'(\w+)'\s*=>\s*'([^']+)'/) {
					$PARAM{$1} = $2;
			}
	}
	

my $sqlHost = $PARAM{'dbhost'};
my $sqlDatabase = $PARAM{'dbname'};
my $sqlUsr=$PARAM{'dbuser'};
my $sqlPass=$PARAM{'dbpassword'};
my $sqlDataSource = "DBI:mysql:database=$sqlDatabase;host=$sqlHost";
my $SQL_CONNEXION;

sub connectSql {
	if ($SQL_CONNEXION) {
		return $SQL_CONNEXION;
	}
	print "connexion sql: $sqlDataSource, $sqlUsr, ...:\n";
	$SQL_CONNEXION = DBI->connect($sqlDataSource, $sqlUsr, $sqlPass) || die $!;
	print " OK \n";
	$SQL_CONNEXION->{'mysql_auto_reconnect'} = 1;
	$SQL_CONNEXION->{'mysql_enable_utf8'} = 1;
	$SQL_CONNEXION->do('SET NAMES utf8');
	return $SQL_CONNEXION ;
}

1;
