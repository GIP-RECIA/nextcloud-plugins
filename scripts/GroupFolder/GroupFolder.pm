
package GroupFolder;
use strict;
use utf8;
use Symbol 'gensym';

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
	};
	bless $self, $class;
}
PARAM! idBase
PARAM! mount
PARAM! quota
PARAM! acl

sub readNC {
	my $class = shift;
	DEBUG! '->readNC';

	my $sqlRes = util->executeSql(q/select * from oc_group_folders/);
	while (my @tuple =  $sqlRes->fetchrow_array()) {
		my $folder = GroupFolder->new(@tuple);
		$folderInBase{$folder->mount()} = $folder;
	}
}

sub addGroup{
	my $this = shift;
	my $group = shift;
	# le reste sont les permissions;
	util->occ('groupfolders:group ' .  $this->idBase . " '" . $group->gid . "' " . join(" ", @_));
}

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
		if (@RES && $RES[0] =~ /^(\d+)\s*$/) {
				$folder = GroupFolder->new($1, $mountPoint, $quotaG);
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

1;
