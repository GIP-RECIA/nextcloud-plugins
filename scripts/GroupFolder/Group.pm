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
		unless (%$res) {
			$sqlRes = util->executeSql(q/select * from oc_groups where gid in (select user_group from oc_asso_uai_user_group where id_etablissement = ?)/, $etab->idBase);
		}
	} else {
		unless (%$res) {
			$sqlRes = util->executeSql(q/select * from oc_groups/);
		}
	}
	if ($sqlRes) {
		while (my @tuple =  $sqlRes->fetchrow_array()) {
			my $group = Group->new(@tuple);
			$groupInBase{$group->gid} = $group;
			if ($res) {
				$res->{$group->gid} = $group;
			}
		}
	}
	TRACE! Dumper($res);
}



sub getOrCreateGroup {
	my ($class, $name, $etab) = @_;

	my $gid = $name . ':LDAP';
	
	my $group = $etab->groupsNC->{$gid};
	if  ($group) {
		return $group;
	}

	$group = $etab->groupsNC->{$name};
	if  ($group) {
		return $group;
	}

	$group = $groupInBase{$gid};
	
	unless ($group) { 
		$group = $groupInBase{$name};
	}

	unless ($group) {
		$group = Group->new($gid, $name);
		util->occ("group:add --display-name '$name' '$gid'");
		$groupInBase{$gid} = $group;

			# les groups ne sont ajouté a l'etab qu'a leurs creations du coup il ne peuvent pas être partager entre etab 
		if ($etab) {
			# le ignore dans le cas ou le group prexistait (occ termine alors normalement).
			util->executeSql(q/insert IGNORE into oc_asso_uai_user_group (id_etablissement, user_group) values (?, ?)/, $etab->idBase, $gid);
			$etab->groupsNC->{$gid} = $group;
		}
		DEBUG! "new group " , Dumper($group);
	}
	return $group;
}

1;
