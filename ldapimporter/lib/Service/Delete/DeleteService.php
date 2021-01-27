<?php


namespace OCA\LdapImporter\Service\Delete;

use OC\DB\Connection;
use OCA\LdapImporter\Service\Merge\AdUserMerger;
use OCA\LdapImporter\Service\Merge\MergerInterface;
use OCP\DB\QueryBuilder\IQueryBuilder;
use OCP\IConfig;
use OCP\IDBConnection;
use OCP\IGroupManager;
use OCP\IUserManager;
use Psr\Log\LoggerInterface;


/**
 * Class DeleteService
 * @package LdapImporter\Service\Delete
 *
 * @author Felix Rupp <kontakt@felixrupp.com>
 * @copyright Felix Rupp
 *
 * @since 1.0.0
 */
class DeleteService
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
     * @var \OCP\IGroupManager
     */
    private $groupManager;

    /**
     * @var \OCP\IUserManager
     */
    private $userManager;


    /**
     * AdImporter constructor.
     * @param IConfig $config
     * @param IDBConnection $db
     * @param IGroupManager $groupManager
     * @param IUserManager $userManager
     */
    public function __construct(IConfig $config, IDBConnection $db, IGroupManager $groupManager, IUserManager $userManager)
    {
        $this->config = $config;
        $this->db = $db;
        $this->groupManager = $groupManager;
        $this->userManager = $userManager;
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
     * @return void User data
     */
    public function removedDisabledUsers()
    {
        $queryBuilder = $this->db->getQueryBuilder();
        $queryBuilder->select('userid')
            ->from('preferences')
            ->where($queryBuilder->expr()->eq('appid', $queryBuilder->createNamedParameter('core')))
            ->andWhere($queryBuilder->expr()->eq('configkey', $queryBuilder->createNamedParameter('enabled')))
            ->andWhere($queryBuilder->expr()->eq('configvalue', $queryBuilder->createNamedParameter('false'), IQueryBuilder::PARAM_STR));
        $result = $queryBuilder->execute();
        $disabledUsers = $result->fetchAll();

        foreach ($disabledUsers as $disabledUser) {
            $uidUser = $disabledUser["userid"];
            $qbDelete = $this->db->getQueryBuilder();
            $qbDelete->delete('asso_uai_user_group')
                ->where($qbDelete->expr()->eq('user_group', $qbDelete->createNamedParameter($uidUser)))
            ;
            $qbDelete->execute();
            $user = $this->userManager->get($uidUser);
            if ($user->delete()) {
                $this->logger->info('User with uid :' . $uidUser . ' was deleted');
            }
        }
    }

    /**
     * @param $uaiArray
     * @param $sirenArray
     * @throws \OCP\PreConditionNotMetException
     */
    public function disableDeletedUsers($uaiArray, $sirenArray, $usersUid)
    {
        if (!is_null($usersUid)) {
            foreach ($usersUid as $userUid) {
                if (!$this->userExist($userUid) && $this->userIsInBdd($userUid)) {
                    $this->logger->info("Désactivation de l'utilisateur avec l'uid : " . $userUid);
                    $this->config->setUserValue($userUid, 'core', 'enabled', 'false');
                }
            }

        }
        elseif (is_null($uaiArray) && is_null($sirenArray)) {
            $qb = $this->db->getQueryBuilder();
            $qb->select('uid')
                ->from('users');
            $dbUsers = $qb->execute()->fetchAll();

            $dbIdUsers = array_map(function ($admin) {
                return $admin['uid'];
            }, $dbUsers);

            $ldapUsers = $this->getLdapList(
                $this->config->getAppValue($this->appName, 'cas_import_ad_base_dn'),
                $this->config->getAppValue($this->appName, 'cas_import_ad_sync_filter'),
                ["uid"]
            );

            $ldapIds = [];

            foreach ($ldapUsers[0] as $ldapUser) {
                if (is_array($ldapUser) && array_key_exists("uid", $ldapUser) && count($ldapUser["uid"]) > 1) {
                    $ldapIds[] = $ldapUser["uid"][0];
                }
            }

            // On ajout les administrateur nextcloud dans la liste pour ne pas qu'on les supprime
            $ldapIds = array_merge($ldapIds, $this->getAdminUids());

            $removedUsers = array_diff($dbIdUsers, $ldapIds);

            $this->logger->info("Désactivation des utilisateurs avec l'uid : " . implode(" | ", $removedUsers));
            foreach ($removedUsers as $removedUser) {
                $this->config->setUserValue($removedUser, 'core', 'enabled', 'false');
            }
        }
        else {
            $qb = $this->db->getQueryBuilder();

            $qb->select(['u.uid'])
                ->from('users', 'u')
                ->join('u', 'asso_uai_user_group', 'g', 'u.uid = g.user_group')
                ->join('g', 'etablissements', 'e', 'g.id_etablissement = e.id');
            if (!is_null($uaiArray)) {
                $qb->orWhere($qb->expr()->in('e.uai', $qb->createNamedParameter(
                    $uaiArray,
                    Connection::PARAM_STR_ARRAY
                )));
            }
            if (!is_null($sirenArray)) {
                $qb->orWhere($qb->expr()->in('e.siren', $qb->createNamedParameter(
                    $sirenArray,
                    Connection::PARAM_STR_ARRAY
                )));
            }

            $dbUsers = $qb->execute()->fetchAll();

            $dbIdUsers = array_unique(array_map(function ($admin) {
                return $admin['uid'];
            }, $dbUsers));

            $adminUids = $this->getAdminUids();

            foreach ($dbIdUsers as $dbIdUser) {
                if (!in_array($dbIdUser, $adminUids) && !$this->userExist($dbIdUser)) {
                    $this->config->setUserValue($dbIdUser, 'core', 'enabled', 'false');
                }
            }
        }
    }

    /**
     * @param $uid
     * @return bool
     */
    protected function userIsInBdd($uid)
    {
        $qb = $this->db->getQueryBuilder();
        $qb->select('uid')
            ->from('users')
            ->where($qb->expr()->eq('uid', $qb->createNamedParameter($uid)));
        $dbUsers = $qb->execute()->fetchAll();
        return count($dbUsers) > 0;
    }

    /**
     * @param $uid
     * @return bool
     */
    protected function userExist($uid)
    {
        $user = $this->getLdapSearch($this->config->getAppValue($this->appName, 'cas_import_ad_base_dn'), "(uid=$uid)");
        return count($user) > 0;
    }

    /**
     *
     * @return mixed|null
     */
    protected function getAdminUids()
    {
        $qbAdmin = $this->db->getQueryBuilder();
        $qbAdmin->select('uid')
            ->from('group_admin')
            ->where("gid='admin'")
        ;
        $result = $qbAdmin->execute();
        $admins = $result->fetchAll();

        return array_map(function ($admin) {
            return $admin['uid'];
        }, $admins);
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
    protected function getLdapList($object_dn, $filter, $keepAtributes, $pageSize = null)
    {
        if (!is_null($this->ldapFilter)) {
			  $filter = "(&" . $this->ldapFilter . $filter . ")";
        }
		$this->logger->info('ldap filter = ' . $filter);
        $cookie = '';
        $members = [];

        do {

            // Query Group members
            if (!is_null($pageSize)) {
                ldap_control_paged_result($this->ldapConnection, $pageSize, false, $cookie);
            }

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
