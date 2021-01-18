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
	protected $reciaObjectStore;

	/**
	 * @param array $params
	 */
	public function __construct($params) {
		parent::__construct($params);
		
		$this->defautObjectStore = $params['objectstore'];
		$this->reciaObjectStore = new  S3Recia($params);
		$this->defautBucket = $this->defautObjectStore->getBucket();
		$this->defautId = $this->defautObjectStore->getStorageId();
  
 	}


	public function stat($path) {
#	try {
		$stat = parent::stat($path);
		if (!(is_null($this->objectStore) or is_null($this->defautObjectStore) )) {

			if  (preg_match("/^[^\/]+\/avatar/",$path,  $matches)) {
				if (preg_match("/avatar\/(F\w{7})(\/.*)?$/",$path,  $matches)) {
					$uid = $matches[1];
					if (! is_null($this->reciaObjectStore)) {
						$this->objectStore = $this->reciaObjectStore;
						$this->objectStore->setBucket($this->defautBucket . strtolower($uid));

					}
				}
			} elseif  (preg_match("/^appdata_[^\/]+\/preview\/(\d+)/",$path,  $matches)) {
				$rep = $matches[1];
				if (! is_null($this->reciaObjectStore)) {
					$num = $rep % 1000;
					$this->objectStore = $this->reciaObjectStore;
					$bucketName = $this->defautBucket .'preview'. $num;
					$this->objectStore->setBucket($bucketName);
					#$this->objectStore = $this->defautObjectStore ;
					#error_log(" bucket name = $bucketName \n " , 3, '/var/www/ncrecette.recia/logs-esco/object.log'); 
				}
 			} else {
				$this->objectStore = $this->defautObjectStore ;
			}
		}
#	} catch (Exception $e) {
#		error_log(" Execption $e->gerMessage() \n " , 3, '/var/www/ncrecette.recia/logs-esco/object.log');
#	}
		return $stat;
	}

}
