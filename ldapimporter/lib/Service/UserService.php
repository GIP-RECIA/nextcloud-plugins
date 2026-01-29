<?php

declare(strict_types=1);

namespace OCA\LdapImporter\Service;

use OCA\LdapImporter\User\Backend;
use OCP\IGroup;
use OCP\IGroupManager;
use OCP\IUser;
use OCP\IUserManager;
use OCP\Security\ISecureRandom;
use Psr\Log\LoggerInterface;

class UserService
{
    public function __construct(
        private IGroupManager $groupManager,
        private IUserManager $userManager,
        private ISecureRandom $secureRandom,
        private LoggerInterface $logger
    ) {}

    /**
     * @param string $userId
     * @param Backend $backend
     * @return boolean|IUser the created user or false
     */
    public function create($userId, Backend $backend)
    {
        $randomPassword = $this->getNewPassword();

        return $this->userManager->createUserFromBackend($userId, $randomPassword, $backend);
    }

    /**
     * Gets an array of groups and will try to add the group to OC and then add the user to the groups.
     *
     * @param IUser $user
     * @param string|array $groups
     * @param string|array $protectedGroups
     * @param bool $justCreated
     */
    public function updateGroups($user, $groups, $protectedGroups = '', $justCreated = false)
    {

        $groupSuffix = ':LDAP';
        if (is_string($groups)) $groups = explode(",", $groups);
        if (is_string($protectedGroups)) $protectedGroups = explode(",", $protectedGroups);

        $uid = $user->getUID();

        if (!$justCreated) {
            $oldGroups = $this->groupManager->getUserGroups($user);
            foreach ($oldGroups as $group) {
                if ($group instanceof IGroup) {
                    $groupId = $group->getGID();
                    $pos = strpos($groupId, $groupSuffix);
                    if ($pos) {
                        $groupId = substr($groupId, 0, $pos);
                        if (!in_array($groupId, $protectedGroups) && !in_array($groupId, $groups)) {
                            $group->removeUser($user);
                            $this->logger->debug("Removed '" . $uid . "' from the group '" . $groupId . "'");
                            #Util::writeLog('cas', 'Removed "' . $uid . '" from the group "' . $groupId . '"', LoggingService::DEBUG);
                        }
                    }
                }
            }
        }

        foreach ($groups as $group) {
            $groupObject = NULL;

            # Use default filter
            $group = preg_replace("/[^a-zA-Z0-9\.\-_ @]+/", "", $group);

            # Filter length to max 64 chars
            if (strlen($group) > 64) {
                $group = substr($group, 0, 63) . "…";
            }
            $groupId = $group . $groupSuffix;

            if (!$this->groupManager->isInGroup($uid, $groupId)) {
                if (!$this->groupManager->groupExists($groupId)) {
                    $this->logger->debug('New group to created: ' . $groupId);
                    $groupObject = $this->groupManager->createGroup($groupId);
                    $groupObject->setDisplayName($group);
                    #Util::writeLog('cas', 'New group created: ' . $group, LoggingService::DEBUG);
                } else {
                    $groupObject = $this->groupManager->get($group);
                }

                $groupObject->addUser($user);

                $this->logger->debug("Added '" . $uid . "' to the group '" . $group . "'");
                #Util::writeLog('cas', 'Added "' . $uid . '" to the group "' . $group . '"', LoggingService::DEBUG);
            }
        }
    }

    /**
     * Register User Backend.
     *
     * @param Backend $backend
     */
    public function registerBackend(Backend $backend)
    {
        $this->userManager->registerBackend($backend);
    }

    /**
     * Generate a random PW with special char symbol characters
     *
     * @return string New Password
     */
    protected function getNewPassword()
    {
        $newPasswordCharsLower = $this->secureRandom->generate(8, ISecureRandom::CHAR_LOWER);
        $newPasswordCharsUpper = $this->secureRandom->generate(4, ISecureRandom::CHAR_UPPER);
        $newPasswordNumbers = $this->secureRandom->generate(4, ISecureRandom::CHAR_DIGITS);
        $newPasswordSymbols = $this->secureRandom->generate(4, ISecureRandom::CHAR_SYMBOLS);

        return str_shuffle($newPasswordCharsLower . $newPasswordCharsUpper . $newPasswordNumbers . $newPasswordSymbols);
    }
}
