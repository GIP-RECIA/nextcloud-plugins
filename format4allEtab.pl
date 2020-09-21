#! /usr/bin/perl

# permet de formater un fichier issue d'un copier coller exel 
# par exemple pour le mettre au format de allEtab
# modifier readLine en fonction des entrees doit sortir (uai, nometab)

sub readLine(){
		chop;
		@col = split  '\t+', $_;
		return $col[-1], $col[0] . " " . $col[-2];
	}
sub writeLine(){
	$uai = shift;
	$nom = shift;
	print "$uai; # $nom \n";	
}
while (<>) {
	&writeLine(&readLine());
}
