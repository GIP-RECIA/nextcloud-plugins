<?php

declare(strict_types=1);

namespace OCA\LdapImporter\Settings;

use OCA\LdapImporter\AppInfo\Application;
use OCP\AppFramework\Http\TemplateResponse;
use OCP\IAppConfig;
use OCP\Settings\ISettings;

class Admin implements ISettings
{
    private array $params = array(
        'cas_import_ad_protocol' => 'string',
        'cas_import_ad_host' => 'string',
        'cas_import_ad_port' => 'int',
        'cas_import_ad_user' => 'string',
        'cas_import_ad_password' => 'string',
        'cas_import_ad_base_dn' => 'string',
        'cas_import_ad_sync_filter' => 'string',
        'cas_import_ad_sync_pagesize' => 'int',
        'cas_import_map_uid' => 'string',
        'cas_import_map_displayname' => 'string',
        'cas_import_map_email' => 'string',
        'cas_import_map_groups_description' => 'string',
        'cas_import_map_quota' => 'string',
        'cas_import_map_enabled' => 'string',
        'cas_import_map_enabled_and_bitwise' => 'string',
        'cas_import_merge' => 'bool',
        'cas_import_merge_enabled' => 'bool',
        'cas_import_map_dn' => 'string',
        'cas_import_map_dn_filter' => 'string',
        'cas_import_map_groups' => 'string',
        'cas_import_map_regex_name_uai' => 'string',
        'cas_import_map_groups_fonctionel' => 'string',
        'cas_import_map_groups_pedagogic' => 'string'
    );

    public function __construct(
        private IAppConfig $appConfig
    ) {}

    public function getForm(): TemplateResponse
    {
        $parameters = array();
        foreach ($this->params as $name => $type) {
            switch ($type) {
                case 'int':
                    $value = strval($this->appConfig->getValueInt(Application::APP_ID, $name));
                    break;
                case 'bool':
                    $value = strval($this->appConfig->getValueBool(Application::APP_ID, $name));
                    break;
                default:
                    $value = $this->appConfig->getValueString(Application::APP_ID, $name);
            }
            $parameters[$name] = htmlentities($value);
        }

        return new TemplateResponse(Application::APP_ID, 'settings/admin', $parameters, '');
    }

    public function getSection(): string
    {
        return Application::APP_ID;
    }

    public function getPriority(): int
    {
        return 10;
    }
}
