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
 */

$app = new \OCA\UserCAS\AppInfo\Application();
$c = $app->getContainer();

$requestUri = (isset($_SERVER['REQUEST_URI']) ? $_SERVER['REQUEST_URI'] : '');

if (\OCP\App::isEnabled($c->getAppName()) && !\OC::$CLI) {

    $userService = $c->query('UserService');
    $appService = $c->query('AppService');

    # Check for valid setup, only enable app if we have at least a CAS host, port and path
    if ($appService->isSetupValid()) {

        // Register User Backend
        $userService->registerBackend($c->query('Backend'));

        if ($requestUri === '/' || (strpos($requestUri, '/login') !== FALSE && strpos($requestUri, '/apps/user_cas/login') === FALSE)) {

            if ($_SERVER['REQUEST_METHOD'] !== 'POST') { // POST is used for single logout requests

                // Register UserHooks
                $c->query('UserHooks')->register();

                // URL params and redirect_url cookie
                setcookie("user_cas_enforce_authentication", "0", null, '/');
                $urlParams = '';

                if (isset($_REQUEST['redirect_url'])) {

                    $urlParams = $_REQUEST['redirect_url'];
                    // Save the redirect_rul to a cookie
                    $cookie = setcookie("user_cas_redirect_url", "$urlParams", null, '/');
                }/*
                else {

                    setcookie("user_cas_redirect_url", '/', null, '/');
                }*/

                // Register alternative LogIn
                $appService->registerLogIn();

                // Check for enforced authentication
                if ($appService->isEnforceAuthentication($_SERVER['REMOTE_ADDR']) && (!isset($_COOKIE['user_cas_enforce_authentication']) || (isset($_COOKIE['user_cas_enforce_authentication']) && $_COOKIE['user_cas_enforce_authentication'] === '0'))) {

                    $loggingService = $c->query("LoggingService");

                    $loggingService->write(\OCA\UserCas\Service\LoggingService::DEBUG, 'Enforce Authentication was: ' . $appService->isEnforceAuthentication($_SERVER['REMOTE_ADDR']));
                    setcookie("user_cas_enforce_authentication", '1', null, '/');

                    // Initialize app
                    if (!$appService->isCasInitialized()) {

                        try {

                            $appService->init();

                            //if (!\phpCAS::isAuthenticated()) {

                                $loggingService->write(\OCA\UserCas\Service\LoggingService::DEBUG, 'Enforce Authentication was on and phpCAS is not authenticated. Redirecting to CAS Server.');

                                $cookie = setcookie("user_cas_redirect_url", urlencode($requestUri), null, '/');

                                header("Location: " . $appService->linkToRouteAbsolute($c->getAppName() . '.authentication.casLogin'));
                                die();
                            //}

                        } catch (\OCA\UserCAS\Exception\PhpCas\PhpUserCasLibraryNotFoundException $e) {

                            $loggingService->write(\OCA\UserCas\Service\LoggingService::ERROR, 'Fatal error with code: ' . $e->getCode() . ' and message: ' . $e->getMessage());
                        }
                    }
                }
            }
        } else {

            // Register UserHooks
            $c->query('UserHooks')->register();
        }
    } else {

        $appService->unregisterLogIn();
    }
}