use IPC::Open3;
use IO::Select;
use Symbol 'gensym';

# 
my $version="4.0";

package MyLogger;
use Filter::Simple;

FILTER {
	s/FATAL(\d?)!/MyLogger::fatal 'FATAL: die at ', !'$1' ? (__FILE__, __LINE__) : (caller($1-1))[1,2] ,/g;
	s/ERROR(\d?)!/MyLogger::is(1) and MyLogger::erreur 'ERROR: ', !'$1' ? (__FILE__, __LINE__) : (caller($1-1))[1,2] ,/g;
	s/WARN(\d?)!/MyLogger::is(2) and MyLogger::erreur 'WARN: ',  !'$1' ? (__FILE__, __LINE__) : (caller($1-1))[1,2] ,/g;
	s/INFO(\d?)!/MyLogger::is(3) and MyLogger::info !'$1' ? (__FILE__, __LINE__) : (caller($1-1))[1,2] ,/g;
	s/DEBUG(\d?)!/MyLogger::is(4) and MyLogger::debug !'$1' ? (__FILE__, __LINE__) : (caller($1-1))[1,2] ,/g;
	s/TRACE!/MyLogger::is(5) and MyLogger::trace/g;
	s/SYSTEM(\d?)!/MyLogger::traceSystem !'$1' ? (__FILE__, __LINE__) : (caller($1-1))[1,2] ,/g;
	s/LOG!/MyLogger::file && MyLogger::logger /g;
	s/PARAM!\s*(\w+)/sub $1 {return MyLogger::param(shift, uc('$1'), shift);}/g;
};

my $level;
my $file;
my $mod;
# si mod = 0 : si on a un fichier  on ne sort sur STDOUT que les WARN ERROR et FATAL si pas de fichier on sort aussi INFO
# si mod = 1 : et on a un fichier on sort sur STDOUT les INFO aussi 
# si mod = 2 : on sort tout sur STDOUT 

sub file {
	unless (shift) {
		return $file;
	};
	if ($file) {
		close MyLoggerFile;
	}
	$file = shift;
	$file =~ s/^\>//;
	open (MyLoggerFile, ">$file" ) or die $file . " $!" ;
}


sub level {
	if (@_) {
		$level = shift;
		if (@_) {
			$mod = shift;
		} 
	} 
	return $level, $mod;
}

sub is {
	my $levelMin = shift;
	return $levelMin <= $level;
}


sub trace {
	if ($file ) {
		print MyLoggerFile "\t", @_;
	};
	if ($mod > 1) {
		print "\t", @_;
	}
}


sub logger {
	print MyLoggerFile dateHeure(), @_, "\n";
}

sub debug {
	unshift (@_, lastname (shift) . ' (', shift . '): ');
	if ($file) {
		logger 'DEBUG: ', @_;
	}
	
	if ($mod > 1) {
		print ' DEBUG: ', @_, "\n";
	}
	
}

sub info {
	my $fileName = lastname (shift) . ' (' . shift . '): ';

	if ($file) {
		logger 'INFO: ', $fileName, @_;
		if ($mod > 0) {
			print '  INFO: ', @_,"\n";
		}
	} else {
		print '  INFO: ', $fileName, @_, "\n";
	}
}

sub erreur {
	my $type = shift;
	my $fileName = lastname(shift). ' (' . shift . '): ';
	
	if ($file) {
		logger $type, $fileName, @_; 
	}
	print STDERR  '> ', $type, $fileName, @_, "\n"; 
}

sub fatal {
	erreur @_;
	close MyLoggerFile;
	exit 1;
}

sub dateHeure {
	my @local = localtime(time);
	return sprintf "%d/%02d/%02d %02d:%02d:%02d " , $local[5] + 1900,  $local[4]+1, $local[3], $local[2], $local[1], $local[0];
}

sub lastname {
	my $file = shift;
	$file =~ s/^.*\///g;
	return $file ;
}
sub traceSystem {
	my $fileName = shift;
	my $line = shift; 
	my $commande = shift;
	my $OUT = shift; #OUT peut etre vide sinon doit etre la reference d'un tableau des lignes de sortie
	my $COM;
	my $ERR = Symbol::gensym();
	my $select = new IO::Select;

	my $pid;
	eval {
	  $pid = IPC::Open3::open3(undef, $COM, $ERR, $commande) or fatal ("FATAL: ", $fileName, $line, "$commande : die: ", $! );
	};
	fatal ("FATAL: ", $fileName, $line, "$commande : die: ", $@ ) if $@;
	info ($fileName, $line, $commande);

	$select->add($COM, $ERR);

	my $flagC = 1;
	my $flagE =1;
	while (my @ready = $select->can_read) {
		foreach my $fh (@ready) {
			my $ligne;
			my $len = sysread $fh, $ligne, 4096;
			if ($len == 0){
				$select->remove($fh);
			} else {
				my $out = $ligne;
				$ligne =~ s/\n(.)/\n\t$1/mg;
				if ($fh == $COM) {
					push(@$OUT, $out) if $OUT;
					if ($flagC) {
						if ( $level >= 4) { debug ($fileName, $line, " STDOUT :"); }
						$flagC = 0;
						$flagE = 1;
					}
					if ($level >=  4) { trace($ligne); }
				} elsif ($fh == $ERR) {
					if ($flagE) {
						if ($level >= 1) { erreur ( 'trace : ', $fileName, $line, 'STDERR :'); }
						$flagC = 1;
						$flagE = 0;
					}
					if ($level >= 1) { trace($ligne) };
				}
			}
		}
	}
	waitpid $pid, 0;
	
	my $child_exit_status = $? >> 8;
	erreur ("ERROR: ", $fileName, $line,"$commande : erreur $child_exit_status") if $child_exit_status;
	close $ERR;
	close $COM;
}
sub param {
	my $self = shift;
	my $param = shift;
	my $value = shift;

 	if ($value) {
		$self->{$param} = $value;
	}
	return $self->{$param};
}
1;
