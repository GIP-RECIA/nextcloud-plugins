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
		GROUPSNC => {}
	};
	bless $self, $class;
}

PARAM! idBase;
PARAM! name;
PARAM! uai;
PARAM! siren;
PARAM! groupsNC;

my %etabInBase;


sub readNC {
	my $class = shift;
	my $siren = shift;
	DEBUG! '->readNC $siren';

	my $etab; #TODO on return le dernier etab a modifier
	my $sqlRes = util->executeSql(q/select * from oc_etablissements where siren=?/, $siren);
	while (my @tuple =  $sqlRes->fetchrow_array()) {
		$etab = Etab->new(@tuple);
		$etabInBase{$etab->siren} = $etab;
	}
	TRACE! Dumper(%etabInBase);
	return $etab;
}

1;
