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
my $nbJourDelay = 20;
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

$logsFile =~ s/(_dev)?\.pl$/\/$jour$1.log/;
 $logsFile = $PARAM{'NC_LOG'} . "/" . $logsFile ;

MyLogger->file('>>' . $logsFile);

my $mode = 2;
if ($loglevel) {
	if ($loglevel >= 10) {
		$mode = $loglevel % 10;
		$loglevel = int $loglevel / 10;
	}
	MyLogger->level($loglevel, $mode);
}

§INFO $FindBin::Script, " -n $nbRemovedUserMax -l $loglevel$mode";
my $sql = connectSql;



# suppression des partages vers des comptes obsolètes.
&delPartage;

# expiration des partages public;
&expirePartage;


if (!$force && &isDelPartage(3) > 0) {
	# si il reste des partages pour les isDel=3 on s'arrete:
	§FATAL "Il reste des partages pour les comptes a supprimer!";
}

# suppression des buckets obsolets
&deleteOldUsersBuckets;

# suppression des comptes déjà marqué à supprimer.
&deleteComptes;


# marque les comptes que l'on peut supprimer. 
&markToDelete;

# suppression des fichiers non partagés, des comptes obsolètes
&deleteFile($nbRemovedUserMax);

sub delPartage {
	my $sql = newConnectSql(0);
	# suppression de partage vers des comptes obsolète
	my $delShareRequete = q/delete from oc_share where share_with like 'F_______' and share_with in (select uid from oc_recia_user_history u where u.isDel = 2 and datediff(now(), dat) > ?) limit ?/;

	§PRINT "delete from oc_share where share_with like 'F_____'" ;
	my $sqlStatement = $sql->prepare($delShareRequete) or §FATAL $sql->errstr;
	my $nbLines = $sqlStatement->execute($nbJourDelay, $nbRemovedUserMax) or §FATAL $sqlStatement->errstr;

	$sql->commit() or §FATAL $sqlStatement->errstr;;
	§PRINT "\t", 0 + $nbLines, " suppressions ";
	
	$sql->do(
		  q/CREATE TEMPORARY TABLE  recia_share_to_delete_temp (id bigint PRIMARY KEY)
			select s.id from oc_share s
			left join oc_share s2 on s2.parent = s.id
			left join  oc_groups g on g.gid = s.share_with
			where g.gid is null
			and s2.id is null
			and s.share_type = 1/
		) or §FATAL $sql->errstr;

	# suppression des partages vers des groupes n'existant plus et parent d'aucun autre partage  
	$delShareRequete = q/delete from oc_share where share_type = 1 and id  in ( select id from recia_share_to_delete_temp) limit ?/;

	§PRINT "delete from oc_share where share_type = 1 " ;
	$sqlStatement = $sql->prepare($delShareRequete) or §FATAL $sql->errstr;

	$nbLines = $sqlStatement->execute($nbRemovedUserMax) or §FATAL $sqlStatement->errstr;

	$sql->commit() or §FATAL $sqlStatement->errstr; ;

	§PRINT "\t", 0 + $nbLines, " suppressions";

	$sql->disconnect();
}

# expiration des partages des comptes obsolètes
sub expirePartage {

	my $req = q/update oc_share set expiration = now() where share_type in (3, 4) and (expiration is null or expiration > now()) and uid_owner in (select uid from oc_recia_user_history where isDel = 2 and datediff(now(), dat) > ? order by dat) limit ?/;
	§PRINT "update oc_share set expiration";

	my $sta =$sql->prepare($req) or §FATAL $sql->errstr;
	my $nbLines = $sta->execute($nbJourDelay, $nbRemovedUserMax) or §FATAL $sta->errstr;

	§PRINT "\t", 0 + $nbLines, " updates des partages liens";

		# Expiration des partages de comptes obsolètes vers des comptes d'élèves
	$req = q/update oc_share s, recia_storage r, oc_recia_user_history u
				set s.expiration = now()
			where s.share_with = r.uid
			and s.expiration is null
			and r.categorie = 'E'
			and u.uid = s.uid_owner
			and u.isdel = 2
			and datediff(now(), u.dat) > ?/ ;
#	$sta =$sql->prepare($req) or §FATAL $sql->errstr;
	
#	$nbLines = $sta->execute($nbJourDelay) or §FATAL $sta->errstr;

#	§PRINT "\t", 0 + $nbLines, " updates partage vers élèves";

	#TODO Expiration des partages de comptes obsolètes vers des répertoires vide
#	$req = q/update oc_share s, oc_recia_user_history u set s.expiration = now()
#			where u.uid = s.uid_owner
#			and u.isdel = 2
#			and datediff(now(), u.dat) > ?
#			and s.file_source not in select .../
}

# Marquer les comptes sans partage candidat a la suppression
# isDel=2 => le compte est désactivé
# isDel=3 => le compte peut être supprimer
sub markToDelete {
	my $shareLessRequete = q/update oc_recia_user_history set isDel = 3
		where isDel = 2 and datediff(now(), dat) > ?
		and uid not in (select uid_owner from oc_share where uid_owner is not null and share_type not in (3, 4) and (expiration is null or datediff(now() , expiration)  < ? )) order by dat  limit ?/;
	§PRINT "update oc_recia_user_history set isDel = 3 ...";
	my $sqlStatement = $sql->prepare($shareLessRequete) or §FATAL $sql->errstr;
	my $nbLines = $sqlStatement->execute($nbJourDelay,$nbJourDelay,$nbRemovedUserMax) or §FATAL $sqlStatement->errstr;
	§PRINT "\t", 0 + $nbLines, " mise à jours";
	§PRINT "Nombre de partages restants  : ", isDelPartage(3);
}


#donne les partages des comptes en fonction de la valeurs de isDel 
sub isDelPartage {
	my $isDel = shift;
	$isDel = 3 unless $isDel;
	§DEBUG "Compte partage isDel = $isDel";
	my $req= q/	select s.id, s.share_type, s.share_with, s.uid_owner, s.item_source, s.item_type, s.file_target, s.expiration, s.stime
				from oc_recia_user_history r , oc_users u, oc_share s
				where r.isDel = ?
				and r.uid = u.uid
				and s.uid_owner = r.uid
				and (s.expiration is null
					or s.expiration > now()
				)/;
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
	
	while ($nbErr < 10) {
		sleep $nbErr  if $nbErr++;

		unless (§SYSTEM "/usr/bin/php occ ldap:remove-disabled-user -vvv ",
				OUT => sub { $nbSuppression++ if /User\ with\ uid\ :F\w{7}\ was\ deleted/;},
				ERR => sub { $nbErr++ if /((\[critical\]\ Fatal\ Error\:)|(An\ unhandled\ exception\ has\ been\ thrown\:))/;},
				MOD => 0
			) {# cas ou la commande termine sans erreur
				last;
		}
	}
	if (--$nbErr ) { §ERROR "$nbErr erreur d'execution sur $maxErr possible !" ; }
	§PRINT " nombre de suppressions de compte : $nbSuppression";
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

	# recherche de tout les historiques qui ne sont pas dans oc_users , ni dans oc_storages avec isDel >3 (donc plus d'acces dans NC)
	$req = qq/select uh.uid, uh.dat , uh.isDel, uh.name, bh.bucket
				from oc_recia_user_history uh left join oc_users u on u.uid= uh.uid
				left join recia_bucket_history bh on uh.uid = bh.uid
				left join oc_storages s on s.id = concat('object::user:', uh.uid )
				where s.id is null and u.uid is null and  isDel > 3
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
			if ($bucket =~ /\-\w{9,}$/) {
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

			my $bucketAvatar = &getBucketName('0' . lc($uid));
			#§DEBUG "Delete bucket des avatars $bucket";
			my @del = deleteBucket($bucketAvatar);
			$nbDeletedBucket++ if $del[0] > 0;
			$nbDeletedObjectTotal += $del[1];
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
	if ($bucket =~ /\-\w{9,}$/) { # on ne veut pas effacer les buckets du syle 's3://nc-recette-0' 
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


# suppression des fichiers non partagés, des comptes obsolètes. 
sub deleteFile {
	my $maxCount = shift;
	§PRINT "Suppression des fichiers non partagés, des comptes obsolètes.";
	my %NbError;
	my %storage2uid;
	
	my $occ = '/usr/bin/php '. $PARAM{'NC_WWW'} . '/occ';
	
	my $sql = newConnectSql(1);

	# initialisation de la tables des comptes à traiter
	$sql->do( q/truncate recia_init_nopartage_temp/)  or §FATAL $sql->errstr;

	my $prefixStorage = isObjectStore() ? 'object::user:' : 'home::'; 

		# on initialise avec le sommet de l'arborescence de chaque compte 
	my $sqlStatement = $sql->prepare(q/
			insert into recia_init_nopartage_temp (
				select s.numeric_id, f.fileid, h.uid, f.mimetype 
				from  oc_recia_user_history h, oc_storages s, oc_filecache f
				where isDel = 2 and datediff(now(), dat) > ?
				and s.id = concat( ? , h.uid)
				and f.storage = s.numeric_id
				and f.parent = -1
				and f.path = ''
				and s.numeric_id is not null
				order by h.dat  limit ?
			) 
		/) or §FATAL $sql->errstr;
		
	my $nbLines = $sqlStatement->execute( $nbJourDelay+1, $prefixStorage, $maxCount) or §FATAL $sqlStatement->errstr;

#	$sql->commit() or §FATAL $sqlStatement->errstr;
	$nbLines += 0;
	§PRINT "\tprepare delete no shared files: ", 0 + $nbLines, " comptes";
	return unless $nbLines; # on s'arrete si il n'y a rien
	
	
	
	# suppressions de leurs corbeilles et versions

	$sqlStatement = $sql->prepare(q/select uid, storage from recia_init_nopartage_temp/) or §FATAL $sqlStatement->errstr;

	my $status;
	my $seconde = 1;
	my $cpt;  # on boucle jusqu'a retrouver les lignes inserées (pb avec le cluster sql de synchro entre ecriture et lecture)
	while ($nbLines > $cpt && $seconde < 60) {
		sleep($seconde);
		$seconde *= 2;
		$sqlStatement->execute() or §FATAL $sqlStatement->errstr;
		$cpt = 0;
		while (my ($uid, $storage) =  $sqlStatement->fetchrow_array) {
			$cpt++;
			§DEBUG $uid, " ", $storage;
			$NbError{$uid} = 0;
			$storage2uid{$storage} = $uid;
			$status = §SYSTEM "$occ trashbin:cleanup -n $uid", MOD => 1;
			$status += §SYSTEM "$occ versions:cleanup -n $uid", MOD => 1;
			if ($status) {
				$NbError{$uid} = 1;
			}
		}
		§DEBUG "select uid, storage from recia_init_nopartage_temp ", $cpt;
	}

	§FATAL "Mauvaise init de recia_init_nopartage_temp: ", $sqlStatement->errstr unless ($cpt > 0 );
	§PRINT "Compte à traiter : $cpt";


	# suppressions des répertoires sans partage.
	my %repStatus; 	# pour indexer le repertoire déjà traiter (supprimer) avec réussite ou non
					# la requête donne tous les répertoires sans partage et les ordonnes par path, on ne supprime un répertoire que si son parent n'est pas lui même déjà supprimer
	$sqlStatement = $sql->prepare(q(select storage, fileid, parent, path from recia_rep_sans_partage where parent != -1 and path like 'files/%' order by storage, path)) or §FATAL $sqlStatement->errstr;
	$sqlStatement->execute() or §FATAL $sqlStatement->errstr;

	§PRINT "Suppression des repertoires sans partage";
	my $lastRepDeleted;
	while (my ($storage, $repId, $parentId, $path) =  $sqlStatement->fetchrow_array  ) {
		if (exists $repStatus{$parentId}) {
			$repStatus{$repId} = 0;
		} else {
			§DEBUG "delete rep $path";
			$status = §SYSTEM "$occ files:delete -f -vv $repId", MOD => 1;
			if ($status) {
				$NbError{$storage2uid{$storage}}++;
				§DEBUG "delete rep error parent = $parentId ";
				$repStatus{$repId} = 0;
			} else {
				$repStatus{$repId} = 1;
				$lastRepDeleted=$repId;
			}
		}
	}
	§PRINT "Nombre de répertoire supprimés : ", scalar keys %repStatus;
	if ($lastRepDeleted) {
		# on a des répertoires supprimés
		$sqlStatement = $sql->prepare(q(select storage, fileid from oc_filecache where path like 'files_trashbin/%' and fileid = ? ));
		$seconde = 1;
		while ($seconde < 60) {
			sleep($seconde); $seconde *= 2; #on temporise jusqu'a ce que le dernier répertoire supprimé soit dans la corbeille
			
			$sqlStatement->execute($lastRepDeleted) or §FATAL $sqlStatement->errstr;
			if (my ($storage, $repId) = $sqlStatement->fetchrow_array) {
				§DEBUG "$repId supprimé en $seconde";
				# ok il est dans la corbeille
				$lastRepDeleted = '';
				last;
			}
			
			§DEBUG $seconde;
		}

		§FATAL "Suppression de répertoire mal teminée : $lastRepDeleted" if $lastRepDeleted;
	}
	
	§PRINT "Suppression des fichiers restant non partagés";

	$sqlStatement = $sql->prepare(q(select fileid, storage, path from recia_files_non_partage where !isrep and path like 'files/%' order by storage, path)) or §FATAL $sqlStatement->errstr;
	$sqlStatement->execute() or §FATAL $sqlStatement->errstr;

	$cpt = 0;
	while (my ($fileId , $storage, $path) =  $sqlStatement->fetchrow_array  ) {
		§DEBUG "delete file $path";
		$status = §SYSTEM "$occ files:delete -f -vv $fileId", MOD => 1;
		if ($status) {
			my $uid = $storage2uid{$storage};
			$NbError{$uid}++;
			§ERROR "delete file: $path, $fileId, $uid";
			sleep 1;
		} else {
			$cpt++;
		}
	}

	§PRINT "Nombre de fichiers supprimés : $cpt";

	$cpt = 0;
	§LOG "Les uids en erreur :";
	while (my ($uid, $nbErr) = each %NbError) {
		if ($nbErr) {
			$cpt++;
			§LOG "\t$uid $nbErr";
		}
	}
	§PRINT "Nombre d'uids en erreur : $cpt" if $cpt;

	$sqlStatement = $sql->prepare(q/update oc_recia_user_history h, recia_init_nopartage_temp t  set h.dat = now() where t.uid = h.uid/) or §FATAL $sqlStatement->errstr;
	$sqlStatement->execute() or §FATAL $sqlStatement->errstr;

	$sql->disconnect();
	
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
