<?php

namespace OCA\LdapImporter\User;

use OC\User\Database;
use OCA\LdapImporter\Exception\PhpCas\PhpUserCasLibraryNotFoundException;
use OCA\LdapImporter\Service\AppService;
use OCA\LdapImporter\Service\LoggingService;
use OCP\IConfig;
use OCP\IUserBackend;
use OCP\IUserManager;
use OCP\User\IProvidesDisplayNameBackend;
use OCP\User\IProvidesHomeBackend;
use OCP\UserInterface;


/**
 * Class Backend
 *
 * @package OCA\LdapImporter\User
 *
 * @author Felix Rupp <kontakt@felixrupp.com>
 * @copyright Felix Rupp <kontakt@felixrupp.com>
 *
 * @since 1.4.0
 */
class Backend extends Database implements UserInterface, IUserBackend, IProvidesHomeBackend, IProvidesDisplayNameBackend, UserCasBackendInterface
{

    /**
     * @var string
     */
    protected $appName;

    /**
     * @var IConfig
     */
    protected $config;

    /**
     * @var \OCA\LdapImporter\Service\LoggingService $loggingService
     */
    protected $loggingService;

    /**
     * @var \OCA\LdapImporter\Service\AppService $appService
     */
    protected $appService;


    /**
     * @var \OCP\IUserManager $userManager
     */
    protected $userManager;


    /**
     * Backend constructor.
     * @param string $appName
     * @param IConfig $config
     * @param LoggingService $loggingService
     * @param AppService $appService
     * @param IUserManager $userManager
     */
    public function __construct($appName, IConfig $config, LoggingService $loggingService, AppService $appService, IUserManager $userManager)
    {

        parent::__construct();
        $this->appName = $appName;
        $this->loggingService = $loggingService;
        $this->appService = $appService;
        $this->config = $config;
        $this->userManager = $userManager;
    }


    /**
     * Backend name to be shown in user management
     * @return string the name of the backend to be shown
     */
    public function getBackendName()
    {

        return "CAS";
    }


    /**
     * @param string $uid
     * @param string $password
     * @return string|bool The users UID or false
     */
    public function checkPassword($uid, $password)
    {

        if (!$this->appService->isCasInitialized()) {

            try {

                $this->appService->init();
            } catch (PhpUserCasLibraryNotFoundException $e) {

                $this->loggingService->write(\OCA\LdapImporter\Service\LoggingService::ERROR, 'Fatal error with code: ' . $e->getCode() . ' and message: ' . $e->getMessage());

                return FALSE;
            }
        }

        if (\phpCAS::isInitialized()) {

            if ($uid === FALSE) {

                $this->loggingService->write(\OCA\LdapImporter\Service\LoggingService::ERROR, 'phpCAS returned no user.');
            }

            if (\phpCAS::isAuthenticated()) {

                $casUid = \phpCAS::getUser();

                $isAuthorized = TRUE;
                $createUser = TRUE;


                # Check if user may be authorized based on groups or not
                $cas_access_allow_groups = $this->config->getAppValue($this->appName, 'cas_access_allow_groups');
                if (is_string($cas_access_allow_groups) && strlen($cas_access_allow_groups) > 0) {

                    $cas_access_allow_groups = explode(',', $cas_access_allow_groups);
                    $casAttributes = \phpCAS::getAttributes();
                    $casGroups = array();
                    $groupMapping = $this->config->getAppValue($this->appName, 'cas_group_mapping');

                    # Test if an attribute parser added a new dimension to our attributes array
                    if (array_key_exists('attributes', $casAttributes)) {

                        $newAttributes = $casAttributes['attributes'];

                        unset($casAttributes['attributes']);

                        $casAttributes = array_merge($casAttributes, $newAttributes);
                    }

                    # Test for mapped attribute from settings
                    if (array_key_exists($groupMapping, $casAttributes)) {

                        $casGroups = (array)$casAttributes[$groupMapping];
                    } # Test for standard 'groups' attribute
                    else if (array_key_exists('groups', $casAttributes)) {

                        $casGroups = (array)$casAttributes['groups'];
                    }

                    $isAuthorized = FALSE;

                    foreach ($casGroups as $casGroup) {

                        if (in_array($casGroup, $cas_access_allow_groups)) {

                            $this->loggingService->write(LoggingService::DEBUG, 'phpCas CAS users login has been authorized with group: ' . $casGroup);

                            $isAuthorized = TRUE;
                        } else {

                            $this->loggingService->write(LoggingService::DEBUG, 'phpCas CAS users login has not been authorized with group: ' . $casGroup . ', because the group was not in allowedGroups: ' . implode(", ", $cas_access_allow_groups));
                        }
                    }
                }


                // Autocreate user if needed or create a new account in CAS Backend
                if (!$this->userManager->userExists($uid) && boolval($this->config->getAppValue($this->appName, 'cas_autocreate'))) {

                    $this->loggingService->write(\OCA\LdapImporter\Service\LoggingService::DEBUG, 'phpCAS creating a new user with UID: ' . $uid);
                } elseif (!$this->userManager->userExists($uid) && !boolval($this->config->getAppValue($this->appName, 'cas_autocreate'))) {

                    $this->loggingService->write(\OCA\LdapImporter\Service\LoggingService::DEBUG, 'phpCAS no new user has been created.');

                    $createUser = FALSE;
                }

                // Finalize check
                if ($casUid === $uid && $isAuthorized && $createUser) {

                    $this->loggingService->write(\OCA\LdapImporter\Service\LoggingService::DEBUG, 'phpCAS user password has been checked.');

                    return $uid;
                }
            }

            $this->loggingService->write(\OCA\LdapImporter\Service\LoggingService::DEBUG, 'phpCAS user password has been checked, user not logged in.');

            return FALSE;
        } else {

            $this->loggingService->write(\OCA\LdapImporter\Service\LoggingService::ERROR, 'phpCAS has not been initialized.');
            return FALSE;
        }
    }


    /**
     * @param string $uid
     * @return bool|string
     */
    public function getDisplayName($uid)
    {

        $displayName = $uid;

        if (!$this->appService->isCasInitialized()) {

            try {

                $this->appService->init();
            } catch (PhpUserCasLibraryNotFoundException $e) {

                $this->loggingService->write(\OCA\LdapImporter\Service\LoggingService::ERROR, 'Fatal error with code: ' . $e->getCode() . ' and message: ' . $e->getMessage());

                return $displayName;
            }
        }

        if (\phpCAS::isInitialized()) {

            if (\phpCAS::isAuthenticated()) {

                $casAttributes = \phpCAS::getAttributes();

                # Test if an attribute parser added a new dimension to our attributes array
                if (array_key_exists('attributes', $casAttributes)) {

                    $newAttributes = $casAttributes['attributes'];

                    unset($casAttributes['attributes']);

                    $casAttributes = array_merge($casAttributes, $newAttributes);
                }

                // DisplayName
                $displayNameMapping = $this->config->getAppValue($this->appName, 'cas_displayName_mapping');

                $displayNameMappingArray = explode("+", $displayNameMapping);

                $displayName = '';

                foreach ($displayNameMappingArray as $displayNameMapping) {

                    if (array_key_exists($displayNameMapping, $casAttributes)) {

                        $displayName .= $casAttributes[$displayNameMapping] . " ";
                    }
                }

                $displayName = trim($displayName);

                if ($displayName === '' && array_key_exists('displayName', $casAttributes)) {

                    $displayName = $casAttributes['displayName'];
                }
            }
        }

        return $displayName;
    }
}
