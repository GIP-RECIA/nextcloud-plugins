package Etab;
use strict;
use utf8;
use MyLogger;
use util;
use Data::Dumper;

sub new {
	my ($class, $idBase, $name, $uai, $siren) = @_;
	my $self = {
		IDBASE => $idBase,
		NAME => $name,
		UAI => $uai,
		SIREN => $siren,
		TIMESTAMP => 0,
		GROUPSNC => {}
	};
	bless $self, $class;
}

PARAM! idBase;
PARAM! name;
PARAM! uai;
PARAM! siren;
PARAM! groupsNC;
PARAM! timestamp;

my %etabInBase;

sub addEtab {
	my $class = shift;
	my $siren = shift;
	my $name = shift;

	DEBUG! "addEtab, siren : $siren  , name : $name";
	my $etab;
		# avec le ignore il n'y a pas d'erreur en cas de préexistance
	my $sth = util->executeSql(q/INSERT IGNORE INTO oc_etablissements (siren, name) values (?, ?)/, $siren, $name);
	my $id = $sth->last_insert_id();
	if ($id) {
		$etab = Etab->new($id, $name, undef, $siren);
	} else {
		$sth = util->executeSql(q/select id, name  from  oc_etablissements where siren = ?/, $siren);
		
		($id, my $nameInBase)   =  $sth->fetchrow_array();

		if ($name ne $nameInBase) {
			WARN! "Etab avec 2 noms $siren, $name, $nameInBase.";
		}
		$etab = Etab->new($id, $name, undef, $siren);
	}
	
	$etabInBase{$siren} = $etab;
	return $etab;
}

sub getEtab{
	my $class = shift;
	my $siren = shift;
	return $etabInBase{$siren};
}

sub readNC {
	my $class = shift;
	my $siren = shift;
	DEBUG! '->readNC $siren';
	
	my $etab = $etabInBase{$siren};

	unless ($etab) {
		my $sqlRes = util->executeSql(q/select * from oc_etablissements where siren=?/, $siren);
		while (my @tuple =  $sqlRes->fetchrow_array()) {
			$etab = Etab->new(@tuple);
			$etabInBase{$etab->siren} = $etab;
			last;
		}
	}
	TRACE! Dumper(%etabInBase);
	return $etab;
}

sub release{
	my $etab = shift;
	delete $etabInBase{$etab->siren};
}
sub next{
	my ($siren, $etab) = each %etabInBase;
	return $etab;
}

1;
