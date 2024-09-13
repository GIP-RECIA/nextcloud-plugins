#!/usr/bin/perl

=encoding utf8

=head1 NAME

	uidKo.pl
	analyse les fichiers de log de loadEtab.pl passé en paramètre pour en déduire les uid qui n'ont pas été traités (suite à une erreur non détectée)    

=head1 SYNOPSIS

	uidKo.pl ./0450840U.log 0450839T.log ...
	gunzip -c *.log.gz | uidKo.pl
	


=cut

use 5.026;
my %UID;
my $nbUser;
while (<>) {
	if (/Start account import from ActiveDirectory/) {
		$nbUser = 0;
	}
	if (/Ajout de l'utilisateur avec id  : (F\w{7})/) {
		$UID{$1} |= 1;
		$nbUser++;
		next;
	}
	if (/Users have been retrieved : (\d+)/) {
		my $nbAttendue = $1;
		if ($nbAttendue != $nbUser) {
			say "WARN: $nbUser / $nbAttendue comptes à traiter";
		} else {
			say "INFO $nbUser comptes à traiter";
		}
		next;
	}
	
	if (/ldap:(update|create)-user,(F\w{7})/) {
		my $uid = $2;
		while (<>) {
			if (/Enabled set to "enabled"/) {
				$UID{$uid} |= 2;
				last;
			}
			if (/Start disable deleted user/) {
				last;
			}
		}
	}
	if (/Start disable deleted user/) {
		while (<>) {
			if (/user to disabled : (F\w{7})/) {
				my $uid = $1;
				$UID{$uid} |= 4;
			}
			if (/Disabling users finished/) {
				last;
			}
		}
	}
}


while (my ($uid, $val) = each(%UID)) {
	if ($val == 1) {
		say "> $uid";
	} 
}
