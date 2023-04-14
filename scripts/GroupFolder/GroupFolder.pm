package GroupFolder;
use strict;
use utf8;
use MyLogger;
use Data::Dumper;

sub createGroupAndFolder {
	my $class = shift;
	my $etabNC = shift;
	my $groupFormat = shift;
	my $folderFormat = shift;
#	my $adminFormat = shift;
	my $quotaF = shift;
	my $permF = shift;
	my @grpMatched = @_;

	my $group = Group->getOrCreateGroup(sprintf($groupFormat, @grpMatched), $etabNC);

	DEBUG! "\t\t" , Dumper($group);

	if ($folderFormat) {
		my $folder = Folder->updateOrCreateFolder(sprintf($folderFormat, @grpMatched), $quotaF);
		if ($folder) {
			$folder->addGroup($group, @$permF);
			DEBUG! "\t\t\tgroup folder ", Dumper($folder);
		}
	}

#suppression de la gestion des admin if ($adminFormat)
=pod

	if ( $adminFormat ) {
		my $folderAdmin = sprintf($adminFormat, @grpMatched);
		DEBUG! "\t\t\tgroup folder admin: ",  $folderAdmin;
		if (index($folderAdmin, '^') == 0 ) {
			my @folderList = Folder->findFolders($folderAdmin);
				foreach my $f (@folderList) {
					$f->addAdminGroup($group);
				}
		} else {
			my $folder = Folder->getFolder($folderAdmin);
			if ($folder) {
				DEBUG! "\t\t\t\tgroup folder admin add group";
				$folder->addAdminGroup($group);
			}
		} 
	}

=cut

}

sub addGroupAdminFolders {
	my $class = shift;
	my $etabNC = shift;
	my $group = shift;
	my $adminFormat = shift;
	my @grpMatched = @_;

	my $folderAdmin;
	if ( $group && $adminFormat ) {
		if (@grpMatched) {
			$folderAdmin = sprintf($adminFormat, @grpMatched);
		} else {
			$folderAdmin = $adminFormat;
		}
		DEBUG! "\t\t\tgroup folder admin: ",  $folderAdmin;
		if (index($folderAdmin, '^') == 0 ) {
			my @folderList = Folder->findFolders($folderAdmin);
				foreach my $f (@folderList) {
					$f->addAdminGroup($group);
				}
		} else {
			my $folder = Folder->getFolder($folderAdmin);
			if ($folder) {
				DEBUG! "\t\t\t\tgroup folder admin add group";
				$folder->addAdminGroup($group);
			}
		} 
	}
}

1;
