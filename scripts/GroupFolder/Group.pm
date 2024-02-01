package Group;
use strict;
use utf8;
use MyLogger;
use util;
use Data::Dumper;
use Unicode::Normalize;

sub new {
	my ($class, $gid, $displayname) = @_;
	my $self = {
		GID => $gid,
		NAME => $displayname,
	};
	return bless $self, $class;
}
§PARAM name;
§PARAM gid;

my %groupInBase;


sub readNC {
	my $class = shift;
	my $etab = shift;

	§DEBUG "->readNC ", Dumper($etab);
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
	§TRACE Dumper($res);
}



sub getOrCreateGroup {
	my ($class, $name, $etab, $suffixGroup) = @_;
	
	my $gid = NFKD($name . $suffixGroup);
	$gid =~ s/\p{NonspacingMark}//g; #suppression des accents

	unless (scalar %{$etab->groupsNC()}) {
		Group->readNC($etab);
	}
	my $inEtab = 0;
	
	my $group = $etab->groupsNC->{$gid};
	if ($group) {
		$inEtab = 1;
	} else {
		$group = $groupInBase{$gid};
		unless ($group) {
			$group = $groupInBase{$name};
		}
	}

	if ($group) {
		if ($group->name() ne $name) {
			util->executeSql(q/update IGNORE oc_groups set displayname = ? where gid = ?/, $name, $gid);
			$group->name($name);
		}
	}
	
	unless ($group) {
		$group = Group->new($gid, $name);
		util->occ("group:add --display-name '$name' '$gid'");
		$groupInBase{$gid} = $group;
		§DEBUG "new group " , Dumper($group);
	}

	if ($etab && !$inEtab) {
			# le ignore dans le cas ou le group prexistait (l'insert termine alors normalement).
		util->executeSql(q/insert IGNORE into oc_asso_uai_user_group (id_etablissement, user_group) values (?, ?)/, $etab->idBase, $gid);
		$etab->groupsNC->{$gid} = $group;
	}

	return $group;
}

1;
