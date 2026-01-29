<?php

declare(strict_types=1);

namespace OCA\LdapImporter\Settings\Sections;

use OCA\LdapImporter\AppInfo\Application;
use OCP\IURLGenerator;
use OCP\Settings\IIconSection;

class Admin implements IIconSection
{
    public function __construct(
        private IURLGenerator $urlGenerator
    ) {}

    public function getIcon(): string
    {
        return $this->urlGenerator->imagePath(Application::APP_ID, 'app-dark.svg');
    }

    public function getID(): string
    {
        return Application::APP_ID;
    }

    public function getName(): string
    {
        return 'LDAP Importer';
    }

    public function getPriority(): int
    {
        return 10;
    }
}
