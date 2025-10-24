<?php

namespace OCA\LdapImporter\Panels;

use OCP\IURLGenerator;
use OCP\Settings\IIconSection;

/**
 * Settings section for the administration page
 */
class AdminSection implements IIconSection {

    /** @var IURLGenerator */
    private $urlGenerator;

    /**
     * @param IURLGenerator $urlGenerator - url generator service
     */
    public function __construct(IURLGenerator $urlGenerator) {
        $this->urlGenerator = $urlGenerator;
    }


    /**
     * Path to an 16*16 icons
     *
     * @return strings
     */
    public function getIcon() {
        return $this->urlGenerator->imagePath("ldapimporter", "app.svg");
    }

    /**
     * ID of the section
     *
     * @returns string
     */
    public function getID() {
        return "ldapimporter";
    }

    /**
     * Name of the section
     *
     * @return string
     */
    public function getName() {
        return "Ldap Importer";
    }

    /**
     * Get priority order
     *
     * @return int
     */
    public function getPriority() {
        return 50;
    }
}
