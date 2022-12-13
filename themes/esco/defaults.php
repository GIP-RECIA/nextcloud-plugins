<?php
/**
 * @author Björn Schießle <schiessle@owncloud.com>
 * @author Jan-Christoph Borchardt, http://jancborchardt.net
 * @copyright Copyright (c) 2016, ownCloud, Inc.
 * @license AGPL-3.0
 *
 * This code is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License, version 3,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License, version 3,
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

class OC_Theme {

	public static $dom = array (
		'test-clg37.giprecia.net' => 'test-clg37.giprecia.net',
		'test-lycee.giprecia.net' => 'test-lycee.giprecia.net',
	//      'recette-pub.nextcloud.recia.aquaray.com' => 'esco',
	//              'prod.nextcloud.recia.aquaray.com' => 'esco',
		'nc-lycees.netocentre.fr' => 'lycees.netocentre.fr',
		'nc-agri.netocentre.fr' => 'lycees.netocentre.fr',
		'nc.touraine-eschool.fr' => 'touraine-eschool.fr',
		'nc.chercan.fr' => 'www.chercan.fr',
		'nc.colleges41.fr' => 'ent.colleges41.fr',
		'nc.mon-e-college.loiret.fr' => 'mon-e-college.loiret.fr',
		'nc.e-college.indre.fr' => 'e-college.indre.fr',
		'nc-ent.recia.fr' => 'ent.recia.fr',
		'nc.colleges-eureliens.fr' => 'www.colleges-eureliens.fr',
	);
	public static $cssClass = array (
		'test-clg37.giprecia.net' => 'clg37',
		'test-lycee.giprecia.net' => 'esco',
		'nc-lycees.netocentre.fr' => 'esco',
		'nc-agri.netocentre.fr' =>  'agri',
		'nc.touraine-eschool.fr' =>  'clg37',
		'nc.chercan.fr' =>  'clg18',
		'nc.colleges41.fr' =>  'clg41',
		'nc.mon-e-college.loiret.fr' =>  'clg45',
		'nc.e-college.indre.fr' =>  'clg36',
		'nc-ent.recia.fr' =>  'esco',
		'nc.colleges-eureliens.fr' =>  'clg28',
	);
/*
	public function __construct() {
		$request = \OC::$server->getRequest();
		$portal_domain = $request->getParam('portal_domain');
		$host = $request->getServerHost();
//error_log("host= $host\n", 3, "/home/esco/logs/themes.esco.log" );
		if (!isset($portal_domain) ) {
			$host = $request->getServerHost();
			$portal_domain = self::$dom[$host];
		}
//error_log("domain  =  $portal_domain\n", 3, "/home/esco/logs/themes.esco.log" );
		if ($portal_domain) {
				\OC\Http\CookieHelper::setcookie('extended_uportal_header_portal_domain', $portal_domain ,0,'/','', true, true);
		}
	}
*/

	public static function getTable() {
		error_log("get table \n", 3, "/home/esco/logs/themes.esco.log" );
		return self::$dom;
	}
	private static function domain($host) {
		error_log("domain for $host \n", 3, "/home/esco/logs/themes.esco.log" );
		return self::$dom[$host];
	}
	public static function getDomain($request) {
		error_log("get domain \n", 3, "/home/esco/logs/themes.esco.log" );
		return self::domain($request->getServerHost());
	}
	public static function getCssClass($request) {
		error_log("get cssClass \n", 3, "/home/esco/logs/themes.esco.log" );
		$host = $request->getServerHost();
		$css =  self::$cssClass[$request->getServerHost()] ;
		return $css ? " embedded " . $css : " not_embedded " ;
	}
	
	public static function getPortailLoginUrl($request) {
		$host = $request->getServerHost();
		error_log("get PortailLoginUrl '$host'\n", 3, "/home/esco/logs/themes.esco.log" );
		$domain = self::domain($host);
		if ($domain) {
			$cas = (strpos($host, 'test') === false) ? "ent.netocentre.fr" : "secure.giprecia.net";
			$portail_login = sprintf("https://%s/cas/login?service=https://%s/portail/Login", $cas, $domain);
		}
		error_log("return  '$portail_login'\n", 3, "/home/esco/logs/themes.esco.log" );
		return $portail_login;
	}
}
