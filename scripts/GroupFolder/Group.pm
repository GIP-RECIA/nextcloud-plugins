package Group;
use strict;
use utf8;
use MyLogger;
use util;
use Data::Dumper;

sub new {
	my ($class, $gid, $displayname) = @_;
	my $self = {
		GID => $gid,
		NAME => $displayname,
	};
	bless $self, $class;
}
PARAM! name;
PARAM! gid;

my %groupInBase;


sub readNC {
	my $class = shift;
	my $etab = shift;

	DEBUG! "->readNC ", Dumper($etab);
	my $sqlRes;
	my $res;
	if ($etab) {
		$res = $etab->groupsNC;
		$sqlRes = util->executeSql(q/select * from oc_groups where gid in (select user_group from oc_asso_uai_user_group where id_etablissement = ?)/, $etab->idBase);
	} else {
		$res = \%groupInBase;
		$sqlRes = util->executeSql(q/select * from oc_groups/);
	}
	
	while (my @tuple =  $sqlRes->fetchrow_array()) {
		my $group = Group->new(@tuple);
		$res->{$group->gid} = $group;
	}
	TRACE! Dumper($res);
}

1;
