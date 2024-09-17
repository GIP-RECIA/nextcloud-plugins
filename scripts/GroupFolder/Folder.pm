use MyLogger ; #'DEBUG';
#use Filter::sh "tee " . __FILE__ . ".pl"; # pour  debuger les macros

package Folder;
use strict;
use utf8;
#use Symbol 'gensym';

use util;
use Data::Dumper;

my %folderInBase;
my %folderById;

sub new {
	my ($class, $idBase, $mount, $quotaOct, $acl) = @_;
	my $self = {
		IDBASE => $idBase,
		MOUNT => $mount,
		QUOTA => $quotaOct,
		ACL => $acl,
		MANAGE_NEW => {},
		MANAGE_OLD => {},
		GROUPS_OLD => {},
		GROUPS_NEW => {}
	};
	$folderById{$idBase} = $self;
	bless $self, $class;
}
§PARAM idBase
§PARAM mount
§PARAM quota	#en octet
§PARAM acl


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
		$val = $new->{$key};
		unless ($val) {
			$val = $old->{$key};
		}
		return $val;
	}
	return 0;
}
sub groups {
	my $this = shift;
	return dictOldNew($this->{GROUPS_OLD}, $this->{GROUPS_NEW}, @_)
}

sub manages {
	my $this = shift;
	return dictOldNew($this->{MANAGE_OLD}, $this->{MANAGE_NEW}, @_)
}


sub readNC {
	my $class = shift;
	§DEBUG '->readNC';

	#TODO select f.folder_id, mount_point, quota, acl, permissions, group_id  from oc_group_folders f, oc_group_folders_groups g where f.folder_id = g.folder_id; 
	my $sqlRes = util->executeSql(q/select * from oc_group_folders/);
	while (my @tuple =  $sqlRes->fetchrow_array()) {
		my $folder = $class->new(@tuple);
		$folderInBase{$folder->mount()} = $folder;
	}

	$sqlRes = util->executeSql(q/select folder_id, group_id, permissions from oc_group_folders_groups where group_id like '%:LDAP'/);
	while (my @tuple = $sqlRes->fetchrow_array()) {
		my $folder = $folderById{$tuple[0]};
		if ($folder) {
			§DEBUG Dumper($folder);
			$folder->{GROUPS_OLD}->{$tuple[1]} = $tuple[2];
		} else {
			§WARN 'Dans oc_group_folders_groups le groupe '. $tuple[1] . ' est associé un folder_id inexistant : '.  $tuple[0];
		}
	}
	 
	$sqlRes = util->executeSql(q/select folder_id, mapping_id from oc_group_folders_manage where mapping_type ='group'/);
	while (my @tuple =  $sqlRes->fetchrow_array()) {
		my $folder = $folderById{$tuple[0]};
		if ($folder) {
			$folder->{MANAGE_OLD}->{$tuple[1]} = 1;
		} else {
			§WARN 'Dans oc_group_folders_manage le groupe '. $tuple[1] . ' manage le folder_id inexistant '. $tuple[0];
		}
	}
	return \%folderById;
}

my %permsGroup = (read => 1, update => 2, create => 4, write => 6, 'delete' => 8, share => 16 );

sub addGroup {
	my $this = shift;
	my $group = shift;
	# le reste sont les permissions;
	my $perms = 1;
	map {$perms |= $permsGroup{$_} ;} @_;
	util->occ('groupfolders:group ' .  $this->idBase . " '" . $group->gid . "' " . join(" ", @_));
	§DEBUG "permisions = $perms";
	$this->groups($group->gid, $perms);
}

sub delGroup {
	my $this = shift;
	my $groupId = shift;

	util->occ('groupfolders:group --delete ' .  $this->idBase . " '" . $groupId . "'");

}

sub getFolder {
	my ($class, $mountPoint) = @_;
	my $folder = $folderInBase{$mountPoint};

	if ($folder) {
		return $folder;
	}
	§WARN "folder $mountPoint n'existe pas";
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
	my ($class, $mountPoint, $quotaG, $forceQuota) = @_;
	my $folder = $folderInBase{$mountPoint};
	my $sqlRequete;


	my $quotaO = $quotaG * (1024 ** 3);
	if ($folder) {
		if ($quotaG && ($quotaO > $folder->quota || ($forceQuota && $quotaO < $folder->quota))) {
			$folder->quota($quotaO);
			util->occ('groupfolders:quota ' . $folder->idBase . ' ' . $quotaG .'G');
		}
		return $folder
	}
	my @RES;
	if ($quotaG) {
		util->occ("groupfolders:create '$mountPoint'", \@RES);
		if (util->isTestMode) {
			unshift @RES, '000' . $pseudoIdFolder++;
		}
		if (@RES && $RES[0] =~ /^(\d+)\s*$/ ) {
			$folder = $class->new($1, $mountPoint, $quotaO);
			$folderInBase{$mountPoint} = $folder;
			util->occ('groupfolders:quota ' . $folder->idBase . ' ' . $quotaG .'G');
		} else {
			§FATAL "erreur de creation du folder : $mountPoint";
		}
	} else {
		§INFO "folder $mountPoint non créé quota null !";
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

	unless ($folder->manages($group->gid)) {
		util->occ('groupfolders:permissions ' . $folder->idBase . " --manage-add  --group '" . $group->gid . "'");
	}
	# on ajoute dans manages même s'il existe déjà pour en avoir une liste complète
	$folder->manages($group->gid, 1);

	$folder->addGroup($group, 'write','share','delete');
}

sub delAdminGroup {
	my ($folder, $groupId) = @_;
	if ($groupId) {
		util->occ('groupfolders:permissions ' . $folder->idBase . " --manage-remove  --group '" . $groupId . "'");
	}
}



sub cleanFolder {
	my $this = shift;

	foreach  my $groupId (keys %{$this->{GROUPS_OLD}}) {
		unless ($this->{GROUPS_NEW}->{$groupId}) {
			$this->delGroup($groupId);
			$this->{GROUPS_OLD}->{$groupId} = 0;
		}
	}
	foreach my $groupId (keys %{$this->{MANAGE_OLD}}) {
		unless ($this->{MANAGE_NEW}->{$groupId}) {
			$this->delAdminGroup($groupId);
			$this->{MANAGE_OLD}->{$groupId} = 0;
		}
	}
}

sub cleanAllFolder {
	my $class = shift;
	# verifications de quota de folder par rapport au disque
	# on recupere les size  en base:
	my %Size;
	if (util->isObjectStore) {
		my $sqlRes = util->executeSql(q"select name, size from oc_filecache where path like '__groupfolders/%' and path = concat('__groupfolders/', name)") ;
		while (my ($name, $size) =  $sqlRes->fetchrow_array()) {
			$Size{$name} = $size;
		}
		# on recupere la place occupée sur le disque:
		my $repGF =  ${util::PARAM}{'NC_DATA'} . "/__groupfolders/";
		§SYSTEM "du -b -d1 $repGF", OUT => sub {
			if (/^(\d+)\s+$repGF(\d+)$/o) {
				my $idFolder = $2;
				my $size = $1;
				my $folder = $folderById{$idFolder};
				if ($folder) {
					my $pourcentQuota = int 100 * $size / $folder->quota;
					if ($pourcentQuota > 80 ) {
						§WARN 'le groupfolder '.  $folder->mount() . ' a atteind '. $pourcentQuota . '% de son quota (' .  util->toGiga($size) . '/' . util->toGiga($folder->quota)  . ' )';
					}
					if (abs ($Size{$idFolder} - $size) > (1024 ** 2) ) {
						§WARN 'le groupfolder '.  $folder->mount() . "($idFolder) a une taille NC (". util->toGiga($Size{$idFolder}) . ") différente de sa taille réélle (". util->toGiga($size) . ")"; 
					}
				} else {
					print "no folder\n";
					§WARN "Répertoire $idFolder correspondant a aucun  GroupFolder ";
				}
			}
		};
	}
	# suppresion des groupes inutiles dans les folders
	# map {$_->cleanFolder} values(%folderInBase);

	foreach (values %folderInBase) { $_->cleanFolder }
}


sub diffBaseDisque {
	my $folder = shift;
	my $repData = ${util::PARAM}{'NC_DATA'};
	my %pathInBase;
	my @pathNotInBase;
	my @pathNotInObject;
	
	my $fid = $folder->idBase;
	my $folderPath = "__groupfolders/$fid";

	my $isStockageObject = util->isObjectStore;
	
	my $sqlRes = util->executeSql(q"
			with recursive repertoires as (
				select fileid from  oc_filecache where path = ? and storage = 1
				union
				select f.fileid  from  oc_filecache f, repertoires r where f.mimetype = 4 and f.parent = r.fileId 
			) select f.fileid, f.path, f.mimetype from oc_filecache f, repertoires r where r.fileid = f.parent
		", $folderPath);

	while (my ($fileid, $path, $mimetype) =  $sqlRes->fetchrow_array()) {
		unless ($isStockageObject && $mimetype eq 4) {
			$pathInBase{$path} = $fileid;
		}
	}
	
	if ($isStockageObject) {
		my $s3command = util->infoCommande(util->getBucketName());
		my %pathInObject;
		while (my ($path, $fileid) = each %pathInBase) {
			§SYSTEM "$s3command/". util->getObjectName($fileid), OUT => sub { $pathInObject{$path} = $fileid if /\:$fileid\ \(object\):$/ };
		}
		for my $path (keys %pathInBase) {
			#§DEBUG "$path";
			unless (exists $pathInObject{$path}) {
				push @pathNotInObject, $path;
			}
		}
		return ([],  [sort @pathNotInObject], [sort keys %pathInBase]);
	} else {
		§SYSTEM "cd $repData; find '$folderPath'",
			OUT => sub{
					chop $_;
					#§DEBUG "|$_|";
					if (exists $pathInBase{$_}) {
						delete $pathInBase{$_};
						#§DEBUG "$_ : in base";
					} else {
						if ($_ ne $folderPath) {
							push @pathNotInBase, $_;
							#§DEBUG "$_ : NOT IN base";
						}
					}
				};
		return ([sort @pathNotInBase], [sort keys %pathInBase], []);
	}
}
1;

__END__

groupfolders:group [-d|--delete] [--output [OUTPUT]] [--] <folder_id> <group> [<permissions>...]

occ groupfolders:permissions <folder_id> --enable
groupfolders:permissions [-e|--enable] [-d|--disable] [-m|--manage-add] [-r|--manage-remove] [-u|--user USER] [-g|--group GROUP] [-t|--test] [--output [OUTPUT]] [--] <folder_id> [<path> [<permissions>...]]
<folder_id> [[-m|--manage-add] | [-r|--manage-remove]] [[-u|--user <user_id>] | [-g|--group <group_id>]].


with recursive fileInfolder as (
	select fileid, storage, path, name from  oc_filecache where path = '__groupfolders/79'
	union
	select f.fileid, f.storage, f.path, f.name from  oc_filecache f, fileInfolder ff where f.parent = ff.fileId
) select * from fileInfolder;

with recursive repertoires as (
	select fileid from  oc_filecache where path = '__groupfolders' and storage = 1
	union
	select f.fileid  from  oc_filecache f, repertoires r where f.mimetype = 4 and f.parent = r.fileId 
) select f.* from oc_filecache f, repertoires r where r.fileid = f.parent  ;


| oc_group_folders            |
| oc_group_folders_acl        |
| oc_group_folders_groups     |
| oc_group_folders_manage     |
| oc_group_folders_trash      |
| oc_group_folders_versions   |
