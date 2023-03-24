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



sub getOrCreateGroup {
	my ($class, $name, $etab) = @_;
	my $group = $groupInBase{$name};
	if  ($group) {
		return $group;
	}
	
	my $gid = $name . ':LDAP';
	
	$group = $groupInBase{$gid};
	if ($group) {
		return $group;
	}
	$group = Group->new($gid, $name);
	util->occ("group:add --display-name '$name' '$gid'");
	if ($etab) {
		# le ignore dans le cas ou le group prexistait (occ termine alors normalement).
		util->executeSql(q/insert IGNORE into oc_asso_uai_user_group (id_etablissement, user_group) values (?, ?)/, $etab->idBase, $gid);
	}
	$groupInBase{$gid} = $group;
	DEBUG! "new group " , Dumper($group);
	return $group;
}

1;
