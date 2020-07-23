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
		parent::__construct($params);
/*		foreach ($params as $k => $v) {
			error_log("\t $k => $v \n", 3, '/var/www/ncrecette.recia/logs-esco/object.log');	
		}
 */   		
//	$this->defautObjectStore = $this->objectStore ; //$params['objectstore'];
		$this->defautObjectStore = $params['objectstore'];
//	$this->defautObjectStore = $this.getObjectStore();
		$this->avatarObjectStore = new  S3Recia($params);
		$this->defautBucket = $this->defautObjectStore->getBucket();
		$this->defautId = $this->defautObjectStore->getStorageId();
		error_log("new ReciaObjectStore 3 ". $this->defautId . "\n", 3, '/var/www/ncrecette.recia/logs-esco/object.log');
  
 	}


	public function stat($path) {
	try {
		$stat = parent::stat($path);
//		$testO = ($this->objectStore === $this->defautObjectStore) ? 'true' : 'false';
//		 error_log("new ok $testO : " . is_null($this->objectStore) . " : " . is_null($this->defautObjectStore)  ."\n" , 3, '/var/www/ncrecette.recia/logs-esco/object.log');
		if (!(is_null($this->objectStore) or is_null($this->defautObjectStore) )) {
			error_log("new ok $testO 1\n" , 3, '/var/www/ncrecette.recia/logs-esco/object.log');
		//	error_log(" objectStore " . isset($this->objectStore) . " \n" , 3, '/var/www/ncrecette.recia/logs-esco/object.log');
		//	error_log(" defautObjectStore " . isset($this->defautObjectStore) . "\n" , 3, '/var/www/ncrecette.recia/logs-esco/object.log');

			if  (preg_match("/^[^\/]+\/avatar/",$path,  $matches)) {
				if (preg_match("/avatar\/(F\w{7})(\/.*)?$/",$path,  $matches)) {
					$uid = $matches[1];
					if (! is_null($this.avatarObjectStore)) {
						error_log("match $uid\n" , 3, '/var/www/ncrecette.recia/logs-esco/object.log');
						$this->objectStore = $this->avatarObjectStore;
						$mes = "no object" ;
						$this->objectStore->setBucket($this->defautBucket . strtolower($uid));
						$mes = $this->objectStore->getStorageId();
						error_log("     match ok " . $mes . "\n", 3, '/var/www/ncrecette.recia/logs-esco/object.log');

					}
				}
			} else {
				$this->objectStore = $this->defautObjectStore ;
			}
		} /*else {
			error_log("ne match pas\n" , 3, '/var/www/ncrecette.recia/logs-esco/object.log');
			$this->objectSore = $defautObjectStore;

			}*/
 
	/*	if (is_array($stat)) {
			foreach ($stat as $k => $v) {
				error_log ("$k => $v \n", 3, '/var/www/ncrecette.recia/logs-esco/object.log');
			}
		}		
	 */
	} catch (Exception $e) {
		error_log(" Execption $e->gerMessage() \n " , 3, '/var/www/ncrecette.recia/logs-esco/object.log');
	}
		return $stat;
	}

}
