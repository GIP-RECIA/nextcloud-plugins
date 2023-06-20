#!/usr/bin/perl

use strict;

my $subject=shift;
my $from =shift;

while (<>) {
	unless (/^\s*$/) {
		open (MAIL, "| /usr/bin/mail -s '$subject' -r '$from' ". 'ent@recia.fr') or die $!;
		do {
			print MAIL ;
		} while <>;
		close MAIL;
		last;
	}
}



__END__
