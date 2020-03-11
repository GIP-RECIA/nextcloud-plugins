<?php


namespace OCA\LdapImporter\Service\Import;

use Psr\Log\LoggerInterface;


/**
 * Interface ImporterInterface
 * @package LdapImporter\Service\Import
 */
interface ImporterInterface
{

    /**
     * @param LoggerInterface $logger
     */
    public function init(LoggerInterface $logger);

    public function close();

    public function getUsers();

    /**
     * @param array $userData
     */
    public function exportAsCsv(array $userData);
}