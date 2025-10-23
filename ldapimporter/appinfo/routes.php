<?php
/**
 * Create your routes in here. The name is the lowercase name of the controller
 * without the controller part, the stuff after the hash is the method.
 * e.g. page#index -> OCA\LdapImporter\Controller\PageController->index()
 *
 * The controller class has to be registered in the application.php file since
 * it's instantiated in there
 */

namespace OCA\LdapImporter\AppInfo;

/** @var \OCA\UserCAS\AppInfo\Application $application */
$application = new \OCA\LdapImporter\AppInfo\Application();
$application->registerRoutes($this, array(
    'routes' => [
        array('name' => 'settings#saveSettings', 'url' => '/settings/save', 'verb' => 'POST'),
    ]
));
