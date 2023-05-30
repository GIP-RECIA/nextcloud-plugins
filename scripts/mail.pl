#!/usr/bin/perl

use strict;

my $subject=shift;
my $from =shift;

my $isOpen;


while (<>) {
	if (/^\s*$/) {
		next;
	}
	open (MAIL, "| /usr/bin/mail -s '$subject' -r '$from' ". 'ent@recia.fr') or die $!;
	$isOpen = 1;
	print MAIL $_;
}

if ($isOpen) {
	while (<>) {print MAIL $_ ;}
	close MAIL;
}


__END__
/var/www/ncgip.recia/scripts/mail.pl 'cron loadGroupFolder' 'ncgip@aquaray.com'
/var/www/ncprod.recia/scripts/mail.pl 'cron loadGroupFolder' 'ncprod@aquaray.com'
