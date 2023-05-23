#!/usr/bin/perl

use strict;

my $subject=shift;
my $from =shift;

my $isOpen;


while (<>) {
	unless ($isOpen) {
		if (/^\s*$/) {
			next;
		}
		open (MAIL, "| /usr/bin/mail -s '$subject' -r '$from' ". 'ent@recia.fr') or die $!;
		$isOpen = 1;
	}
	print MAIL $_;
}
if ($isOpen) {
	close MAIL;
}


__END__
