#!/usr/bin/perl

use strict;

my $subject=shift;
my $from =shift;

while (<>) {
	next if /^libpng warning/;
	unless (/^\s*$/) {
		open (MAIL, "| /usr/bin/mail -s '$subject' -r '$from' ". 'ent@recia.fr') or die $!;
		do {
			next if /^libpng warning/;
			print MAIL ;
		} while <>;
		close MAIL;
		last;
	}
}

__END__
