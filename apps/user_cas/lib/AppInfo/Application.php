<?php

/**
 * ownCloud - user_cas
 *
 * @author Felix Rupp <kontakt@felixrupp.com>
 * @copyright Felix Rupp <kontakt@felixrupp.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU AFFERO GENERAL PUBLIC LICENSE for more details.
 *
 * You should have received a copy of the GNU Affero General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

namespace OCA\UserCAS\AppInfo;

use \OCP\AppFramework\App;

use OCA\UserCAS\Service\UserService;
use OCA\UserCAS\Service\AppService;
use OCA\UserCAS\Hooks\UserHooks;
use OCA\UserCAS\Controller\SettingsController;
use OCA\UserCAS\Controller\AuthenticationController;
use OCA\UserCAS\User\Backend;
use OCA\UserCAS\User\NextBackend;
use OCA\UserCAS\Service\LoggingService;
use Psr\Container\ContainerInterface;
use Psr\Log\LoggerInterface;

/**
 * Class Application
 *
 * @package OCA\UserCAS\AppInfo
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

        parent::__construct('user_cas', $urlParams);

        $container = $this->getContainer();

        $container->registerService('User', function (ContainerInterface $c) {
            return $c->get('UserSession')->getUser();
        });

        $container->registerService('Config', function (ContainerInterface $c) {
            return $c->get('ServerContainer')->getConfig();
        });

        $container->registerService('L10N', function (ContainerInterface $c) {
            return $c->get('ServerContainer')->getL10N($c->get('appName'));
        });

        $container->registerService('Logger', function (ContainerInterface $c) {
            return \OC::$server->get(LoggerInterface::class);
        });

        /**
         * Register LoggingService
         */
        $container->registerService('LoggingService', function (ContainerInterface $c) {
            return new LoggingService(
                $c->get('appName'),
                $c->get('Config'),
                $c->get('Logger')
            );
        });

        /**
         * Register AppService with config
         */
        $container->registerService('AppService', function (ContainerInterface $c) {
            return new AppService(
                $c->get('appName'),
                $c->get('Config'),
                $c->get('LoggingService'),
                $c->get('ServerContainer')->getUserManager(),
                $c->get('ServerContainer')->getUserSession(),
                $c->get('ServerContainer')->getURLGenerator(),
                $c->get('ServerContainer')->getAppManager()
            );
        });


        // Workaround for Nextcloud >= 14.0.0
        if ($container->get('AppService')->isNotNextcloud()) {

            /**
             * Register regular Backend
             */
            $container->registerService('Backend', function (ContainerInterface $c) {
                return new Backend(
                    $c->get('appName'),
                    $c->get('Config'),
                    $c->get('LoggingService'),
                    $c->get('AppService'),
                    $c->get('ServerContainer')->getUserManager(),
                    $c->get('UserService')
                );
            });
        } else {

            /**
             * Register Nextcloud Backend
             */
            $container->registerService('Backend', function (ContainerInterface $c) {
                return new NextBackend(
                    $c->get('appName'),
                    $c->get('Config'),
                    $c->get('LoggingService'),
                    $c->get('AppService'),
                    $c->get('ServerContainer')->getUserManager(),
                    $c->get('UserService')
                );
            });
        }

        /**
         * Register UserService with UserSession for login/logout and UserManager for create
         */
        $container->registerService('UserService', function (ContainerInterface $c) {
            return new UserService(
                $c->get('appName'),
                $c->get('Config'),
                $c->get('ServerContainer')->getUserManager(),
                $c->get('ServerContainer')->getUserSession(),
                $c->get('ServerContainer')->getGroupManager(),
                $c->get('AppService'),
                $c->get('LoggingService')
            );
        });

        /**
         * Register SettingsController
         */
        $container->registerService('SettingsController', function (ContainerInterface $c) {
            return new SettingsController(
                $c->get('appName'),
                $c->get('Request'),
                $c->get('Config'),
                $c->get('L10N')
            );
        });

        /**
         * Register AuthenticationController
         */
        $container->registerService('AuthenticationController', function (ContainerInterface $c) {
            return new AuthenticationController(
                $c->get('appName'),
                $c->get('Request'),
                $c->get('Config'),
                $c->get('UserService'),
                $c->get('AppService'),
                $c->get('ServerContainer')->getUserSession(),
                $c->get('LoggingService')
            );
        });

        /**
         * Register UserHooks
         */
        $container->registerService('UserHooks', function (ContainerInterface $c) {
            return new UserHooks(
                $c->get('appName'),
                $c->get('ServerContainer')->getUserManager(),
                $c->get('ServerContainer')->getUserSession(),
                $c->get('Config'),
                $c->get('UserService'),
                $c->get('AppService'),
                $c->get('LoggingService'),
                $c->get('Backend')
            );
        });
    }
}
