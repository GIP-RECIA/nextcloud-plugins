use IPC::Open3;
use IO::Select;
use Symbol 'gensym';

# 
my $version="2.0";

package MyLogger;
use Filter::Simple;

FILTER {
	s/FATAL!/MyLogger::fatal 'FATAL: die at ', __FILE__,' (', __LINE__,'): ',/g;
	s/ERROR!/MyLogger::is(1) and MyLogger::erreur 'ERROR: ', __FILE__,' (', __LINE__,'): ',/g;
	s/WARN!/MyLogger::is(2) and MyLogger::erreur 'WARN: ',  __FILE__,' (', __LINE__,'): ',/g;
	s/INFO!/MyLogger::is(3) and MyLogger::info __FILE__,' (', __LINE__,'): ',/g;
	s/DEBUG!/MyLogger::is(4) and MyLogger::debug __FILE__,' (', __LINE__,'): ',/g;
	s/TRACE!/MyLogger::is(5) and MyLogger::trace/g;
	s/SYSTEM!/MyLogger::traceSystem __FILE__, __LINE__,/g;
	s/PARAM!\s*(\w+)/sub \1 {return MyLogger::param(shift, uc('\1'), shift);}/g; 
};

my $level;
my $file;
my $mod;
# si mod = 0 : si on a un fichier  on ne sort sur STDIN que les WARN ERROR et FATAL si pas de fichier on sort aussi INFO
# si mod = 1 : et on a un fichier on sort sur STDIN les INFO aussi 
# si mod = 2 : on sort tout sur STDIN 

sub file {
	my $class = shift;
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

sub debug {
	push @_, "\n";
	if ($file ) {
		unshift (@_, lastname (shift));
		print MyLoggerFile dateHeure(), 'DEBUG: ', @_;
	}
	
	if ($mod > 1) {
		print ' DEBUG: ', @_;
	}
	
}

sub info {
	unshift (@_, lastname (shift));
	push @_, "\n";
	if ($file) {
		print MyLoggerFile dateHeure(), 'INFO: ', @_;
		if ($mod > 0) {
			print '  INFO: ', @_;
		}
	} else {
		print '  INFO: ', @_;
	}
}

sub erreur {
	my $type = shift;
	my $file = lastname(shift);
	
	push @_, "\n";
	if ($file) {
		print MyLoggerFile dateHeure(), $type, $file, @_; 
	}
	print STDERR  '> ', $type, $file, @_; 
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
	my $file = shift;
	my $line = shift; 
	my $commande = shift;
	my $OUT = shift; #OUT peut etre vide sinon doit etre la reference d'un tableau des lignes de sortie
	my $COM;
	my $ERR = Symbol::gensym();
	my $select = new IO::Select;

	my $pid;
	eval {
	  $pid = IPC::Open3::open3(undef, $COM, $ERR, $commande);
	};
	fatal ('FATAL: SYSTEM! die at ', $file,' (', $line,'): ', $@ ) if $@;
	
	$select->add($COM, $ERR);

	my $flagC = 1;
	my $flagE =1;
	while (my @ready = $select->can_read) {
		foreach my $fh (@ready) {
			my $line;
			my $len = sysread $fh, $line, 4096;
			if ($len == 0){
				$select->remove($fh);
			} else {
				my $out = $line;
				$line =~ s/\n(.)/\n\t$1/mg;
				if ($fh == $COM) {
					push(@$OUT, $out) if $OUT;
					if ($flagC) {
						if ( $level >= 4) { debug (' system ', $commande); }
						$flagC = 0;
						$flagE = 1;
					}
					if ($level >=  4) { trace($line); }
				} elsif ($fh == $ERR) {
					if ($flagE) {
						if ($level >= 1) { erreur ( '> ERROR',  ' system ', $commande); }
						$flagC = 1;
						$flagE = 0;
					}
					if ($level >= 1) { trace($line) };
				}
			}
		}
	}
	waitpid $pid, 0;
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
