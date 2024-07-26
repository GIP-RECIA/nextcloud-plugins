#!/usr/bin/perl

=encoding utf8

=head1 NAME

	removeOldUser.pl
	Supprime les plus vieux comptes obsolètes 

=head1 SYNOPSIS

	removeOldUser.pl -n nbCompteASupprimer [-l loglevel] [--force]

	nbCompteASupprimer : nombre maximum de comptes à traiter (<= 2000).
	loglevel : 0x FATAL, 1x ERROR, 2x WARN, 3x INFO, 4x DEBUG, 5x TRACE; defaut = 42.
			si  x = 0 les logs ne vont que dans le fichier
				x = 1 on affiche les FATAL, ERROR et WARN
				x = 2 on affiche en plus les INFO
				x = 3 on ajoute les DEBUG et TRACE
	force :  force l'execution même s'il reste des partage depuis les comptes à supprimer,
	         à n'utiliser que si on est sure que ces partages peuvent être perdu (genre par mail ).

=cut

use strict;
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

use FindBin;
use lib $FindBin::Bin;
use lib $FindBin::Bin . "/GroupFolder";
#use ncUtil;
use MyLogger ; # 'DEBUG';
#use Filter::sh "tee " . __FILE__ . ".pl"; # pour  debuger les macros
use DBI();
use Pod::Usage qw(pod2usage);
use Getopt::Long;
use ncUtil;


my $nbRemovedUserMax;
my $nbJourDelay = 60;
my $loglevel = 4;
my $force = '';

unless (@ARGV && GetOptions ( "n=i" => \$nbRemovedUserMax, "l=i" => \$loglevel, 'force' => \$force ) ) {
	my $myself = $FindBin::Bin . "/" . $FindBin::Script ;
	#$ENV{'MANPAGER'}='cat';
	pod2usage( -message =>"ERROR:	manque d'arguments", -verbose => 1, -exitval => 1 , -input => $myself, -noperldoc => 1 );
}

if (@ARGV) {
	§FATAL "Unknow ", @ARGV;
}

if ($nbRemovedUserMax > 2000) {
	§FATAL "User Max to remove > 2000" ;
}

my $jour = ( (localtime)[3] );
my $logsFile = $FindBin::Script;

$logsFile =~ s/\.pl$/\/$jour.log/;
 $logsFile = $PARAM{'NC_LOG'} . "/" . $logsFile ;

MyLogger->file('>>' . $logsFile);

if ($loglevel) {
	my $mode = 2;
	if ($loglevel >= 10) {
		$mode = $loglevel % 10;
		$loglevel = int $loglevel / 10;
	}
	MyLogger->level($loglevel, $mode);
}

§INFO $FindBin::Script, " -n $nbRemovedUserMax -l $loglevel";
my $sql = connectSql;


if (!$force && &isDelPartage(3) > 0) {
	# si il reste des partages pour les isDel=3 on s'arrete:
	§FATAL "Il reste des partages pour les comptes a supprimer!";
}

# suppression des buckets obsolets
&deleteOldUsersBuckets;

# suppression des comptes déjà marqué à supprimer.
&deleteComptes;

# suppression des partages vers des comptes obsolètes.
&delPartage;

# expiration des partages public;
&expirePartage;

# marque les comptes que l'on peut supprimer. 
&markToDelete;

# suppression des partages vers des comptes obsolètes
sub delPartage {
	my $delShareRequete = q/delete from oc_share where share_with like 'F_______' and share_with in (select uid from oc_recia_user_history u where u.isDel >= 2 and datediff(now(), dat) > 60) limit ?/;

	§PRINT "delete from oc_share ";
	my $sqlStatement = $sql->prepare($delShareRequete) or §FATAL $sql->errstr;

	my $nbLines = $sqlStatement->execute($nbRemovedUserMax) or §FATAL $sqlStatement->errstr;

	§PRINT "\t", 0 + $nbLines, " suppressions";
}

# expiration des partages des comptes obsolètes
sub expirePartage {

	my $req = q/update oc_share set expiration = now() where share_type = (3, 4) and (expiration is null or expiration > now()) and uid_owner in (select uid from oc_recia_user_history where isDel >= 2 and datediff(now(), dat) > 60 order by dat) limit ?/;
	§PRINT "update oc_share set expiration";

	my $sta =$sql->prepare($req) or §FATAL $sql->errstr;
	my $nbLines = $sta->execute($nbRemovedUserMax) or §FATAL $sta->errstr;

	§PRINT "\t", 0 + $nbLines, " updates";
}

# Marquer les comptes sans partage candidat a la suppression
# isDel=2 => le compte est désactivé
# isDel=3 => le compte peut être supprimer
sub markToDelete {
	my $shareLessRequete = q/update oc_recia_user_history set isDel = 3 where isDel = 2 and datediff(now(), dat) > 60 and uid not in (select uid_owner from oc_share where uid_owner is not null and share_type not in (3, 4) and (expiration is null or datediff(expiration, now()) > -60 )) order by dat  limit ?/;
	§PRINT "update oc_recia_user_history set isDel = 3 ...";
	my $sqlStatement = $sql->prepare($shareLessRequete) or §FATAL $sql->errstr;
	my $nbLines = $sqlStatement->execute($nbRemovedUserMax) or §FATAL $sqlStatement->errstr;
	§PRINT "\t", 0 + $nbLines, " mise à jours";
	§PRINT "Nombre de partages restants  : ", isDelPartage(3);
}

#donne les partages des comptes en fonction de la valeurs de isDel 
sub isDelPartage {
	my $isDel = shift;
	$isDel = 3 unless $isDel;
	§DEBUG "Compte partage isDel = $isDel";
	my $req= q/select s.id, s.share_type, s.share_with, s.uid_owner, s.item_source, s.item_type, s.file_target, s.expiration, s.stime from oc_recia_user_history r , oc_users u, oc_share s where r.isDel = ? and r.uid = u.uid and s.uid_owner = r.uid and (s.expiration is null or s.expiration > now())/;
	my $sta = $sql->prepare($req) or §FATAL $sql->errstr;
	my $nb = $sta->execute($isDel) or §FATAL $sta->errstr;
	while (my @tuple =  $sta->fetchrow_array) {
		§TRACE "\t", join(' ', @tuple), "\n";
	}
	§DEBUG "		$nb";
	return 0 + $nb;
}

# Suppression des comptes marqués isDel = 3
sub deleteComptes{
	my $wwwRep = $PARAM{'NC_WWW'};
	chdir $wwwRep;
	my $nbSuppression;
	
	my $nbErr = 0;
		# attention a ne pas augmenter le nombre max de boucle
		# sans revoir la valeur du sleep en debut de boucle
		# avec 5 erreurs on aurra un sleep de 52mm  avec 6 on passe a 12h
	my $maxErr = 5;
	while ($nbErr < $maxErr) {
		sleep $nbErr ** $nbErr if $nbErr++; 
		my $isErr = 0;
		if (§SYSTEM "/usr/bin/php occ ldap:remove-disabled-user -vvv ",
				OUT => sub { $nbSuppression++ if /User\ with\ uid\ :F\w{7}\ was\ deleted/;},
				ERR => sub { $isErr = 1 if /((\[critical\]\ Fatal\ Error\:)|(An\ unhandled\ exception\ has\ been\ thrown\:))/;}
			) {# cas ou la commande termine en erreur
				$isErr = 1;
				$maxErr--;
		} 
	
		last unless ($isErr);
	}
	if (--$nbErr ) { §ERROR "$nbErr erreur d'execution sur $maxErr possible !" ; }
	§PRINT "nombre de suppressions de compte : $nbSuppression";
}

# Les comptes supprimé sans bucket mémorisé
#  select * from oc_recia_user_history u left join recia_bucket_history b on u.uid = b.uid where b.uid is null limit 10;
#  select * from oc_recia_user_history uh left join oc_users u on u.uid= uh.uid left join recia_bucket_history bh on uh.uid = bh.uid where bh.uid is null limit 10;
#  select uh.uid, uh.dat , uh.isDel, uh.name, bh.bucket from oc_recia_user_history uh left join oc_users u on u.uid= uh.uid left join recia_bucket_history bh on uh.uid = bh.uid where u.uid is null limit 10;
# select uh.uid, uh.dat , uh.isDel, uh.name, bh.bucket from oc_recia_user_history uh left join oc_users u on u.uid= uh.uid left join recia_bucket_history bh on uh.uid = bh.uid where u.uid is null < ;
# select * from oc_recia_user_history u left join recia_bucket_history b on u.uid = b.uid where b.uid is null limit 10;
# select uh.uid, uh.dat , uh.isDel, uh.name, bh.bucket from oc_recia_user_history uh left join oc_users u on u.uid= uh.uid left join recia_bucket_history bh on uh.uid = bh.uid  left join oc_storages s on s.id = concat('object::user:', uh.uid ) where s.id is null and u.uid is null and  isDel >= 3 order by dat limit 10;

sub deleteOldUsersBuckets {

	§PRINT "suppression des buckets des anciens utilisateurs ";
	my %bucketMultiUser;
	my $sql = connectSql();
	# recherche des buckets partagés par plusieurs utilisateur;
	my $req = qq/select bucket, count(*) nb from recia_bucket_history where suppression is null group by bucket having nb > 1/;

	my $sth = $sql->prepare($req) or §FATAL $sql->errstr;
	$sth->execute or §FATAL $sth->errstr;
	
	while ( my ($bucket, $nb) = $sth->fetchrow_array) {
		$bucketMultiUser{$bucket} = $nb;
	}

	# recherche de tout les historiques qui ne sont pas dans oc_users , ni dans oc_storages avec isDel >=3 (donc plus d'acces dans NC)
	$req = qq/select uh.uid, uh.dat , uh.isDel, uh.name, bh.bucket
				from oc_recia_user_history uh left join oc_users u on u.uid= uh.uid
				left join recia_bucket_history bh on uh.uid = bh.uid
				left join oc_storages s on s.id = concat('object::user:', uh.uid )
				where s.id is null and u.uid is null and  isDel >= 3
				order by dat limit ?/;

	$sth = $sql->prepare($req) or §FATAL $sql->errstr;
	$sth->execute($nbRemovedUserMax) or §FATAL $sth->errstr;
	my $nbDeletedBucket = 0;
	my $nbDeletedObject = 0;
	my $nbDeletedObjectTotal =0;
	while (my ($uid, $dat, $isDel, $name, $bucket) =  $sth->fetchrow_array) {
		#§DEBUG "bucket a supprimer ($bucket, $uid)"; 
		my $notDelete = 1;
		if ($bucket) {
			if ($bucket =~ /\-\w{8,25}$/) {
				#§DEBUG "le bucket n'est pas un bucket systeme";
				$notDelete = $bucketMultiUser{$bucket};
				if ($notDelete) {
					#§DEBUG "le bucket est partagé (ne devrait pas arriver)";
					$bucketMultiUser{$bucket}--;
				} else {
					#§DEBUG "le bucket n'est pas partagé";
					$bucket = &getBucketName($bucket);
				}
			} 
		} else {
			#§DEBUG "calcul du bucket manquand";
			$bucket = uid2bucket($uid);
			$notDelete = 0;
		}
		my $s3cmd = getS3command();
		my $isDeleted=0;
		unless ($notDelete || !$bucket) {
			#§DEBUG "Delete $bucket";
			($isDeleted, $nbDeletedObject) = deleteBucket($bucket);
			$nbDeletedBucket++ if $isDeleted > 0;
			$nbDeletedObjectTotal += $nbDeletedObject;
 		}
 		
 		$bucket = &getBucketName('0' . lc($uid));
 		#§DEBUG "Delete bucket des avatars $bucket";
 		my @del = deleteBucket($bucket);
 		$nbDeletedBucket++ if $del[0] > 0;
 		$nbDeletedObjectTotal += $del[1];

 		if ($isDeleted) {
			#§DEBUG "Suppression dans la table recia_bucket_history";
			$bucket =~ s/^s3:\/\///;
			my $req = qq/delete from recia_bucket_history where bucket=? and uid = ?/;
			my $sth = $sql->prepare($req) or §FATAL $sql->errstr;
			$sth->execute($bucket, $uid) or §FATAL $sth->errstr;

			#§DEBUG "Suppression dans la table oc_recia_user_history";
			$req = qq/delete from oc_recia_user_history where uid = ?/;
			$sth = $sql->prepare($req) or §FATAL $sth->errstr;
			$sth->execute($uid) or §FATAL $sth->errstr;
		}
	}
	§PRINT "objects supprimés : $nbDeletedObjectTotal";
	§PRINT "buckets supprimés : $nbDeletedBucket\n";
}

# suppression d'un bucket avec son contenu sans controle
# renvoie 0 si le bucket n'est pas supprimé , -1 s'il n'existait pas et 1 s'il a été supprimé
# renvoie en 2ieme valeur le nombre d'objet supprimés
sub deleteBucket {
	my $bucket = shift;
	my $nbDeleted =0;
	my $lastErr = '';
	my $nbErr = 0 ;
	my $s3cmd = getS3command();
	if ($bucket =~ /\w{9,25}$/) { # on ne veut pas effacer les buckets du syle 's3://nc-recette-0' 
		my $status = §SYSTEM "$s3cmd  del --force --recursive $bucket",
			OUT => sub { $nbDeleted++ if /^delete/},
			ERR => sub { if (/^ERROR[^\[]*\((\w+)\)/) {$lastErr = $1; $nbErr++;} },
			MOD => 0;
		if ($status && $status != 12) {
			§ERROR "$s3cmd  del --force --recursive $bucket : error $status"; 
		}
		§DEBUG "nombre d'objets supprimés : $nbDeleted";
		if  ($nbErr) {
			if ($lastErr =~ /NoSuchBucket/) {
				§DEBUG "bucket inexistant";
				return (-1, $nbDeleted);
			}
			§DEBUG "erreur de suppression d'objet : $lastErr";
			return (0, $nbDeleted);
		} else {
			$status = §SYSTEM "$s3cmd  rb $bucket" , ERR => sub {$nbErr++ if /^ERROR/;}, MOD => 0 ;
			if ( $status || $nbErr) {
				§ERROR "Suppression de bucket $bucket  en erreur : (status, nberr) = ($status, $nbErr) ";
				return (0, $nbDeleted);
			} 
			§INFO "bucket supprimé : $bucket ($nbDeleted)" ;
			return (1, $nbDeleted);
		}
	} else {
		§WARN "Tentative de suppression du bucket : $bucket";
		return (0, $nbDeleted);
	}
}

__END__

 select distinct share_type from oc_share; 
+------------+
| share_type |
+------------+
|          0 | -> a des personnes
|          1 | -> a des groupes
|          2 | -> a des personnes via un groupe dans ce cas le partage a un parent : le partage au groupe
|          3 | -> partage public link
|          4 | -> partage par mail
|         12 | -> deck '/{DECK_PLACEHOLDER}' ressemble au 1 sauf le share_with est un numero 
|         13 | -> deck a des personne ressemble au 2 avec de groupe a la deck et parent avec share_type 12
+------------+
12 13 que sur ncgip pas sur ncprod
