
package GroupFolder;
use strict;
use utf8;
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

1;
