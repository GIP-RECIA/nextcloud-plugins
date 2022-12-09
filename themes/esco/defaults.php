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

	public function __construct() {
		$request = \OC::$server->getRequest();
		$portal_domain = $request->getParam('portal_domain');
//		$response = \OC::$server->getResponse();
		if ($portal_domain) {
			\OC\Http\CookieHelper::setcookie('extended_uportal_header_portal_domain', $portal_domain ,0,'/','', true, true);
		}
//		$response->setcookie('cookie test', 'test,['secure'=>true,'httponly'=>true])

	}
	

}
