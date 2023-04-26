
package Folder;
use strict;
use utf8;
#use Symbol 'gensym';

use MyLogger;
use util;
use Data::Dumper;

my %folderInBase;

sub new {
	my ($class, $idBase, $mount, $quota, $acl) = @_;
	my $self = {
		IDBASE => $idBase,
		MOUNT => $mount,
		QUOTA => $quota,
		ACL => $acl,
		MANAGE_NEW => {},
		MANAGE_OLD = > {},
		GROUPS_OLD => {},
		GROUPS_NEW => {}
	};
	bless $self, $class;
}
PARAM! idBase
PARAM! mount
PARAM! quota
PARAM! acl


sub dictOldNew {
	my $old = shift;
	my $new = shift;
	my $key = shift;
	my $val = shift;

	if ($key) {
		if ($val) {
			$new->{$key} = $val;
			return $val;
		}
		$val = $new->{$gid};
		unless ($val) {
			$val = $old->{$gid};
		}
		return $val;
	}
	return 0;
}
sub groups {
	my $this = shift;
	return dictOldNew($this->GROUPS_OLD, $this->GROUPS_NEW, @_)
}

sub manages {
	my $this = shift;
	return dictOldNew($this->MANAGE_OLD, $this->MANAGE_NEW, @_)
}


sub readNC {
	my $class = shift;
	DEBUG! '->readNC';

	my %folderById;
	#TODO select f.folder_id, mount_point, quota, acl, permissions, group_id  from oc_group_folders f, oc_group_folders_groups g where f.folder_id = g.folder_id; 
	my $sqlRes = util->executeSql(q/select * from oc_group_folders/);
	while (my @tuple =  $sqlRes->fetchrow_array()) {
		my $folder = $class->new(@tuple);
		$folderInBase{$folder->mount()} = $folder;
		$folderById{$folder->idBase} = $folder;
	}

	$sqlRes = util->executeSql(q/select folder_id, group_id, permissions from oc_group_folders_groups where group_id like '%:LDAP'/);
	while (my @tuple = $sqlRes->fetchrow_array()) {
		my $folder = $folderById{$tuple[0]};
		if ($folder) {
			$folder->GROUPS_OLD->{$tuple[1]} = $tuple[2];
		} else {
			WARN! 'Dans oc_group_folders_groups folder_id (' . $tuple[0] . ') sans folder associé ';
		}
	}
	 
	$sqlRes = util->executeSql(q/select folder_id, mapping_id from oc_group_folders_manage where mapping_type ='group'/);
	while (my @tuple =  $sqlRes->fetchrow_array()) {
		my $folder = $folderById{$tuple[0]};
		if ($folder) {
			$folder->MANAGE_OLD->{$tuple[1]} = 1;
		} else {
			WARN! 'Dans oc_group_folders_manage folder_id (' . $tuple[0] . ') sans folder associé ';
		}
	}
}

sub addGroup{
	my $this = shift;
	my $group = shift;
	# le reste sont les permissions;
	util->occ('groupfolders:group ' .  $this->idBase . " '" . $group->gid . "' " . join(" ", @_));
}


sub getFolder {
	my ($class, $mountPoint) = @_;
	my $folder = $folderInBase{$mountPoint};

	if ($folder) {
		return $folder;
	}
	WARN! "folder $mountPoint n'existe pas";
	return 0;
}
sub findFolders {
	my ($class, $pattern) =@_;
	my @folders;
	while (my ($mountpoint, $folder) = each %folderInBase ) {
		if ($mountpoint =~ /$pattern/) {
			push @folders, $folder;
		}
	}
	return @folders;
}

my $pseudoIdFolder = 1;
sub updateOrCreateFolder {
	my ($class, $mountPoint, $quota) = @_;
	my $folder = $folderInBase{$mountPoint};
	my $sqlRequete;


	my $quotaG = $quota * 1024 * 1024 * 1024;
	if ($folder) {
		if ($quota && $quotaG != $folder->quota) {
			$folder->quota($quota);
			util->occ('groupfolders:quota ' . $folder->idBase . ' ' . $quota .'G');
		}
		return $folder
	}
	my @RES;
	if ($quota) {
		util->occ("groupfolders:create '$mountPoint'", \@RES);
		if (util->isTestMode) {
			unshift @RES, '000' . $pseudoIdFolder++;
		}
		if (@RES && $RES[0] =~ /^(\d+)\s*$/ ) {
			$folder = $class->new($1, $mountPoint, $quotaG);
			$folderInBase{$mountPoint} = $folder;
			util->occ('groupfolders:quota ' . $folder->idBase . ' ' . $quota .'G');
		} else {
			FATAL! "erreur de creation du folder : $mountPoint";
		}
	} else {
		INFO! "folder $mountPoint non créé quota null!";
		return 0;
	}
	return $folder;
}

sub addAdminGroup {
	my ($folder, $group) = @_;

	unless ($folder->acl > 0) {
		util->occ('groupfolders:permissions ' . $folder->idBase . ' --enable');
		$folder->acl(1);
	}

	unless ($folder->manage->{$group->gid}) {
		util->occ('groupfolders:permissions ' . $folder->idBase . " --manage-add  --group '" . $group->gid . "'");
		$folder->manage->{$group->gid} = 1;
	}

	$folder->addGroup($group, 'write','share','delete');
}
1;
__END__

groupfolders:group [-d|--delete] [--output [OUTPUT]] [--] <folder_id> <group> [<permissions>...]

occ groupfolders:permissions <folder_id> --enable
groupfolders:permissions [-e|--enable] [-d|--disable] [-m|--manage-add] [-r|--manage-remove] [-u|--user USER] [-g|--group GROUP] [-t|--test] [--output [OUTPUT]] [--] <folder_id> [<path> [<permissions>...]]
<folder_id> [[-m|--manage-add] | [-r|--manage-remove]] [[-u|--user <user_id>] | [-g|--group <group_id>]].
