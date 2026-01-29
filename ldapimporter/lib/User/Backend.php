<?php

declare(strict_types=1);

namespace OCA\LdapImporter\User;

use OC\User\Database;
use OCP\IUserBackend;
use OCP\User\Backend\ICheckPasswordBackend;
use OCP\User\Backend\IGetRealUIDBackend;
use OCP\UserInterface;

class Backend extends Database implements IUserBackend, ICheckPasswordBackend, IGetRealUIDBackend, UserInterface
{
    public function __construct()
    {
        parent::__construct();
    }

    public function getBackendName()
    {
        return "LDAPIMPORTER";
    }

    public function checkPassword(string $loginName, string $password)
    {
        return $loginName;
    }

    public function getRealUID(string $uid): string
    {
        return $uid;
    }
}
