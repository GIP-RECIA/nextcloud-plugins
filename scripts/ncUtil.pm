# fait la lecture de parametre depuis config.php
# donne une connection a la base
# place l'execution dans le HOME de l'utilisateur
use Net::LDAP;

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

my @share_type = qw(user group usergroup link email contact remote circle gues remote_group room userroom deck deck_user);

my @share_status = qw(pending accepted rejected);

sub partageType {
	return $share_type[shift];
}

sub partageStatus {
	return $share_status[shift];
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

# les infos ldap seront récupérées dans la base nextcloud.
my $ldapHost;
my $ldapUser;
my $ldapPass;
my $ldapBaseDn;
my $ldapPort = ':389';
my $lapProto = 'ldap//';

my $LDAP_CONNEXION;

sub connectLdap {
		# $newHost est utile si on veux se connecter à un réplicat déterminé
		# le reste de la conf reste celle de NC en base.
	my $newHost = shift;

	if ($LDAP_CONNEXION) {
		unless ($newHost) {
			return $LDAP_CONNEXION;
		}
		$LDAP_CONNEXION->unbind; 
	}
	
	unless ($ldapHost && $ldapUser && $ldapPass) {
		my $sql = connectSql();
		my $sqlQuery = q(select configkey, configvalue from oc_appconfig where configkey like 'cas_import_ad%' and appid = 'ldapimporter');
		print  "$sqlQuery\n";
		my $sqlStatement = $sql->prepare($sqlQuery) or die $sql->errstr;
		$sqlStatement->execute() or die $sqlStatement->errstr;

		my $host = 'localhost';
		
		
		while (my @tuple =  $sqlStatement->fetchrow_array()) {
			if ($tuple[0] eq 'cas_import_ad_base_dn') {
				$ldapBaseDn = $tuple[1];
			} elsif ($tuple[0] eq 'cas_import_ad_host') {
				$host = $tuple[1];
			} elsif ($tuple[0] eq 'cas_import_ad_password') {
				$ldapPass = $tuple[1];
			} elsif ($tuple[0] eq 'cas_import_ad_port') {
				$ldapPort = ':' . $tuple[1];
			} elsif ($tuple[0] eq 'cas_import_ad_user') {
				$ldapUser = $tuple[1];
			} elsif ($tuple[0] eq 'cas_import_ad_protocol') {
				$ldapProto = $tuple[1];
			}
		}
		$ldapBaseDn =~ s/^ou=[^,]+,//;
		$ldapHost = $ldapProto . $host . $ldapPort;
		$PARAM{'ldapHost'} = $host;
#		$ldapHost= 'chene.srv-ent.brgm.recia.net';
	}
	if  ($newHost) {
		$newHost = $ldapProto . $newHost . $ldapPort;
	} else {
		$newHost = $ldapHost;
	}
	print "Ldap connexion: $newHost\n";
		# le parametre raw est un regex qui filtre  les attributs binaires. 
		# Les attributs qui ne verifie pas la regex seront en utf-8.
		# si on ne met rien les attribut utf-8 seront considérés comme binaire
		# et l'encodage sera incorecte.
		# Nous n'avons pas d'attribut binaire d'ou la valeur choisie qui ne doit matcher aucun attribut
	my $ldap = Net::LDAP->new($newHost,  async => 1, raw => '^UTF-8$' ) or die "$@";
	my $mesg ;
	$ldap->debug(0);
	
	print "Ldap user: $ldapUser\n";
	$mesg = $ldap->bind( $ldapUser,
	                      password => $ldapPass
	                    );
	
	$mesg->code && die $mesg->error;
	
	print "Ldap bind: ", $ldapUser , "\n";
	$LDAP_CONNEXION = $ldap;
	return $ldap;
}

# fait une recherche ldap : si le branche est vide recherche dans tout et si le filtre est vide aussi ramene l'element racine uniquement
sub searchLDAP {
	my $branch = shift;
	my $filter = shift;
	my $attrs ; #shift;
	 
	my $ldap = connectLdap();
	if ($branch) {
		$branch .= ",".$ldapBaseDn;
	} else {
		$branch = $ldapBaseDn;
		unless ($filter) {
			if ($ldapBaseDn =~ /^([^,]+)/) {
				$filter = "$1";
			}
		}
	}
	if (@_) {
		$attrs = [@_];
	}else {
		$attrs = ['1.1'];
	}
	my $srch = $ldap->search( base => $branch, filter => $filter , attrs => $attrs);
	$srch->code  and  die "ldap  $branch"," $filter :", $srch->error;
	return $srch->entries;
}

1;
