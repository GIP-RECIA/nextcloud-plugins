<?php
/**
 * @copyright Copyright (c) 2016, ownCloud, Inc.
 *
 * @author Björn Schießle <bjoern@schiessle.org>
 * @author Jörn Friedrich Dreyer <jfd@butonic.de>
 * @author Morris Jobke <hey@morrisjobke.de>
 * @author Roeland Jago Douma <roeland@famdouma.nl>
 *
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
 * along with this program. If not, see <http://www.gnu.org/licenses/>
 *
 */

namespace OC\Files\ObjectStore;


class ReciaObjectStoreStorage extends ObjectStoreStorage { 

	protected $defautBucket;
	protected $defautId;

	protected $defautObjectStore;
	protected $avatarObjectStore;

	/**
	 * @param array $params
	 */
	public function __construct($params) {
		error_log("new ReciaObjectStore \n", 3, '/var/www/ncrecette.recia/logs-esco/object.log');
		parent::__construct($params);
		$defautObjectStore = $this->objectStore;
		$avatarObjectStore = clone $defautObjectStore;
		$defautBucket = $defautObjectStore->getBucket();
		$defautId = $defautObjectStore->getStorageId();
 	}


	public function stat($path) {
		$stat = parent::stat($path);
		error_log("new ok ". $this->objectStore->getBucket() . " " . $this->objectStore->getStorageId() ."\n" , 3, '/var/www/ncrecette.recia/logs-esco/object.log');

		if (preg_match("/avatar\/(F\w{7})(\/.*)?$/",$path,  $matches)) {
			$uid = $matches[1];
			error_log("match $uid\n" , 3, '/var/www/ncrecette.recia/logs-esco/object.log');
		} else {
			error_log("ne match pas\n" , 3, '/var/www/ncrecette.recia/logs-esco/object.log');
			$this->objectSore = $defautObjectStore;

		}
 
	/*	if (is_array($stat)) {
			foreach ($stat as $k => $v) {
				error_log ("$k => $v \n", 3, '/var/www/ncrecette.recia/logs-esco/object.log');
			}
		}		
	 */	return $stat;
	}

}
