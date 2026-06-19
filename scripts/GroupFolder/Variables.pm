use MyLogger ; #'DEBUG';
#use Filter::sh "tee " . __FILE__ . ".pl"; # pour  debuger les macros

package Variables;
use strict;
use utf8;
use Data::Dumper;


sub new {
	my $class = $_[0];
	my $self = {};
	bless $self, $class;
}

sub filtre { # pour recuperer les parametres representants une variable, renvoit un nouvel object  Variables
	my $this = shift;
	my $class = ref($this) || $this;
	my $confHash = $_[0];
	my $self = {map (($_, $$confHash{$_}) , grep ( /^\$\w+/, keys %$confHash))};
	§DEBUG 'filtre:', Dumper($self);
	bless $self, $class;
	
	return $self;
}



sub instancie { # pour instancie les variables a partir des groupements des regex
	my $this = shift;
	my ($variablesLocal, @param) = @_;
	while (my ($var, $templateVal)= each %$variablesLocal ) {
		$this->($var) = sprintf($templateVal, @param);
	}
}

sub remplace {
	my $this = shift;
	my $entree = $_[0];
#	$entree =~ s/(\$\w+)/$this->{$1}/g;
	$entree =~ s/(?<!%\d\d?)(\$\w+)/$this->{$2}/g;
	return $entree;
}

1;
