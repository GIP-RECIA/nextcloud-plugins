<?php

/**
 * SPDX-FileCopyrightText: 2016-2024 Nextcloud GmbH and Nextcloud contributors
 * SPDX-FileCopyrightText: 2016 ownCloud, Inc.
 * SPDX-License-Identifier: AGPL-3.0-only
 */
namespace OC\Files\ObjectStore;

use OCP\IUser;

/**
 * Class Mapper
 *
 * @package OC\Files\ObjectStore
 *
 * Map a user to a bucket.
 */
class Mapper {
	public function __construct(
		private readonly IUser $user,
		private readonly array $config,
	) {
	}

	public function getBucket(int $numBuckets = 64): string {
		$hash = md5($this->user->getUID());
		return base_convert($hash, 16, 36);
	}
}
 
