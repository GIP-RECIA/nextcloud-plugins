
=encoding utf8

=pod

	Une lib qui implémente un logger minimal pour des scripts perl pour gérer les mêmes logs sur la sortie erreurs et dans un fichier (avec des niveaux adaptés) sans quasiment de conf.
	Comme tout est basé sur des macros (voir Filter::Simple de perl), j'ai ajouté quelque macros qui simplifient la gestion des paramètres objets qui n'a rien à voir avec les logs et qui devrait être dans une lib séparé...
	Toutes les macros commencent par § ce qui évite une confusion avec les termes perl normaux.
	Le paramétrage des logs
	
	use MyLogger [(DEBUG|TRACE)];   si DEBUG ou TRACE sont en paramètre les loggers commentés correspondants seront décommantés ie #§DEBUG et #§TRACE seront réécrits en §DEBUG ou §TRACE
	
	MyLogger->file(filename [, autoflush]); définit le fichier de log, si autoflush=true alors les logs seront écrits (flush) à chaque fois immédiatement.
	MyLogger->level(); retourne le level et mode utilisé.
	MyLogger->level(level); fix le niveau de log :
		0 FATAL,
		1 ERROR,
		2 WARN,
		3 INFO,
		4 DEBUG,
		5 TRACE.
	MyLogger->level(level, mod); fix le niveau et ce qui sort sur STDERR si on a un fichier de log:
		mod = 0 => on ne sort rien
		mod = 1 => on sort les FATAL, ERROR et WARN 
		mod = 2 => on sort aussi les INFO
		mod = 3 => on sort en plus les DEBUG et TRACE
		si l'on n'a pas de fichier de log, mod ne sert pas, tout va sur STDERR.

	Tous les loggers affiche l'heure, le fichier et la ligne sauf §TRACE .
	Si le nom du logger est suivi d'un chiffre entre crochets [n] ; il affichera le fichier et la ligne de la énième procédure appelante dans la trace d'exécution, utile dans une lib pour indiquer l'erreur dans la procédure appelante et pas dans la lib.

	Le logger §LOG écrit dans le fichier de log sans condition de niveau, si pas de fichier ne fait rien.
	
	Exemples : les macros seront remplacées par le code ad hoc les arguments suivants resteront tels quel à la suite, donc ne pas mettre de () et finir par; le 1er argument est obligatoire ;
	§DEBUG "un message ", "de debug" ;
	open ('myfile') or §FATAL "erreur de lecture du fichier ", 'myfile ' , $!; # §FATAL termine le processus (die).
	§INFO " myfile ouvert en lecture ! " ;

	§WARN[1] "paramètre vide " unless ($param) ; # la ligne et le fichier seront sur l'appel de la fonction qui contient ce code.

	§LOG "une info pour le fichier de log ", " seulement" ;

	§PRINT "ecrit dans STDOUT comme print et dans le fichier de log comme §INFO"; 

	§SYSTEM est une macro pour logger les appels système ie stderr et stdin seront logger en fonction du niveau fixé.
	Exemple:
	§SYSTEM "tar -czf monfichier.tgz monrep";
		# exécute la commande tar et met les erreurs dans  le fichier de log ou stderr suivant le niveau et le mode

	Les dernier parametres  facultatif (syntaxe des hash): OUT, ERR, MOD
	Si on veut traiter les sorties de la commande ou peut passer des closure dans les parametres OUT ou ERR,
	$_ donne chaque ligne renvoyée par la commande.
	Exemple:
	§SYSTEM "tar -cvzf monfichier.tgz monrep", OUT => sub {print $_;}, ERR => sub { $nbErr++ ; $lastErr = $_}, MOD => 0;
				# OUT affiche la sortie du tar dans STDIN, tout en loggant dans le fichier de log ;
				# ERR compte le nombre d'erreurs et mémorise la dernière.
				# MOD change le mod du logger dans SYSTEM, avec 0 on affiche rien dans STDERR, on ne log que dans le fichier.

	Dans OUT et ERR, au lieux de closure on peut mettre la réference à un tableaux qui contiendra les lignes produites par la commande:
	exemple:
	§SYSTEM "tar -cvzf monfichier.tgz monrep", OUT => \@sortieTar, MOD => 1;
		# @sortieTar contiendra les sorties STDOUT produites par la commande;
		# MOD 1 donne dans  STDERR les FATAL, ERROR et WARN .

	Si la commande ne peut pas se lancer un §FATAL est exécuté et le programme finit.

=cut





use strict;
use IPC::Open3;
use IO::Select;
use IO::Handle;
use Symbol 'gensym';
#use Hash::Util::FieldHash;
# 
my $version="9.3.2";

package MyLogger;
use Filter::Simple;
use Encode qw(decode);

my $isDebug;

sub import {
	$isDebug = $_[1] ? $_[1] : 0;
}

#######################################################################
# les filtres
#
FILTER {
	
	if ($isDebug eq 'TRACE') {
		s/\#§(TRACE|DEBUG)\b/rewrite4log('#'.$1)/ge;
	} elsif ($isDebug eq 'DEBUG') {
		s/\#§DEBUG\b/rewrite4log('#DEBUG')/ge;
	}

	s/§(FATAL|ERROR|WARN|INFO|DEBUG|TRACE|SYSTEM|PRINT|LOG)\b(\*?)(?:\s*\[(\d+)\])?(?:\s*\[(\$\w+)])?(?:\s*\[([^\]]+)\])?/rewrite4log($1, $2, $3, $4, $5)/ge;

	my $out;
	my $nbParam = -1;
	my $isArray = 0;
	my $paramIdx = '';
	for (split /(?<=\n)/) {
		if (s/^(\s*)(\§?)\bpackage\b/$1package/) {
			$nbParam = 0;
			$isArray =$2;
		}

		s/(\bmy\b|=)?\s*§NEW\s*(;|,)/rewrite4New($1, $2, $isArray)/ge;

		s/§PARAM\s+(\w+)/rewrite4Param($1, $isArray ? ++$nbParam : 0)/ge;

		s/§((\w+)\s*(=|\()?|(?=(\W)))/rewrite4Var($0, $2, $3)/ge;

		$out .= $_ ;
	}
	$_ = $out;
};
##
# les fontions de réécritures utilisé dans les filtres
#

sub rewrite4Var {
	my ($all, $name , $pEgal) = @_;
	$pEgal = '' unless (defined $pEgal);
	if ($name) {
		unless ($name =~ /(NEW|PARAM|package)/){
			if ($pEgal eq '=') {
				return '${$self->_'.$name.'()} =';
			} elsif ($pEgal eq '(') {
				return '$self->'.$name.'(';
			} else {
				return '$self->'.$name.'()';
			}
		}
		return $all;
	}
	return '$self';
}

sub rewrite4Param {
	my ($param, $numParam ) = @_;
	my $idx;
	if ($numParam > 0) {
		$idx = $numParam -1;
		return  # "sub $param {my (\$self, \$val) = \@_; if (defined \$val) { if (ref(\$val) && \$val == \$self) {return \\(\$self->[$idx])} else {\$self->[$idx] = \$val }} else {return \$self->[$idx]} }";
			"sub $param {my (\$self, \$val) = \@_; if (defined \$val) {\$self->[$idx] = \$val} else {\$self->[$idx]} };" .
			"sub _$param {my \$self=shift; \\(\$self->[$idx])}";
	}
	$idx = uc($param);
	return #	"sub $param {my (\$self, \$val) = \@_; if (defined \$val) { if (ref(\$val) && \$val == \$self) {return \\(\$self->{$idx})} else {\$self->{$idx} = \$val }} else {return \$self->{$idx}} }";
		"sub $param {my (\$self, \$val) = \@_; if (defined \$val) { \$self->{$idx} = \$val} else {\$self->{$idx}} };".
		"sub _$param {my \$self = shift; \\(\$self->{$idx})}";
}

sub rewrite4New {
	my ($myEgal, $pVirgule, $isArray) = @_;
	my $sortie;

	
	if ($myEgal eq '=') {
		$sortie = '= bless ';
	} elsif ($myEgal =~ /my/) {
		$sortie = 'my $self = bless ';
	} else {
		$sortie = ' bless ';
	}
	
	
	if ($isArray) {
		$sortie .= '[],';
	} else {
		$sortie .= '{},';
	}
	
	if ($pVirgule eq ';') {
		$sortie .= ' shift();';
	}
	
}

my %ParamLogger = (
		FATAL => ['fatal ',		0, 1, "'FATAL: die at ',"],
		ERROR => ['erreur ',	1, 1, "'ERROR: ',"],
		WARN => ['erreur ',		2, 1, "'WARN: ',"],
		INFO => ['info ',		3, 1, "'INFO: ',"],
		PRINT => ['printInfo ',		0, 0,"'INFO: ',"],
		DEBUG => ['debug ', 	4, 1 , "'DEBUG: ',"],
		TRACE => ['trace ', 	5, 0],
		SYSTEM => ['traceSystem ',0, 1],
		LOG => ['logger ',		0, 0],
		'#DEBUG' => ['debug ',  0, 1,"'DEBUG: ',"],
		'#TRACE' => ['trace ',  0, 1],
	);

sub rewrite4log {
	my ($name, $noText, $call, $logger, $sep) = @_;
	my ($function, $level, $iscall, $text) = @{$ParamLogger{$name}};

#	print "$name, $call, $logger; $function, $level, $call, $text\n";
	my $caller ;
	if ($noText) { #cas avec * pas de texte ni de ligne (caller)
		$caller = "'', ''";

		if ($text) {
			$text = " '', ";
		} else {
			$text = ' ';
		}
	} else {
		$caller = $call ? sprintf('@{[(caller(%d))]}[1,2]', $call-1 ) : '__FILE__, __LINE__';
		if ($text) {
			$text = " $text ";
		} else {
			$text =' ';
		}
	}

	if ($sep) {
		$sep = " join \"$sep\",";
	} else {
		$sep ='';
	}
	my $test;
	my $testFile;
	if ($logger) {
		$function = "_". $function ."$logger,";
		$test = "MyLogger::_is($logger,";
		$testFile = "MyLogger::_file($logger) and " ;
	} else {
	    $test = "MyLogger::is(";
	    $testFile = 'MyLogger::file and ';
	}
	$function = 'MyLogger::' . $function;
	
	if ($iscall) {
		if ($level > 0) {
			return $test . $level . ") and " . $function . $text . $caller . ", $sep"; 
		} elsif ($level < 0) { # on test l'existance d'un fichier
			return   $testFile. $function . $text . $caller . ", $sep"; 
		} else {
			return $function . $text . $caller . ",$sep"; 
		}
	} else {
		if ($level > 0) {
			return $test . $level . ") and " . $function . $text. $sep;
		} elsif ($level < 0) {
			return $testFile . $function . $text. $sep;
		}
		return $function . $text . $sep; 
	}
}




########################################################################
my $defautLog = new MyLogger();

sub new {
	my $class = shift;
	my ($fileName, $autoflush) = @_;
	
	my $self = bless { LEVEL=>2, MOD=>1, BUFSIZE=>1024 }, $class;
	if ($fileName) {
		$self->file($fileName, $autoflush);
	}
	return  $self;
}

sub _file {
	my $self = shift;
	if (@_) {
		return $self->file(@_);
	}
	return $self->{FILE};
}

# sans parametre  (MyLogger::file) renvoie le descripteur de fichier de log courant ou null
# avec 1 param (MyLogger->file()) ferme le fichier de log 
# sinon (MyLogger->file(filename, autoflush) ) fixe le fichier de log et le statut (autofluch des logs)
sub file {
	my $self = shift;

	unless ($self) {
		return $defautLog->{FILE};
	}
	unless (ref $self) {
		$self = $defautLog;
	}

	my ($filename, $autoflush) = @_;

	my $MyLoggerFile = $defautLog->{FILE};;

	if ($MyLoggerFile) {
		close $MyLoggerFile;
	}
	if ($filename) {
		
		$filename =~ s/(\>{1,2})//;
		my $encoding = $1 ? "$1:encoding(UTF-8)" : ">:encoding(UTF-8)";
		print STDERR "Open $1$filename\n";
		open ($MyLoggerFile, $encoding, $filename) or die $filename . " $!" ;
		if ($autoflush) {
			my $old_fh = select($MyLoggerFile);
			$| = 1;
			select($old_fh);
		}
		$self->{FILE} = $MyLoggerFile;
		$self->{FILENAME} = $filename;
	}
}


# fixe le level et mod
# si appele sur la class renvoie le level et mod
# si appele sur un object renvoie l'objet lui même
sub level {
	my $self = shift;

	unless (ref $self) {
		$self = $defautLog;
	};
	
	if (@_) {
		$self->{LEVEL} = shift;
		if (@_) {
			$self->{MOD} = shift;
		} 
	}
	return ($self->{LEVEL}, $self->{MOD});
}

sub _is {
	my $self = shift;
	return (shift() <= $self->{LEVEL});
}
sub is {
	my $levelMin = shift;
	return $levelMin <= $defautLog->{LEVEL};
}

sub _trace {
	local $::defautLog = shift;
	trace (@_);
}

sub trace_ {
	my $mod = shift;
	if ($defautLog->{FILE}) {
		print {$defautLog->{FILE}} @_;
		if ($mod >  2) {
			print STDERR @_;
		}
	} else {
		print STDERR @_;
	}
}
sub trace {
	trace_($defautLog->{MOD}, @_);
}


sub _logger {
	my $self = shift;
	if ($self && $self->{FILE}) {
		print {$self->{FILE}} dateHeure(), @_, "\n";
	}
}
sub logger {
	
	if ($defautLog->{FILE}) {
		print {$defautLog->{FILE}} dateHeure(), @_, "\n";
	}
}


sub _debug {
	local $::defautLog = shift;
	debug(@_);
}

sub debug {
	debug_($defautLog->{MOD}, @_);
}

sub debug_ {
	my $mod = shift;
	my $text = shift;
	my $name = lastname (shift) . ' (' . shift . '): ';
	$name = '' unless $text;

	unshift (@_, $name);

	if ($defautLog->{FILE}) {
		logger ($text, @_);
		if ($mod > 2) {
			print STDERR $text, @_, "\n";
		}
	} else {
		print STDERR $text, @_, "\n";
	}
}

sub _info {
	local $::defautLog = shift;
	info(@_);
}

sub info {
	info_($defautLog->{MOD}, @_);
}

sub printInfo { # les infos toujours sur stdin mais aussi possiblement dans le fichier de log 
	my $text = shift;
	if ($defautLog->{LEVEL} > 1 && $defautLog->{FILE}) {
		my ($fileName, $line) = (caller())[1,2];
		logger ($text, "$fileName ($line): " , @_);
	}
	STDERR->flush;
	print (@_, "\n");
}


sub info_ {
	my $mod = shift;
	my $text = shift;
	my $fileName = lastname (shift) . ' (' . shift . '): ';

	$fileName = '' unless $text;

	if ($defautLog->{FILE}) {
		logger ($text, $fileName, @_);
		if ($mod > 1) {
			print STDERR $text, @_,"\n";
		}
	} else {
		print STDERR $text , $fileName, @_, "\n";
	}
}

sub _erreur {
	local $::defautLog = shift;
	erreur(@_);
}

sub erreur {
	erreur_($defautLog->{MOD}, @_);
}
sub erreur_ {
	my $mod = shift;
	my $type = shift;
	my $fileName = lastname(shift). ' (' . shift . '): ';

	$fileName = '' unless $type;

	if ($defautLog->{FILE}) {
		logger $type, $fileName, @_;
		if ($mod > 0) {
			print STDERR  '> ', $type, $fileName, @_, "\n";
		} 
	} else {
		print STDERR  '> ', $type, $fileName, @_, "\n";
	}
}

sub _fatal {
	local $::defautLog = shift;
	fatal(@_);
}

sub fatal {
	erreur( @_);
	if (is(4)) {
		my $i = 1;
		erreur (" ", "Stack Trace");
		while  ((my ($file, $line, $sub) = (caller($i++))[1,2,3])) {
			erreur ("\t" , $file, $line, $sub);
		}
	}
	file();
	die "\n";
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

sub _traceSystem {
	local $::defautLog = shift;
	traceSystem(@_);
}

sub traceSystem {
	my $fileName = shift;
	my $line = shift;
	my $commande = shift;
	my %params = @_; 
	
	my $mod ;
	if (exists $params{'MOD'}) {
		$mod = $params{'MOD'};
	} else {
		$mod = $defautLog->{MOD};
	}
	unless ($fileName or $line) {
		($fileName, $line) = (caller())[1,2];
		erreur ( 'WARN : ', $fileName, $line, '§SYSTEM appelé avec un indice ne permetant pas de déterminer le fichier et la ligne de d\'appèle' );
	}
	# les parametres optionnels donnés par name => valeur
	my $printOut = printCodeFromParameter($mod, $fileName, $line, 4, 'OUT', $params{'OUT'}); #OUT peut etre vide ou la reference d'un tableau sinon doit etre la reference d'un code qui prend en charge chaque ligne (via $_) envoyée par la commande
	my $printErr = printCodeFromParameter($mod, $fileName, $line, 1, 'ERR', $params{'ERR'}); #même chose que pour OUT ci dessus;

	my $bufSize = $params{'bufferSize'}; #taille du buffer de lecture

	$bufSize = $defautLog->{BUFSIZE} unless $bufSize;
	
	my $COM = Symbol::gensym();
	my $ERR = Symbol::gensym();
	my $select = new IO::Select;

	my $pid;
	eval {
	  $pid = IPC::Open3::open3(undef, $COM, $ERR, $commande) or fatal ("FATAL: ", $fileName, $line, "$commande : die: ", $! );
	};
	fatal ("FATAL: ", $fileName, $line, "$commande : die: ", $@ ) if $@;

	info_ ($mod, $fileName, $line, $commande) if $defautLog->{LEVEL} >= 3;

	$select->add($COM, $ERR);

	my $flagC = 0;
	my $flagE =0;
	my $out;
	my $err;
	
	my %BUF;
	while (my @ready = $select->can_read) {
		foreach my $fh (@ready) {
			my $buf;
			my $len = sysread $fh, $BUF{$fh}, $bufSize, length($BUF{$fh});
			
			if ($len == 0){
				$select->remove($fh);
			} else {
				$buf = decode_utf8_partial($BUF{$fh});
				if ($fh == $COM) {
					$out .= $buf;
					unless ($flagC) {
						if ( $defautLog->{LEVEL} >= 4) { debug_ ($mod, $fileName, $line, " STDOUT :"); }
						$flagC = 1;
					}
					while ($out =~ s/^(.*\n)//) {
						&$printOut($1);
					}
				} elsif ($fh == $ERR) {
					$err .= $buf;
					unless ($flagE) {
						if ($defautLog->{LEVEL} >= 1) { erreur_ ($mod,  'trace : ', $fileName, $line, 'STDERR :'); }
						$flagE = 1;
					}
					while ($err =~ s/^(.*\n)//) {
						&$printErr($1);
					}
				}
			}
		}
	}
	
	&$printOut("$out\n") if $out;
	
	&$printErr("$err\n") if $err;
	
	waitpid $pid, 0;
	my $child_signal = $? & 127;
	my $child_exit_status = $? >> 8;
	erreur_ ($mod, "ERROR: ", $fileName, $line,"$commande : erreur $child_exit_status, $child_signal") if $child_exit_status;
	close $ERR;
	close $COM;
	return $child_exit_status;
}

sub printCodeFromParameter {
	my $mod = shift;
	my $fileName = shift;
	my $line = shift;
	my $level = shift;
	my $pName = shift;
	my $code = shift;

	my $tab =  ($level < 3) ? ">\t" : "\t";

	if ($code) {
		fatal ("FATAL: ",  $fileName, $line, '§'."SYSTEM The $pName parameter must be an ARRAY or CODE réference") unless ref($code) =~ /(ARRAY)|(CODE)/;
		if ($2) {
			return sub {
				local $_ = shift;
				if ($defautLog->{LEVEL} >=  $level) { trace_($mod,$tab, $_); }
				&$code;
			}
		}
		return sub {
			my $line = shift;
			if ($defautLog->{LEVEL} >=  $level) { trace_($mod, $tab, $line); }
			push @$code, $line;
		}
	}
	return sub {
		my $line = shift;
		if ($defautLog->{LEVEL} >=  $level) { trace_($mod, $tab, $line); }
	}
}

## pour convertir en utf8 les sorties de system
# on decode ce que l'on peut ce qui n'est pas decodé reste dans le buffer
# et sera décodé au prochain tour 
sub decode_utf8_partial {
   my $s = decode('UTF-8', $_[0], Encode::FB_QUIET);
   return undef
      if !length($s) && $_[0] =~ /
         ^
         (?: [\x80-\xBF]
         |   [\xC0-\xDF].
         |   [\xE0-\xEF]..
         |   [\xF0-\xF7]...
         |   [\xF8-\xFF]
         )
      /xs;
    return $s;
}

1;
