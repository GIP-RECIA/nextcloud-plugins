<?php

/**
 * SPDX-FileCopyrightText: 2016-2024 Nextcloud GmbH and Nextcloud contributors
 * SPDX-FileCopyrightText: 2016 ownCloud, Inc.
 * SPDX-License-Identifier: AGPL-3.0-only
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
		$this->reciaObjectStore = new S3Recia($params);
		$this->defautBucket = $this->defautObjectStore->getBucket();
		$this->defautId = $this->defautObjectStore->getStorageId();
	}

	public function stat(string $path): array|false {
		// try {
		$stat = parent::stat($path);
		if (!(is_null($this->objectStore) or is_null($this->defautObjectStore))) {
			if (preg_match("/^[^\/]+\/avatar/", $path,  $matches)) {
				if (preg_match("/avatar\/(F\w{7})(\/.*)?$/", $path,  $matches)) {
					$uid = $matches[1];
					if (! is_null($this->reciaObjectStore)) {
						$this->objectStore = $this->reciaObjectStore;
						$this->objectStore->setBucket($this->defautBucket . strtolower($uid));
					}
				}
			} elseif (preg_match("/^appdata_[^\/]+\/preview\/(\d+)/", $path,  $matches)) {
				$rep = $matches[1];
				if (! is_null($this->reciaObjectStore)) {
					$num = $rep % 1000;
					$this->objectStore = $this->reciaObjectStore;
					$bucketName = $this->defautBucket . 'preview' . $num;
					$this->objectStore->setBucket($bucketName);
					// $this->objectStore = $this->defautObjectStore;
					// error_log(" bucket name = $bucketName \n " , 3, '/var/www/ncrecette.recia/logs-esco/object.log'); 
				}
			} else {
				$this->objectStore = $this->defautObjectStore;
			}
		}
		// } catch (Exception $e) {
		// 	error_log(" Execption $e->gerMessage() \n " , 3, '/var/www/ncrecette.recia/logs-esco/object.log');
		// }

		return $stat;
	}
}
