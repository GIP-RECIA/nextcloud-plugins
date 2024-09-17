use DBI;
use MyLogger;
#use Filter::sh "tee " . __FILE__ . ".pl"; # pour  debuger les macros


package util;
BEGIN {
        use Exporter   ();
		@EXPORT_OK   = qw(%PARAM);
    }
use vars      @EXPORT_OK;
use strict;
use utf8;
use Cwd;


my $logRep = $ENV{'NC_LOG'};
my $wwwRep = $ENV{'NC_WWW'};



$wwwRep = $ENV{'HOME'}.'/web' unless $wwwRep ;
$logRep = $ENV{'HOME'} . '/logs-esco' unless $logRep ;

my $scriptRep = $ENV{'NC_SCRIPTS'};
unless ($scriptRep) {
	$scriptRep = $ENV{'HOME'}. "/scripts";
}


my $occ = "php $wwwRep/occ ";

my $configFile = "$wwwRep/config/config.php";

my $dir = getcwd;
#chdir;
our %PARAM;

$PARAM{'NC_LOG'} = $logRep;
$PARAM{'NC_WWW'} = $wwwRep;
$PARAM{'NC_SCRIPTS'} = $scriptRep;
my $defautBucket = $PARAM{'bucket'};
	
	# lecture des paramatres de conf

	open CONFIG, "$configFile" or die $!;

	while (<CONFIG>)  {
		if (/'(\w+)'\s*=>\s*'([^']+)'/) {
			$PARAM{$1} = $2;
		}
	}
$PARAM{'NC_DATA'} = $PARAM{'datadirectory'};
#package util;

my $sqlHost = $PARAM{'dbhost'};
my $sqlDatabase = $PARAM{'dbname'};
my $sqlUsr=$PARAM{'dbuser'};
my $sqlPass=$PARAM{'dbpassword'};
my $sqlDataSource = "DBI:mysql:database=$sqlDatabase;host=$sqlHost";
my $SQL_CONNEXION;

my $s3command = "/usr/bin/s3cmd ";

# les infos ldap seront récupérées dans la base nextcloud.
my $ldapHost;
my $ldapUser;
my $ldapPass;
my $ldapBaseDn;

my $readOnly = 0;
 
# permet de ne pas jouer la commande occ
sub testMode {
	$readOnly = 1;
	$occ = "echo $occ ";
}

sub isTestMode {
	return $occ =~ /^echo/; 
}

sub isObjectStore {
	return exists $PARAM{'objectstore_multibucket'} ;
}

sub newConnectSql {
	§INFO "connexion sql: $sqlDataSource, $sqlUsr\n";
	my $sql_connexion = DBI->connect($sqlDataSource, $sqlUsr, $sqlPass) || die $!;
	§INFO " OK \n";
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

my $LDAP_CONNEXION;

sub connectLdap {
	if ($LDAP_CONNEXION) {
		return $LDAP_CONNEXION;
	} 
	unless ($ldapHost && $ldapUser && $ldapPass) {
		my $sql = connectSql();
		my $sqlQuery = q(select configkey, configvalue from oc_appconfig where configkey like 'cas_import_ad%' and appid = 'ldapimporter');
		§INFO "$sqlQuery\n";
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
		$ldapBaseDn =~ s/^ou=[^,]+,//;
		$ldapHost = $proto . $host . $port;
#		$ldapHost= 'chene.srv-ent.brgm.recia.net';
	}
	§INFO "Ldap connexion: $ldapHost";
		# le parametre raw est un regex qui filtre  les attributs binaires. 
		# Les attributs qui ne verifie pas la regex seront en utf-8.
		# si on ne met rien les attribut utf-8 seront considérés comme binaire
		# et l'encodage sera incorecte.
		# Nous n'avons pas d'attribut binaire d'ou la valeur choisie qui ne doit matcher aucun attribut
	my $ldap = Net::LDAP->new($ldapHost,  async => 1, raw => '^UTF-8$' ) or §FATAL "$@";
	my $mesg ;
	$ldap->debug(0);
	
	§INFO "Ldap user: $ldapUser";
	$mesg = $ldap->bind( $ldapUser,
	                      password => $ldapPass
	                    );
	
	$mesg->code && §FATAL $mesg->error;
	
	§INFO "Ldap bind: ", $ldapUser;
	$LDAP_CONNEXION = $ldap;
	return $ldap;
}



sub executeSql {
	my $class = shift;
	my $sqlQuery = shift;
	my $sql = connectSql();
	§DEBUG[1] $sqlQuery;
	if (!isTestMode() || ( $sqlQuery =~ /^\s*select/i &&  ! ($sqlQuery =~ /into/i))) {
		my $sqlStatment =  $sql->prepare($sqlQuery) or §FATAL[1] $sql->errstr;
		§DEBUG 'execute ', join(", ", @_);
		$sqlStatment->execute(@_) or §FATAL[1]  $sqlStatment->errstr, "\n$sqlQuery \n(", join(", ", @_), ")\n";
		return $sqlStatment;
	} 
	§DEBUG "TestMode => pas de modif de base la requête aurait été executé avec :";
	§DEBUG 'execute ', join(", ", @_);
	return 0;
}

sub searchLDAP {
	my $class = shift;
	my $branch = shift;
	my $filter = shift;
	my $attrs ; #shift;
	 
	my $ldap = connectLdap();
	$branch .= ",".$ldapBaseDn;
	if (@_) {
		$attrs = [@_];
	}else {
		$attrs = ['1.1'];
	}
	my $srch = $ldap->search( base => $branch, filter => $filter , attrs => $attrs);
	$srch->code  and  §FATAL "ldap  $branch"," $filter :", $srch->error;
	return $srch->entries;
}


sub occ {
	my $class = shift;
	my $com = shift;
	my $out = shift;

	if ($out) {
		§SYSTEM[1] "$occ $com", OUT => $out;
	} else {
		§SYSTEM[1] "$occ $com" ;
	}
}

sub timestampLdap() {
	my $class = shift;
		# calcul du timestamp courant donné a la minute
	my @local = gmtime (shift);
	return sprintf '%d%02d%02d%02d%02d00' , $local[5] + 1900,  $local[4]+1, $local[3], $local[2], $local[1];
}

sub localDate {
	my @tab = localtime shift;
	$tab[5] += 1900;
	$tab[4]++;
	return @tab;
}
sub jour {
	return sprintf '%6$d%5$02d%4$02d', &localDate (time); 
}

sub toGiga {
	my $class = shift;
	my $val = shift;
	my $unit = shift;
	if ($val) {
		if (@_) {
			my $mod = $val % 1024;
			if ($mod) {
				return $class->toGiga(int($val/1024),@_) . $mod . "$unit ";
			}
			return $class->toGiga(int($val/1024),@_);
		} else {
			return $unit ? "$val$unit " : $class->toGiga($val, 'o', 'Ko', 'Mo', 'Go', 'To'); 
		}
	}
	return $unit ? "" : "0o";
}

# si $name == nc-recette-name/... => s3://nc-recette-name
# si $name != null =>  s3://nc-recette-name
# sinon  => s3://nc-recette-0
sub getBucketName {
	my $name = shift;
	unless ($name) {
		$name = "0";
	}
	if ($name =~ m{^($defautBucket([^/]*))}) {
		if ($2) {
			$name = $2;
		} else {
			$name = "0";
		}
	}
    return "s3://".$defautBucket.$name;
}

sub getObjectName {
	return "urn:oid:". shift;
}

sub lsCommande {
	return "$s3command ls ".shift;
}

1;
