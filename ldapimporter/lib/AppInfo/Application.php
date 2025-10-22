<?php


namespace OCA\LdapImporter\AppInfo;

use \OCP\AppFramework\App;
use \OCP\IContainer;

use OCA\LdapImporter\Service\UserService;
use OCA\LdapImporter\Service\AppService;
use OCA\LdapImporter\Controller\SettingsController;
use OCA\LdapImporter\User\Backend;
use OCA\LdapImporter\User\NextBackend;
use OCA\LdapImporter\Service\LoggingService;
use OCA\LdapImporter\Hooks\UserHooks;
use OCA\LdapImporter\Controller\AuthenticationController;
use Psr\Log\LoggerInterface;

/**
 * Class Application
 *
 * @package OCA\LdapImporter\AppInfo
 *
 * @author Felix Rupp <kontakt@felixrupp.com>
 * @copyright Felix Rupp <kontakt@felixrupp.com>
 *
 * @since 1.4.0
 */
class Application extends App
{

    /**
     * Application constructor.
     *
     * @param array $urlParams
     */
    public function __construct(array $urlParams = array())
    {

        parent::__construct('ldapimporter', $urlParams);

        $container = $this->getContainer();

        $container->registerService('User', function (IContainer $c) {
            return $c->query('UserSession')->getUser();
        });

        $container->registerService('Config', function (IContainer $c) {
            return $c->query('ServerContainer')->getConfig();
        });

        $container->registerService('L10N', function (IContainer $c) {
            return $c->query('ServerContainer')->getL10N($c->query('AppName'));
        });

	$container->registerService('Logger', function (IContainer $c) {
		return \OC::$server->query(\Psr\Log\LoggerInterface::class);

        });

        /**
         * Register LoggingService
         */
        $container->registerService('LoggingService', function (IContainer $c) {
            return new LoggingService(
                $c->query('AppName'),
                $c->query('Config'),
                $c->query('Logger')
            );
        });

        /**
         * Register AppService with config
         */
        $container->registerService('AppService', function (IContainer $c) {
            return new AppService(
                $c->query('AppName'),
                $c->query('Config'),
                $c->query('LoggingService'),
                $c->query('ServerContainer')->getUserManager(),
                $c->query('ServerContainer')->getUserSession(),
                $c->query('ServerContainer')->getURLGenerator()
            );
        });


        // Workaround for Nextcloud >= 14.0.0
        if ($container->query('AppService')->isNotNextcloud()) {

            /**
             * Register regular Backend
             */
            $container->registerService('Backend', function (IContainer $c) {
                return new Backend(
                    $c->query('AppName'),
                    $c->query('Config'),
                    $c->query('LoggingService'),
                    $c->query('AppService'),
                    $c->query('ServerContainer')->getUserManager()
                );
            });
        } else {

            /**
             * Register Nextcloud Backend
             */
            $container->registerService('Backend', function (IContainer $c) {
                return new NextBackend(
                    $c->query('AppName'),
                    $c->query('Config'),
                    $c->query('LoggingService'),
                    $c->query('AppService'),
                    $c->query('ServerContainer')->getUserManager(),
                    $c->query('UserService')
                );
            });
        }

        /**
         * Register UserService with UserSession for login/logout and UserManager for create
         */
        $container->registerService('UserService', function (IContainer $c) {
            return new UserService(
                $c->query('AppName'),
                $c->query('Config'),
                $c->query('ServerContainer')->getUserManager(),
                $c->query('ServerContainer')->getUserSession(),
                $c->query('ServerContainer')->getGroupManager(),
                $c->query('AppService'),
                $c->query('LoggingService')
            );
        });

        /**
         * Register SettingsController
         */
        $container->registerService('SettingsController', function (IContainer $c) {
            return new SettingsController(
                $c->query('AppName'),
                $c->query('Request'),
                $c->query('Config'),
                $c->query('L10N')
            );
        });

        /**
         * Register AuthenticationController
         */
        $container->registerService('AuthenticationController', function (IContainer $c) {
            return new AuthenticationController(
                $c->query('AppName'),
                $c->query('Request'),
                $c->query('Config'),
                $c->query('UserService'),
                $c->query('AppService'),
                $c->query('ServerContainer')->getUserSession(),
                $c->query('LoggingService')
            );
        });

        /**
         * Register UserHooks
         */
        $container->registerService('UserHooks', function (IContainer $c) {
            return new UserHooks(
                $c->query('AppName'),
                $c->query('ServerContainer')->getUserManager(),
                $c->query('ServerContainer')->getUserSession(),
                $c->query('Config'),
                $c->query('UserService'),
                $c->query('AppService'),
                $c->query('LoggingService'),
                $c->query('Backend')
            );
        });
    }
}
