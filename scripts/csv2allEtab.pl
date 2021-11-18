#! /usr/bin/perl

# permet de formater un fichier issue d'un .csv
# pour le mettre au format de allEtab
# modifier readLine en fonction des entrees doit sortir (uai, nometab)

sub readLine(){
		chop;
		@col = split  '","', $_;
		return $col[2], $col[4] ;
	}

sub writeLine(){
	$uai = shift;
	$nom = shift;
	print "$uai; # $nom \n";	
}
while (<>) {
	&writeLine(&readLine());
}
