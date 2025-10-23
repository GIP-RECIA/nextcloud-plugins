<?php

namespace OCA\LdapImporter\Panels;

use OCP\Settings\ISettings;
use OCP\Template;
use OCP\AppFramework\Http\TemplateResponse;
use OCP\IConfig;

class Admin implements ISettings
{

    /**
     * @var array
     */
    private $params = array('cas_server_version', 'cas_server_hostname', 'cas_server_port', 'cas_server_path', 'cas_force_login', 'cas_force_login_exceptions','cas_autocreate',
        'cas_update_user_data', 'cas_keep_ticket_ids', 'cas_login_button_label', 'cas_protected_groups', 'cas_default_group', 'cas_ecas_attributeparserenabled', 'cas_email_mapping', 'cas_displayName_mapping', 'cas_group_mapping', 'cas_quota_mapping',
        'cas_cert_path', 'cas_debug_file', 'cas_php_cas_path', 'cas_link_to_ldap_backend', 'cas_disable_logout', 'cas_handlelogout_servers', 'cas_service_url', 'cas_access_allow_groups',
        'cas_access_group_quotas', 'cas_groups_letter_filter', 'cas_groups_letter_umlauts',
        'cas_import_ad_protocol', 'cas_import_ad_host', 'cas_import_ad_port', 'cas_import_ad_user', 'cas_import_ad_domain', 'cas_import_ad_password', 'cas_import_ad_base_dn', 'cas_import_ad_sync_filter', 'cas_import_ad_sync_pagesize',
        'cas_import_map_uid', 'cas_import_map_displayname', 'cas_import_map_email', 'cas_import_map_groups', 'cas_import_regex_name_uai', 'cas_import_regex_name_group', 'cas_import_regex_uai_group','cas_import_map_groups_filter', 'cas_import_map_groups_naming', 'cas_import_map_groups_description', 'cas_import_map_groups_pedagogic', 'cas_import_map_groups_fonctionel', 'cas_import_map_regex_name_uai', 'cas_import_map_quota', 'cas_import_map_enabled', 'cas_import_map_enabled_and_bitwise', 'cas_import_map_dn_filter', 'cas_import_map_dn', 'cas_import_merge', 'cas_import_merge_enabled',
        'cas_ecas_accepted_strengths', 'cas_ecas_retrieve_groups','cas_ecas_request_full_userdetails', 'cas_ecas_assurance_level','cas_use_proxy', 'cas_ecas_internal_ip_range');

    /**
     * @var IConfig
     */
    private $config;

    /**
     * Admin constructor.
     *
     * @param IConfig $config
     */
    public function __construct(IConfig $config)
    {
        $this->config = $config;
    }

    /**
     * @return string
     */
    public function getSectionID()
    {
        return 'authentication';
    }

    /**
     * @see Nextcloud 13 support
     *
     * @return string
     *
     * @since 1.5.0
     */
    public function getSection()
    {
        return 'ldapimporter';
    }

    /**
     * @return int
     */
    public function getPriority()
    {
        return 50;
    }

    /**
     * Get Panel
     *
     * @return Template
     */
    public function getPanel()
    {

        $tmpl = new Template('ldapimporter', 'admin');

        foreach ($this->params as $param) {

            $value = htmlentities($this->config->getAppValue('ldapimporter', $param));

            $tmpl->assign($param, $value);
        }

        return $tmpl;
    }

    /**
     * @see Nextcloud 13 support
     *
     * @return TemplateResponse
     *
     * @since 1.5.0
     */
    public function getForm()
    {

        $parameters = array();

        foreach ($this->params as $param) {

            $parameters[$param] = htmlentities($this->config->getAppValue('ldapimporter', $param));
        }

        return new TemplateResponse('ldapimporter', 'admin', $parameters);
    }
}