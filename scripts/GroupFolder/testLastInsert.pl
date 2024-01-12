#!/usr/bin/perl

use strict;
use utf8;
use FindBin;
use lib $FindBin::Bin;
use DBI();

use Data::Dumper;

use util;

util->executeSql(q/drop table recia_test_last_insert/);
util->executeSql(q/create table recia_test_last_insert ( id INT PRIMARY KEY NOT NULL AUTO_INCREMENT, name varchar(100) )/);

my $sth = util->executeSql(q/INSERT  INTO recia_test_last_insert (name) values (?)/, 'unTest');
my $id;

$id = $sth->last_insert_id();

print "$id \n";

#sleep(5);

$sth = util->executeSql(q/select * from recia_test_last_insert where id = ? /, $id);

while (my @tuple =  $sth->fetchrow_array()) {
			print join "\t", @tuple, "\n";
		}
