<?php


namespace OCA\LdapImporter\Service\Import;

use OCA\LdapImporter\Service\Merge\AdUserMerger;
use OCA\LdapImporter\Service\Merge\MergerInterface;
use OCP\IConfig;
use OCP\IDBConnection;
use Psr\Log\LoggerInterface;


/**
 * Class AdImporter
 * @package LdapImporter\Service\Import
 *
 * @author Felix Rupp <kontakt@felixrupp.com>
 * @copyright Felix Rupp
 *
 * @since 1.0.0
 */
class AdImporter implements ImporterInterface
{

    /**
     * @var boolean|resource
     */
    private $ldapConnection;

    /**
     * @var MergerInterface $merger
     */
    private $merger;

    /**
     * @var LoggerInterface $logger
     */
    private $logger;

    /**
     * @var IConfig
     */
    private $config;

    /**
     * @var string $appName
     */
    private $appName = 'ldapimporter';

    /**
     * @var IDBConnection $db
     */
    private $db;

    /**
     * @var $ldapFilterter
     */
    private $ldapFilter;

    /**
     * AdImporter constructor.
     * @param IConfig $config
     * @param IDBConnection $db
     * @param $ldapFilter
     * @param IGroupManager $groupManager
     */
    public function __construct(IConfig $config, IDBConnection $db, $ldapFilter)
    {
        $this->config = $config;
        $this->db = $db;
        $this->ldapFilter = $ldapFilter;
    }


    /**
     * @param LoggerInterface $logger
     *
     * @throws \Exception
     */
    public function init(LoggerInterface $logger)
    {

        $this->merger = new AdUserMerger($logger);
        $this->logger = $logger;

        $this->ldapConnect();
        $this->ldapBind();

        $this->logger->info("Init complete.");
    }

    /**
     * @throws \Exception
     */
    public function close()
    {

        $this->ldapClose();
    }

    /**
     * Get User data
     *
     * @return array User data
     */
    public function getUsers()
    {
		$date = date('Y-m-d');
        $uidAttribute = $this->config->getAppValue($this->appName, 'cas_import_map_uid');

        $displayNameAttribute1 = $this->config->getAppValue($this->appName, 'cas_import_map_displayname');
        $displayNameAttribute2 = '';

        if (strpos($displayNameAttribute1, "+") !== FALSE) {
            $displayNameAttributes = explode("+", $displayNameAttribute1);
            $displayNameAttribute1 = $displayNameAttributes[0];
            $displayNameAttribute2 = $displayNameAttributes[1];
        }

        $emailAttribute = $this->config->getAppValue($this->appName, 'cas_import_map_email');
        $groupsAttribute = $this->config->getAppValue($this->appName, 'cas_import_map_groups');

        $groupsFilterAttribute = json_decode($this->config->getAppValue($this->appName, 'cas_import_map_groups_fonctionel'), true);
        $arrayGroupsAttrPedagogic = json_decode($this->config->getAppValue($this->appName, 'cas_import_map_groups_pedagogic'), true);
        $arrayRegexNameUai = json_decode($this->config->getAppValue($this->appName, 'cas_import_map_regex_name_uai'), true);

        $quotaAttribute = $this->config->getAppValue($this->appName, 'cas_import_map_quota');
        $enableAttribute =strtolower($this->config->getAppValue($this->appName, 'cas_import_map_enabled'));
        $dnAttribute = $this->config->getAppValue($this->appName, 'cas_import_map_dn');
        $mergeAttribute = boolval($this->config->getAppValue($this->appName, 'cas_import_merge'));
        $primaryAccountDnStartswWith = $this->config->getAppValue($this->appName, 'cas_import_map_dn_filter');
        $preferEnabledAccountsOverDisabled = boolval($this->config->getAppValue($this->appName, 'cas_import_merge_enabled'));
        $andEnableAttributeBitwise = $this->config->getAppValue($this->appName, 'cas_import_map_enabled_and_bitwise');

        $keep = [$uidAttribute, $displayNameAttribute1, $displayNameAttribute2, $emailAttribute, $groupsAttribute, $quotaAttribute, $enableAttribute, $dnAttribute];

        //On ajoute des nouveaux éléments qu'on récupère du ldap pour les groupe
        $keep[] = 'ESCOUAICourant';
        $keep[] = 'ESCOSIREN';
        $keep[] = 'ENTPersonStructRattach';
        if (sizeof($arrayGroupsAttrPedagogic) > 0) {
            foreach ($arrayGroupsAttrPedagogic as $groupsAttrPedagogic) {
                if (array_key_exists("field", $groupsAttrPedagogic) && strlen($groupsAttrPedagogic["field"]) > 0 &&
                    array_key_exists("filter", $groupsAttrPedagogic) && strlen($groupsAttrPedagogic["filter"]) > 0 &&
                    array_key_exists("naming", $groupsAttrPedagogic) && strlen($groupsAttrPedagogic["naming"]) > 0) {
                    $keep[] = strtolower($groupsAttrPedagogic["field"]);
                }
            }
        }

        if (!$this->db->tableExists("etablissements")) {
            $sql =
                'CREATE TABLE `*PREFIX*etablissements`' .
                '(' .
                'id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,' .
                'name VARCHAR(255),' .
                'uai VARCHAR(255),' .
                'siren VARCHAR(255)' .
                ')';
            $this->db->executeQuery($sql);
        }
        if (!$this->db->tableExists("asso_uai_user_group")) {
            $sql =
                'CREATE TABLE `*PREFIX*asso_uai_user_group`' .
                '(' .
                'id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,' .
                'id_etablissement VARCHAR(255),' .
                'user_group VARCHAR(255)' .
                ')';
            $this->db->executeQuery($sql);
        }
        
        if (!$this->db->tableExists("recia_user_history")) {
			$this->logger->error("Creation de la table :" );
            $sql =
                'CREATE TABLE `*PREFIX*recia_user_history`' .
                '(' .
                'uid char(8) PRIMARY KEY,' .
                'siren varchar(15), ' .
                'dat date, '.
                'eta varchar(32),' .
                'isadd tinyint(1),' .
                'isdel tinyint(1),' .
                'name varchar(100),' .
                'UNIQUE (siren, isdel, uid)' .
                ')';
            $this->db->executeQuery($sql);
        }

        $pageSize = $this->config->getAppValue($this->appName, 'cas_import_ad_sync_pagesize');

        $users = [];

        $this->logger->info("Getting all users from the AD …");

        # Get all members of the sync group
        $memberPages = $this->getLdapList($this->config->getAppValue($this->appName, 'cas_import_ad_base_dn'), $this->config->getAppValue($this->appName, 'cas_import_ad_sync_filter'), $keep, $pageSize);

        foreach ($memberPages as $memberPage) {

            #var_dump($memberPage["count"]);

            for ($key = 0; $key < $memberPage["count"]; $key++) {

                $m = $memberPage[$key];

                # Each attribute is returned as an array, the first key is [count], [0]+ will contain the actual value(s)
                $employeeID = isset($m[$uidAttribute][0]) ? $m[$uidAttribute][0] : "";
                $mail = isset($m[$emailAttribute][0]) ? $m[$emailAttribute][0] : "";
                $dn = isset($m[$dnAttribute]) ? $m[$dnAttribute] : "";
                $idsEtabUser = [];

                $displayName = $employeeID;

                if (isset($m[$displayNameAttribute1][0])) {

                    $displayName = $m[$displayNameAttribute1][0];

                    if (strlen($displayNameAttribute2) > 0 && isset($m[$displayNameAttribute2][0])) {

                        $displayName .= " " . $m[$displayNameAttribute2][0];
                    }
                } else {

                    if (strlen($displayNameAttribute2) > 0 && isset($m[$displayNameAttribute2][0])) {

                        $displayName = $m[$displayNameAttribute2][0];
                    }
                }

                $quota = isset($m[$quotaAttribute][0]) ? intval($m[$quotaAttribute][0]) : 0;


                $enable = 1;
				

                $groupsArray = [];

                $addUser = FALSE;

                if (isset($m[strtolower($groupsAttribute)][0])) {

                    # Cycle all groups of the user
                    $assoEtablissementUaiOrNameAndId = [];

                    for ($j = 0; $j < $m[strtolower($groupsAttribute)]["count"]; $j++) {
                        $resultGroupsAttribute = $m[strtolower($groupsAttribute)][$j];

                        # Check if user has MAP_GROUPS attribute
                        if (isset($m[strtolower(($groupsAttribute))][$j])) {
                            foreach($arrayRegexNameUai as $regexNameUaiGroup) { # les regex associant le nom et  l'uai des etabs
                                if (array_key_exists("nameUai", $regexNameUaiGroup) && !is_null($regexNameUaiGroup["nameUai"])) {
                                    preg_match_all('/' . $regexNameUaiGroup["nameUai"] . '/si', $resultGroupsAttribute, $uaiNameMatches, PREG_SET_ORDER, 0);

                                    if (sizeof($uaiNameMatches) > 0 && sizeof($uaiNameMatches[0]) >= 2) {
                                        $indexRegexUaiGroup = array_key_exists("uaiGroup", $regexNameUaiGroup) && !is_null($regexNameUaiGroup["uaiGroup"]) ? intval($regexNameUaiGroup["uaiGroup"]) : null;
                                        $indexRegexNameGroup = array_key_exists("nameGroup", $regexNameUaiGroup) && !is_null($regexNameUaiGroup["nameGroup"]) ? intval($regexNameUaiGroup["nameGroup"]) : null;
                                        $uaiEtablissement = is_null($indexRegexUaiGroup)  ? null : $uaiNameMatches[0][$indexRegexUaiGroup];
                                        $nameEtablissement = is_null($indexRegexNameGroup) ? null : $uaiNameMatches[0][$indexRegexNameGroup];


                                        $groupCnEtablissement = str_replace("people", "structures", $this->config->getAppValue($this->appName, 'cas_import_ad_base_dn'));
                                        if (is_null($uaiEtablissement)) {
                                            $filter = "ENTStructureNomCourant=" . str_replace("'", "\\27", str_replace(" ", "\\20", $nameEtablissement));
                                            $groupAttr = $this->getLdapSearch($groupCnEtablissement, $filter);
                                            $assoEtab = $nameEtablissement;
                                        }
                                        else {
                                            $filter = "ENTStructureUAI=" . $uaiEtablissement;
                                            $groupAttr = $this->getLdapSearch($groupCnEtablissement, $filter);
                                            $assoEtab = $uaiEtablissement;
                                        }
                                        $sirenEtab = null;
                                        $uaiEtab = null;
                                        if (array_key_exists('entstructuresiren', $groupAttr) && $groupAttr['entstructuresiren']['count'] > 0) {
                                            $sirenEtab = $groupAttr['entstructuresiren'][0];
                                        }

                                        if (array_key_exists('entstructureuai', $groupAttr) && $groupAttr['entstructureuai']['count'] > 0) {
                                            $uaiEtab = $groupAttr['entstructureuai'][0];
                                        }

                                        $idEtab = $this->addEtablissement($uaiEtab, $nameEtablissement, $sirenEtab);
                                        $assoEtablissementUaiOrNameAndId[$assoEtab] = $idEtab;
                                    }
                                }
                            }

                        }
                    }


                    for ($j = 0; $j < $m[strtolower($groupsAttribute)]["count"]; $j++) {

                        # Check if user has MAP_GROUPS attribute
                        if (isset($m[strtolower(($groupsAttribute))][$j])) {

                        //    $addUser = TRUE; # Only add user if the group has a MAP_GROUPS attribute

                            $resultGroupsAttribute = $m[strtolower($groupsAttribute)][$j];

                            $groupName = '';

                            foreach ($groupsFilterAttribute as $groupFilter) {
                                if (array_key_exists('filter', $groupFilter)) {
                                    if (preg_match_all("/" . $groupFilter['filter'] . "/si", $resultGroupsAttribute, $groupFilterMatches)) {
                                        $addUser = TRUE; # Only add user if the group has a MAP_GROUPS  attribute matching

                                        if (!isset($quota) || intval($quota) < intval($groupFilter['quota'])) {
                                            $quota = $groupFilter['quota'];
                                        }
                                        if (array_key_exists('naming', $groupFilter)) {

                                            $newName = $groupFilter['naming'];
                                            $regexGabarits = '/\$\{(.*?)\}/i';

                                            preg_match_all($regexGabarits, $newName, $matches, PREG_SET_ORDER, 0);
                                            $sprintfArray = [];
                                            foreach ($matches as $match) {
                                                $newName = preg_replace('/\$\{' . $match[1] . '\}/i', '%s', $newName, 1);
                                                $sprintfArray[] = $groupFilterMatches[$match[1]][0];
                                            }
                                            $groupName = $this->normalizedGroupeName(sprintf($newName, ...$sprintfArray));
                                       
                                            if (!is_null($groupFilterMatches) && !is_null($groupFilter["uaiNumber"]) && count($assoEtablissementUaiOrNameAndId) > 0) {
                                                $nameOrUaiFromUaiNumber = $groupFilterMatches[intval($groupFilter["uaiNumber"])];
                                                $idEtablissement = $assoEtablissementUaiOrNameAndId[$nameOrUaiFromUaiNumber[0]];
                                                $this->addEtablissementAsso($idEtablissement, $groupName);
                                                $this->addEtablissementAsso($idEtablissement, $employeeID);
                                                $idsEtabUser[] = $idEtablissement;
                                            }
                                            elseif (!is_null($groupFilterMatches[intval($groupFilter["uaiNumber"])]) && !array_key_exists($groupFilterMatches[intval($groupFilter["uaiNumber"])], $assoEtablissementUaiOrNameAndId)) {
                                                $this->logger->debug("L'établissement avec le nom/Uai : " . $groupFilterMatches[intval($groupFilter["uaiNumber"])] . " n'existe pas");
                                            }
                                            break;
                                        }
                                    }
                                    else {
                                        $this->logger->debug("Groupes fonctionels : la regex " . $groupFilter['filter'] . " ne match pas avec le groupe " . $resultGroupsAttribute);
                                    }
                                }
                            }

                            if (strlen($groupName) > 0) {
                                $this->logger->debug("Groupes fonctionels :" . $groupName);
                                $groupsArray[] = $groupName;
                            }
                        }
                    }
                }
                
				if ($addUser) {
					foreach ($arrayGroupsAttrPedagogic as $groupsAttrPedagogic) {
						if (array_key_exists("field", $groupsAttrPedagogic) && isset($m[strtolower($groupsAttrPedagogic["field"])][0]) && strlen($groupsAttrPedagogic["field"]) > 0 &&
							array_key_exists("filter", $groupsAttrPedagogic) && strlen($groupsAttrPedagogic["filter"]) > 0 &&
							array_key_exists("naming", $groupsAttrPedagogic) && strlen($groupsAttrPedagogic["naming"]) > 0
						) {
							$pedagogicField = $groupsAttrPedagogic["field"];

							# Cycle all groups of the user
							for ($j = 0; $j < $m[strtolower($pedagogicField)]["count"]; $j++) {
								$attrPedagogicStr = $m[strtolower($pedagogicField)][$j];
								$pedagogicFilter = $groupsAttrPedagogic["filter"];
								$pedagogicNaming = $groupsAttrPedagogic["naming"];

								if (preg_match_all("/" . $pedagogicFilter . "/si", $attrPedagogicStr, $groupPedagogicMatches)) {
									# Check if user has MAP_GROUPS attribute
									if (isset($attrPedagogicStr) && strpos($attrPedagogicStr, "$")) {
										$addUser = TRUE; # Only add user if the group has a MAP_GROUPS attribute
										$arrayGroupNamePedagogic = explode('$', $attrPedagogicStr);

										$groupCn = array_shift($arrayGroupNamePedagogic);

										# Retrieve the MAP_GROUPS_FIELD attribute of the group
										$groupAttr = $this->getLdapSearch($groupCn);
										$groupName = '';

										$regexGabarits = '/\$\{(.*?)\}/i';

										preg_match_all($regexGabarits, $pedagogicNaming, $matches, PREG_SET_ORDER, 0);
										$sprintfArray = [];
										foreach ($matches as $match) {

											$pedagogicNaming = preg_replace('/\$\{' . $match[1] . '\}/i', '%s', $pedagogicNaming, 1);
											if (is_numeric($match[1])) {
												$sprintfArray[] = $groupPedagogicMatches[$match[1]][0];
											}
											else {
												if (strtolower($match[1]) === 'nometablissement') {
													$sprintfArray[] = $this->getEstablishmentNameFromUAI($groupAttr['entstructureuai'][0]);
												}
												elseif (array_key_exists(strtolower($match[1]), $groupAttr) && $groupAttr[strtolower($match[1])]["count"] > 0) {
													$sprintfArray[] = $groupAttr[strtolower($match[1])][0];
												}
												else {
													$this->logger->debug("Groupes pédagogique : l'attibut : " . strtolower($match[1]) . " n'existe pas dans les groupe édagogique");
												}
											}
										}
										$groupName = sprintf($pedagogicNaming, ...$sprintfArray);
                                        if (array_key_exists('entstructureuai', $groupAttr) && $groupAttr['entstructureuai']['count'] > 0) {
                                            $idEtablishement = $this->getIdEtablissementFromUai($groupAttr['entstructureuai'][0]);
                                            if ($groupName && strlen($groupName) > 0) {
												$groupName = $this->normalizedGroupeName($groupName);
                                                $this->addEtablissementAsso($idEtablishement, $groupName);
                                            }
                                            $this->addEtablissementAsso($idEtablishement, $employeeID);
                                            $idsEtabUser[] = $idEtablissement;
                                        }

										if ($groupName && strlen($groupName) > 0) {
											$this->logger->debug("Groupes pédagogique : " . $groupName);
											$groupsArray[] = $groupName;
										}
									}
								}
								else {
									$this->logger->debug("Groupes pédagogique : la regex " . $pedagogicFilter . " ne match pas avec le groupe " . $attrPedagogicStr);
								}
							}
						}
					}
				}
                # Fill the users array only if we have an employeeId and addUser is true
                if (isset($employeeID) && $addUser) {
                    $this->logger->info("Groupes pédagogique : Ajout de l'utilisateur avec id  : " . $employeeID);
                    $uaiCourant = '';
                    if (array_key_exists('escouaicourant', $m) && $m['escouaicourant']['count'] > 0) {
                        $uaiCourant = $m['escouaicourant'][0];
                    }
                    if (array_key_exists('escosiren', $m) && $m['escosiren']['count'] > 0) {
                        $this->addEtablissementAssoForAllEscosiren($m['escosiren'], $employeeID);
                        $idsEtabUser = array_merge($idsEtabUser, $this->getIdsEtablissementFromSirenArray($m['escosiren']));
                    }
                    $this->removeObsoleteAssoUaiUser(array_unique($idsEtabUser), $employeeID);
                    if ($this->config->getUserValue($employeeID, 'core', 'enabled') === 'false') {
                        $this->config->setUserValue($employeeID, 'core', 'enabled', 'true');
                    }
                    $this->merger->mergeUsers($users, ['uid' => $employeeID, 'displayName' => $displayName, 'email' => $mail, 'quota' => $quota, 'groups' => $groupsArray, 'enable' => $enable, 'dn' => $dn, 'uai_courant' => $uaiCourant], $mergeAttribute, $preferEnabledAccountsOverDisabled, $primaryAccountDnStartswWith);
                }
				
				/* pl mettre l'historique a jours. */
				$etat = false;
				$alreadyExist= false;
				
                
                if (isset($m[$enableAttribute][0]) && $employeeID) {
					$etat = $m[$enableAttribute][0];
					$etabRatach = $m['entpersonstructrattach'][0];
					if ($etat && $etabRatach ) {
						$alreadyExists =$this->userHistoryExists($employeeID);
						if ($alreadyExists || $addUser) {
							if (preg_match('/ENTStructureSIREN=(\d+)/', $etabRatach, $grp)) { 
								$this->saveUserHistory($employeeID, $displayName, $alreadyExists, $addUser, $etat, $date, $grp[1]);
							} else {
								$this->logger->error("compte $employeeID sans siren de ratachement : $etabRatach \n");
							}
						}
					} else {
						if ($adduser) {
							$this->logger->error("compte ajouté ($employeeID) sans etat ($etat)  ou structure de ratachement ($etabRatach). \n");
						}
					}
                }
            }
        }

        $this->logger->info("Users have been retrieved : " . count($users));

        return $users;
    }

	protected function normalizedGroupeName($groupName) {
	/*	$name = str_replace(aray('é','è','ê','ë'),'e', $groupName);
		$name = str_replace(aray('É','È','Ê','Ë'),'E', $name);
		$name = str_replace(aray('à', 'â', 'ä'), 'a', $name);
		$name = str_replace(aray('À', 'Â', 'Ä'), 'A', $name);
		* $name = strtr($groupName,'àáâãäçèéêëìíîïñòóôõöùúûüýÿÀÁÂÃÄÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ','aaaaaceeeeiiiinooooouuuuyyAAAAACEEEEIIIINOOOOOUUUUY');
	*/	
		    $accents = array("à","á","â","ã","ä","ç","è","é","ê","ë","ì","í","î","ï","ñ","ò","ó","ô","õ","ö","ù","ú","û","ü","ý","ÿ","À","Á","Â","Ã","Ä","Ç","È","É","Ê","Ë","Ì","Í","Î","Ï","Ñ","Ò","Ó","Ô","Õ","Ö","Ù","Ú","Û","Ü","Ý");
		$sansAccents = array("a","a","a","a","a","c","e","e","e","e","i","i","i","i","n","o","o","o","o","o","u","u","u","u","y","y","A","A","A","A","A","C","E","E","E","E","I","I","I","I","N","O","O","O","O","O","U","U","U","U","Y");
		$name = str_replace($accents, $sansAccents, $groupName);
		return preg_replace("/[^a-zA-Z0-9\.\-_ @]+/", "", $name);
		
	}
	
	protected function userHistoryExists( $uid) {
		$qbHist = $this->db->getQueryBuilder();
        $qbHist->select('uid')
            ->from('recia_user_history')
            ->where($qbHist->expr()->eq('uid', $qbHist->createNamedParameter($uid)))
        ;
        $result = $qbHist->execute();
        $uids = $result->fetchAll();
        return count($uids) > 0;
	}
	
	protected function saveUserHistory($uid, $name, $isExists, $isAdded, $etat, $date, $siren){
		$qbHist = $this->db->getQueryBuilder();
		
		$del = (stripos($etat, 'DELETE') !== false) ? 1 : 0;
		
		if ($isExists) {
			$qbHist->update('recia_user_history')
				->set('eta', $qbHist->createNamedParameter($etat))
				->set('isadd', $qbHist->createNamedParameter($isAdded ? : 0))
				->set('dat', $qbHist->createNamedParameter($date))
				->set('siren', $qbHist->createNamedParameter($siren))
				->set('isdel', $qbHist->createNamedParameter($del))
				->set('name', $qbHist->createNamedParameter($name))
				->where( $qbHist->expr()->eq('uid' , $qbHist->createNamedParameter($uid))) ;
			$qbHist->execute();
				
		} else {
			$qbHist->insert('recia_user_history')
				->values([
					'uid' => $qbHist->createNamedParameter($uid),
					'eta' => $qbHist->createNamedParameter($etat),
					'isadd' => $qbHist->createNamedParameter($isAdded ? 1: 0),
					'dat' => $qbHist->createNamedParameter($date),
					'siren' => $qbHist->createNamedParameter($siren),
					'isdel' => $qbHist->createNamedParameter($del),
					'name' => $qbHist->createNamedParameter($name),
				]);
			$qbHist->execute();
		}
	}
    /**
     *
     * @param $currentEtablishementIds
     * @param $uid
     * @return void
     */
    protected function removeObsoleteAssoUaiUser($currentEtablishementIds, $uid)
    {
        $qbAsso = $this->db->getQueryBuilder();
        $qbAsso->select('id_etablissement')
            ->from('asso_uai_user_group')
            ->where($qbAsso->expr()->eq('user_group', $qbAsso->createNamedParameter($uid)))
        ;
        $result = $qbAsso->execute();
        $etablissement = $result->fetchAll();

        if (sizeof($etablissement) !== 0) {
            $idsEtab = array_unique(array_map(function ($asso) {
                return $asso['id_etablissement'];
            }, $etablissement));
            $idsToDelete = array_diff($idsEtab, $currentEtablishementIds);

            foreach ($idsToDelete as $idToDelete) {
                $qbDelete = $this->db->getQueryBuilder();
                $qbDelete->delete('asso_uai_user_group')
                    ->where($qbDelete->expr()->eq('id_etablissement', $qbDelete->createNamedParameter($idToDelete)))
                    ->andWhere($qbDelete->expr()->eq('user_group', $qbDelete->createNamedParameter($uid)))
                ;
                $qbDelete->execute();
            }
        }
    }

    /**
     *
     * @param $escosirenArray
     * @return array
     */
    protected function getIdsEtablissementFromSirenArray($escosirenArray)
    {
        $idsEtab = [];
        foreach ($escosirenArray as $key => $escosiren) {
            if ($key !== "count") {
                $idEtablishement = $this->getIdEtablissementFromSiren($escosiren);
                if (!is_null($idEtablishement)) {
                    $idsEtab[] = $idEtablishement;
                }
            }
        }
        return $idsEtab;
    }

    /**
     *
     * @param $escosirenArray
     * @param $employeeID
     */
    protected function addEtablissementAssoForAllEscosiren($escosirenArray, $employeeID)
    {
        foreach ($escosirenArray as $key => $escosiren) {
            if ($key !== "count") {
                $idEtablishement = $this->getIdEtablissementFromSiren($escosiren);
                if (!is_null($idEtablishement)) {
                    $this->addEtablissementAsso($idEtablishement, $employeeID);
                }
            }
        }
    }

    /**
     *
     * @param $uai
     * @return mixed|null
     */
    protected function getEstablishmentNameFromUAI($uai)
    {
        if (!is_null($uai)) {
            $qbEtablissement = $this->db->getQueryBuilder();
            $qbEtablissement->select('name')
                ->from('etablissements')
                ->where($qbEtablissement->expr()->eq('uai', $qbEtablissement->createNamedParameter($uai)))
            ;
            $result = $qbEtablissement->execute();
            $etablissement = $result->fetchAll();

            if (sizeof($etablissement) !== 0) {
                return $etablissement[0]['name'];
            }
        }
        return null;
    }


    /**
     * Ajout d'un établissement si il n'existe pas dans la bdd
     *
     * @param $uai
     * @param $name
     * @param $siren
     * @return mixed|null
     */
    protected function addEtablissement($uai, $name, $siren)
    {
        if (!is_null($name)) {
            $qbEtablissement = $this->db->getQueryBuilder();
            $qbEtablissement->select('*')
                ->from('etablissements')
                ->where($qbEtablissement->expr()->eq('siren', $qbEtablissement->createNamedParameter($siren)))
                ->orWhere($qbEtablissement->expr()->eq('uai', $qbEtablissement->createNamedParameter($uai)));
            $result = $qbEtablissement->execute();
            $etablissement = $result->fetchAll();

            if (sizeof($etablissement) === 0) {
                $insertEtablissement = $this->db->getQueryBuilder();
                $insertEtablissement->insert('etablissements')
                    ->values([
                        'uai' => $insertEtablissement->createNamedParameter($uai),
                        'name' => $insertEtablissement->createNamedParameter($name),
                        'siren' => $insertEtablissement->createNamedParameter($siren),
                    ]);
                $insertEtablissement->execute();
            }
            $newEtablissement = $this->db->getQueryBuilder();
            $newEtablissement->select('id')
                ->from('etablissements')
                ->where($newEtablissement->expr()->eq('siren', $newEtablissement->createNamedParameter($siren)))
                ->orWhere($newEtablissement->expr()->eq('uai', $newEtablissement->createNamedParameter($uai)));
            $result = $newEtablissement->execute();
            $newEtab = $result->fetchAll()[0];
            return $newEtab["id"];
        }
        return null;
    }

    /**
     * Récupération de l'id d'un etablissement depuis son uai
     *
     * @param $uai
     * @return mixed
     */
    protected function getIdEtablissementFromUai($uai)
    {
        if (!is_null($uai)) {
            $qb = $this->db->getQueryBuilder();
            $qb->select('id')
                ->from('etablissements')
                ->where($qb->expr()->eq('uai', $qb->createNamedParameter($uai)));
            $result = $qb->execute();
            $idEtabs = $result->fetchAll()[0];
            return $idEtabs["id"];
        }
    }

    /**
     * Récupération de l'id d'un etablissement depuis son siren
     *
     * @param $uai
     * @return mixed
     */
    protected function getIdEtablissementFromSiren($siren)
    {
        if (!is_null($siren)) {
            try {
				$qb = $this->db->getQueryBuilder();
				$qb->select('id')
					->from('etablissements')
					->where($qb->expr()->eq('siren', $qb->createNamedParameter($siren)));
				$result = $qb->execute();
            
				$idEtabs = $result->fetchAll()[0];
				return $idEtabs["id"];
			} catch (\Exception $e) {
				$this->logger->error(print_r($e, TRUE) . "  [Siren = $siren] ");
			}
        }
        return null;
    }

    /**
     * Ajout d'un établissement et d'une asso id_etablissement -> user/groups si il n'existe pas dans la bdd
     *
     * @param $idEtablissement
     * @param $groupUserId
     */
    protected function addEtablissementAsso($idEtablissement, $groupUserId)
    {
		
        if (!is_null($groupUserId) && !empty($groupUserId) && !is_null($idEtablissement)) {
            $qb = $this->db->getQueryBuilder();
            $qb->select('*')
                ->from('asso_uai_user_group')
                ->where($qb->expr()->eq('id_etablissement', $qb->createNamedParameter($idEtablissement)))
                ->andWhere($qb->expr()->eq('user_group', $qb->createNamedParameter($groupUserId)));
            $result = $qb->execute();
            $assoOaiUserGroup = $result->fetchAll();
            if (sizeof($assoOaiUserGroup) === 0) {
                $insertAsso = $this->db->getQueryBuilder();
                $insertAsso->insert('asso_uai_user_group')
                    ->values([
                        'id_etablissement' => $insertAsso->createNamedParameter($idEtablissement),
                        'user_group' => $insertAsso->createNamedParameter($groupUserId),
                    ]);
                $insertAsso->execute();
            }
        }
    }



    /**
     * List ldap entries in the base dn
     *
     * @param string $object_dn
     * @param $filter
     * @param array $keepAtributes
     * @param $pageSize
     * @return array
     */
    protected function getLdapList($object_dn, $filter, $keepAtributes, $pageSize)
    {
        if (!is_null($this->ldapFilter)) {
			  $filter = "(&" . $this->ldapFilter . $filter . ")";
        }
		$this->logger->info('ldap filter = ' . $filter);

        $cookie = '';
        $members = [];

        do {

            // Query Group members
            ldap_control_paged_result($this->ldapConnection, $pageSize, false, $cookie);
//supprimer ldap_control_paged_result remplacer  par param array $controls dans ldap_search  https://www.php.net/manual/en/function.ldap-search.php
            $results = ldap_search($this->ldapConnection, $object_dn, $filter, $keepAtributes/*, array("member;range=$range_start-$range_end")*/) or die('Error searching LDAP: ' . ldap_error($this->ldapConnection));
            $members[] = ldap_get_entries($this->ldapConnection, $results);

            ldap_control_paged_result_response($this->ldapConnection, $results, $cookie);

        } while ($cookie !== null && $cookie != '');

        // Return sorted member list
        sort($members);

        return $members;
    }


    /**
     * @param string $user_dn
     * @param bool $keep
     * @return array Attribute list
     */
    protected function getLdapAttributes($user_dn, $keep = false)
    {
        if (!isset($this->ldapConnection)) die('Error, no LDAP connection established');
        if (empty($user_dn)) die('Error, no LDAP user specified');

        // Disable pagination setting, not needed for individual attribute queries
        ldap_control_paged_result($this->ldapConnection, 1);

        // Query user attributes
        $results = (($keep) ? ldap_search($this->ldapConnection, $user_dn, 'cn=*', $keep) : ldap_search($this->ldapConnection, $user_dn, 'cn=*'));
        if (ldap_error($this->ldapConnection) == "No such object") {
            return [];
        }
        elseif (ldap_error($this->ldapConnection) != "Success") {
            die('Error searching LDAP: ' . ldap_error($this->ldapConnection) . " and " . $user_dn);
        }

        $attributes = ldap_get_entries($this->ldapConnection, $results);

        $this->logger->debug("AD attributes successfully retrieved.");

        // Return attributes list
        if (isset($attributes[0])) return $attributes[0];
        else return array();
    }

    /**
     * @param string $groupCn
     * @param string $filter
     * @param bool $keep
     * @return array Attribute list
     */
    protected function getLdapSearch($groupCn, $filter = 'objectClass=*',$keep = false)
    {
        if (!isset($this->ldapConnection)) die('Error, no LDAP connection established');
        if (empty($groupCn)) die('Error, no LDAP user specified');

        // Disable pagination setting, not needed for individual attribute queries
        ldap_control_paged_result($this->ldapConnection, 1);

        // Query user attributes
        $results = (($keep) ? ldap_search($this->ldapConnection, $groupCn, $filter, $keep) : ldap_search($this->ldapConnection, $groupCn, $filter));
        if (ldap_error($this->ldapConnection) == "No such object") {
            return [];
        }
        elseif (ldap_error($this->ldapConnection) != "Success") {
            die('Error searching LDAP: ' . ldap_error($this->ldapConnection) . " and " . $groupCn);
        }

        $attributes = ldap_get_entries($this->ldapConnection, $results);

        $this->logger->debug("AD attributes successfully retrieved.");

        // Return attributes list
        if (isset($attributes[0])) return $attributes[0];
        else return array();
    }

    /**
     * Connect ldap
     *
     * @return bool|resource
     * @throws \Exception
     */
    protected function ldapConnect()
    {
        try {

            $host = $this->config->getAppValue($this->appName, 'cas_import_ad_host');

            $this->ldapConnection = ldap_connect($this->config->getAppValue($this->appName, 'cas_import_ad_protocol') . $host . ":" . $this->config->getAppValue($this->appName, 'cas_import_ad_port')) or die("Could not connect to " . $host);

            ldap_set_option($this->ldapConnection, LDAP_OPT_PROTOCOL_VERSION, 3);
            ldap_set_option($this->ldapConnection, LDAP_OPT_REFERRALS, 0);
            ldap_set_option($this->ldapConnection, LDAP_OPT_NETWORK_TIMEOUT, 10);

            $this->logger->info("AD connected successfully.");

            return $this->ldapConnection;
        } catch (\Exception $e) {

            throw $e;
        }
    }

    /**
     * Bind ldap
     *
     * @throws \Exception
     */
    protected function ldapBind()
    {
        try {

            if ($this->ldapConnection) {
                $ldapIsBound = ldap_bind($this->ldapConnection, $this->config->getAppValue($this->appName, 'cas_import_ad_user'), $this->config->getAppValue($this->appName, 'cas_import_ad_password'));

                if (!$ldapIsBound) {

                    throw new \Exception("LDAP bind failed. Error: " . ldap_error($this->ldapConnection));
                } else {

                    $this->logger->info("AD bound successfully.");
                }
            }
        } catch (\Exception $e) {

            throw $e;
        }
    }

    /**
     * Unbind ldap
     *
     * @throws \Exception
     */
    protected function ldapUnbind()
    {

        try {

            ldap_unbind($this->ldapConnection);

            $this->logger->info("AD unbound successfully.");
        } catch (\Exception $e) {

            throw $e;
        }
    }

    /**
     * Close ldap connection
     *
     * @throws \Exception
     */
    protected function ldapClose()
    {
        try {

            ldap_close($this->ldapConnection);

            $this->logger->info("AD connection closed successfully.");
        } catch (\Exception $e) {

            throw $e;
        }
    }

    /**
     * @param array $exportData
     */
    public function exportAsCsv(array $exportData)
    {

        $this->logger->info("Exporting users to .csv …");

        $fp = fopen('accounts.csv', 'wa+');

        fputcsv($fp, ["UID", "displayName", "email", "quota", "groups", "enabled"]);

        foreach ($exportData as $fields) {

            for ($i = 0; $i < count($fields); $i++) {

                if (is_array($fields[$i])) {

                    $fields[$i] = $this->multiImplode($fields[$i], " ");
                }
            }

            fputcsv($fp, $fields);
        }

        fclose($fp);

        $this->logger->info("CSV export finished.");
    }

    /**
     * @param array $exportData
     */
    public function exportAsText(array $exportData)
    {

        $this->logger->info("Exporting users to .txt …");

        file_put_contents('accounts.txt', serialize($exportData));

        $this->logger->info("TXT export finished.");
    }

    /**
     * @param array $array
     * @param string $glue
     * @return bool|string
     */
    private function multiImplode($array, $glue)
    {
        $ret = '';

        foreach ($array as $item) {
            if (is_array($item)) {
                $ret .= $this->multiImplode($item, $glue) . $glue;
            } else {
                $ret .= $item . $glue;
            }
        }

        $ret = substr($ret, 0, 0 - strlen($glue));

        return $ret;
    }
}
