<?php


namespace OCA\LdapImporter\Service\Merge;


/**
 * Interface MergerInterface
 * @package LdapImporter\Service\Merge
 *
 */
interface MergerInterface
{

    public function mergeUsers(array &$userStack, array $userToMerge, $merge, $preferEnabledAccountsOverDisabled, $primaryAccountDnStartswWith);
}