<?php

namespace OCA\LdapImporter\User;

use OC\User\Database;
use OCA\LdapImporter\Exception\PhpCas\PhpUserCasLibraryNotFoundException;
use OCA\LdapImporter\Service\AppService;
use OCA\LdapImporter\Service\LoggingService;
use OCA\LdapImporter\Service\UserService;
use OCP\IConfig;
use OCP\IUser;
use OCP\IUserBackend;
use OCP\IUserManager;
use \OCP\User\Backend\ICheckPasswordBackend;
use OCP\UserInterface;


/**
 * Class Backend
 *
 * @package OCA\LdapImporter\User
 */
class NextBackend extends Database implements UserInterface, IUserBackend, ICheckPasswordBackend, UserCasBackendInterface
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
     * @var \OCP\IUserManager;
     */
    protected $userManager;

    /**
     * @var \OCA\LdapImporter\Service\UserService $userService
     */
    protected $userService;


    /**
     * Backend constructor.
     *
     * @param string $appName
     * @param IConfig $config
     * @param LoggingService $loggingService
     * @param AppService $appService
     * @param IUserManager $userManager
     * @param UserService $userService
     */
    public function __construct($appName, IConfig $config, LoggingService $loggingService, AppService $appService, IUserManager $userManager, UserService $userService)
    {

        parent::__construct();
        $this->appName = $appName;
        $this->loggingService = $loggingService;
        $this->appService = $appService;
        $this->config = $config;
        $this->userManager = $userManager;
        $this->userService = $userService;
    }


    /**
     * Backend name to be shown in user management
     *
     * @return string the name of the backend to be shown
     */
    public function getBackendName()
    {

        return "LDAPIMPORTER";
    }


    /**
     * Check the password
     *
     * @param string $loginName
     * @param string $password
     * @return string|bool The users UID or false
     */
    public function checkPassword(string $loginName, string $password)
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

            if ($loginName === FALSE) {

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
                if (!$this->userManager->userExists($loginName) && boolval($this->config->getAppValue($this->appName, 'cas_autocreate'))) {

                    $this->loggingService->write(\OCA\LdapImporter\Service\LoggingService::DEBUG, 'phpCAS creating a new user with UID: ' . $loginName);

                    try {

                        $createUser = $this->userService->create($loginName, $this);

                        if (!$createUser instanceof IUser) {

                            $createUser = FALSE;
                        }
                    } catch (\Exception $e) {

                        $createUser = FALSE;
                    }
                } elseif (!$this->userManager->userExists($loginName) && !boolval($this->config->getAppValue($this->appName, 'cas_autocreate'))) {

                    $this->loggingService->write(\OCA\LdapImporter\Service\LoggingService::DEBUG, 'phpCAS no new user has been created.');

                    $createUser = FALSE;
                }

                // Finalize check
                if ($casUid === $loginName && $isAuthorized && $createUser) {

                    $this->loggingService->write(\OCA\LdapImporter\Service\LoggingService::DEBUG, 'phpCAS user password has been checked.');

                    return $loginName;
                }
            }

            return FALSE;
        } else {

            $this->loggingService->write(\OCA\LdapImporter\Service\LoggingService::ERROR, 'phpCAS has not been initialized.');
            return FALSE;
        }
    }

    /**
     * Get the real UID
     *
     * @param string $uid
     * @return string
     *
     * @since 1.8.0
     */
    public function getRealUID(string $uid): string
    {

        return $uid;
    }
}
