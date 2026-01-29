<?php

declare(strict_types=1);

namespace OCA\LdapImporter\Controller;

use OCA\LdapImporter\AppInfo\Application;
use OCP\AppFramework\Controller;
use OCP\AppFramework\Http;
// use OCP\AppFramework\Http\Attribute\ApiRoute;
use OCP\AppFramework\Http\Attribute\AuthorizedAdminSetting;
use OCP\AppFramework\Http\JSONResponse;
use OCP\IAppConfig;
use OCP\IRequest;

class SettingsController extends Controller
{
    public function __construct(
        IRequest $request,
        private IAppConfig $appConfig
    ) {
        parent::__construct(Application::APP_ID, $request);
    }

    #[AuthorizedAdminSetting(settings: 'OCA\LdapImporter\Settings\Admin')]
    #[AuthorizedAdminSetting(settings: 'OCA\LdapImporter\Settings\Sections\Admin')]
    // #[ApiRoute(verb: 'POST', url: '/settings/save')]
    public function saveSettings(
        string $cas_import_ad_protocol,
        string $cas_import_ad_host,
        string $cas_import_ad_port,
        string $cas_import_ad_user,
        string $cas_import_ad_password,
        string $cas_import_ad_base_dn,
        string $cas_import_ad_sync_filter,
        string $cas_import_ad_sync_pagesize,
        string $cas_import_map_uid,
        string $cas_import_map_displayname,
        string $cas_import_map_email,
        string $cas_import_map_groups_description,
        string $cas_import_map_quota,
        string $cas_import_map_enabled,
        string $cas_import_map_enabled_and_bitwise,
        string|null $cas_import_merge = null,
        string|null $cas_import_merge_enabled = null,
        string $cas_import_map_dn,
        string $cas_import_map_dn_filter,
        string $cas_import_map_groups,
        string $cas_import_map_regex_name_uai,
        string $cas_import_map_groups_fonctionel,
        string $cas_import_map_groups_pedagogic
    ): JSONResponse {
        try {
            # ActiveDirectory (LDAP)
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_ad_protocol',
                $cas_import_ad_protocol
            );
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_ad_host',
                $cas_import_ad_host
            );
            $this->appConfig->setValueInt(
                Application::APP_ID,
                'cas_import_ad_port',
                intval($cas_import_ad_port)
            );
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_ad_user',
                $cas_import_ad_user
            );
            if (strlen($cas_import_ad_password) > 0) {
                $this->appConfig->setValueString(
                    Application::APP_ID,
                    'cas_import_ad_password',
                    $cas_import_ad_password
                );
            }
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_ad_base_dn',
                $cas_import_ad_base_dn
            );
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_ad_sync_filter',
                htmlspecialchars_decode($cas_import_ad_sync_filter)
            );
            $this->appConfig->setValueInt(
                Application::APP_ID,
                'cas_import_ad_sync_pagesize',
                intval($cas_import_ad_sync_pagesize)
            );

            # Mappage d'attributs CLI
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_map_uid',
                $cas_import_map_uid
            );
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_map_displayname',
                $cas_import_map_displayname
            );
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_map_email',
                $cas_import_map_email
            );
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_map_groups_description',
                $cas_import_map_groups_description
            );
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_map_quota',
                $cas_import_map_quota
            );
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_map_enabled',
                $cas_import_map_enabled
            );
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_map_enabled_and_bitwise',
                $cas_import_map_enabled_and_bitwise
            );
            $this->appConfig->setValueBool(
                Application::APP_ID,
                'cas_import_merge',
                $cas_import_merge !== null
            );
            $this->appConfig->setValueBool(
                Application::APP_ID,
                'cas_import_merge_enabled',
                $cas_import_merge_enabled !== null
            );
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_map_dn',
                $cas_import_map_dn
            );
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_map_dn_filter',
                $cas_import_map_dn_filter
            );

            # Groupes fonctionnels
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_map_groups',
                $cas_import_map_groups
            );
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_map_regex_name_uai',
                $cas_import_map_regex_name_uai
            );
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_map_groups_fonctionel',
                $cas_import_map_groups_fonctionel
            );

            # Groupes pédagogiques
            $this->appConfig->setValueString(
                Application::APP_ID,
                'cas_import_map_groups_pedagogic',
                $cas_import_map_groups_pedagogic
            );

            return new JSONResponse(array(
                'message' => 'Configuration enregistrée'
            ));
        } catch (\Exception $e) {
            return new JSONResponse(array(
                'message' => 'Une erreur est survenue lots de la sauvegarde',
                'error' => strval($e)
            ), Http::STATUS_BAD_REQUEST);
        }
    }
}
