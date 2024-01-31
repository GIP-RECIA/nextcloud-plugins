use MyLogger;
#use Filter::sh "tee " . __FILE__ . ".pl"; # pour  debuger les macros

package GroupFolder;
use strict;
use utf8;
use Data::Dumper;

sub addGroup4AdminFolder {
	my $class = shift;
	my $etabNC = shift;
	my $groupNC = shift;
	my $adminFormat = shift;
	my @grpMatched = @_;

	if ($adminFormat) {
		my $folderAdmin = sprintf($adminFormat, @grpMatched);
		§DEBUG "\t\t\tgroup folder admin: ",  $folderAdmin;
		if (index($folderAdmin, '^') == 0 ) {
			my @folderList = Folder->findFolders($folderAdmin);
				foreach my $f (@folderList) {
					$f->addAdminGroup($groupNC);
				}
		} else {
			my $folder = Folder->getFolder($folderAdmin);
			if ($folder) {
				§DEBUG "\t\t\t\tgroup folder admin add group";
				$folder->addAdminGroup($groupNC);
			}
		} 
	}
}

my $isForceQuota = 0;
sub forceQuota{
	$isForceQuota = shift;
}


sub createFolder4Group {
	my $class = shift;
	my $etabNC = shift;
	my $folderFormat = shift;
	my $quotaF = shift;
	my $permF = shift;
	my $groupNC = shift;
	my @grpMatched = @_;

	if ($groupNC) {
		if ($folderFormat) {
			my $folder = Folder->updateOrCreateFolder(sprintf($folderFormat, @grpMatched), $quotaF, $isForceQuota);
			if ($folder) {
				$folder->addGroup($groupNC, @$permF);
				§DEBUG "\t\t\tgroup folder ", Dumper($folder);
			}
		}
	}
	
}

1;
