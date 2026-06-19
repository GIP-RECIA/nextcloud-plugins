use MyLogger ; #'DEBUG';
#use Filter::sh "tee " . __FILE__ . ".pl"; # pour  debuger les macros

package Variables;
use strict;
use utf8;
use Data::Dumper;

# construteur
# Créer un Object variable avec le valeur par défaut donnée par $confHash, s'il existe
sub new {
	my $class = $_[0];
	my $confHash = $_[1];
	my $self = {};
	if ($confHash) {
		add($self, $confHash)
		 #$self = {map (($_, $$confHash{$_}) , grep ( /^\$\w+/, keys %$confHash))};
	} 
	bless $self, $class;
}

# ajoute au Variables le parametre du type '$\w' donné par confHash
sub add { # pour ajouter des parametres variables
	my $this = shift;
	my $confHash = $_[0];
	if (%$confHash) {
		$$this{$_} = $$confHash{$_} for grep ( /^\$\w+/, keys %$confHash);
	}
	return $this;
}



sub instancie { # pour instancie les variables a partir des groupements des regex
				# 
				# return un nouvel objet Variables instancié
	my $this = shift;
	my $predefVariables = shift;
	my (@param) = @_;
	my $res = new (ref $this, $predefVariables);
	if (%$this) {
		while (my ($var, $templateVal)= each %$this ) {
			$res->{$var} = sprintf($templateVal, @param);
		}
	}
	return  $res;
}

#donne la valeur d'une variable
#si elle n'existe pas log une erreur, et renvoie le nom fournie
sub value {
	# donne 
	my ($this, $clee, $trace)= @_;
	if (exists $this->{$clee}) {
		return $this->{$clee};
	}
	§ERROR "Variable non instanciée : $clee; $trace", Dumper($this);
	return $clee;
}

sub remplace {
	my ($this, $entree, $trace) = @_;
	$entree =~ s/(?<!%\d\d?)(\$\w+)/$this->value($1, $trace)/ge;

	return $entree;
}

1;
