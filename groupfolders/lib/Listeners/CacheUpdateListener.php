<?php

declare(strict_types=1);

/**
 * @copyright Copyright (c) 2023, Grégory Brousse <pro@gregory-brousse.fr>
 *
 * @author Grégory Brousse <pro@gregory-brousse.fr>
 *
 * @license GNU AGPL version 3 or any later version
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */
namespace OCA\GroupFolders\Listeners;

use OCA\GroupFolders\Folder\FolderManager;

use OCP\EventDispatcher\Event;
use OCP\EventDispatcher\IEventListener;
use OCP\Files\Cache\CacheEntryUpdatedEvent;

use OC\Files\View;
use Psr\Log\LoggerInterface;


class CacheUpdateListener implements IEventListener {
	/** @var FolderManager  */
	private $folderManager;

	/** @var View  */
	private $view;

	/** @var LoggerInterface */
	private $logger;

	/**
	 * @param SharedStorage $storage
	 */
	public function __construct(FolderManager $folderManager, View $view, LoggerInterface $logger) {
		$this->folderManager = $folderManager;
		$this->view = $view;
		$this->logger = $logger;
	}

	public function handle(Event $event): void {
		if (!($event instanceof CacheEntryUpdatedEvent)) {
			return;
		}
		$regExp = '/^__groupfolders\/(?<gfId>\d*)$/';
		$path = $event->getPath();
		preg_match($regExp,$path,$matches);
		if(!isset($matches['gfId']) || !is_numeric($matches['gfId']) || $matches['gfId']<1){
			return;
		}
		$id = $matches['gfId'];
		$fileInfo = $this->view->getFileInfo($path);
		$fileId = $fileInfo->getId();
		$storage = $fileInfo->getStorage();
		$cache = $storage->getCache();
		$fileCache = $cache->get($fileId);
		$etag = $fileCache->getEtag();
		$mtime = $fileCache->getMTime();
		$storage_mtime = $fileCache->getStorageMTime();
		$groupFolder = $this->folderManager->getFolder((int)$id,(int)$storage->getId());
		$mountPoint = $groupFolder['mount_point'];
		$parentMountPoint = dirname($mountPoint);
		if($parentMountPoint === '.'){
			return;
		}
		if(!$parentGroupFolderId = $this->folderManager->getFolderByMountPoint($parentMountPoint)){
			return;
		}
		$parentFileCachePath = '__groupfolders/'.$parentGroupFolderId;
		$parentFileInfo = $this->view->getFileInfo($parentFileCachePath);
		$parentFileId = $parentFileInfo->getId();
		$cache->update($parentFileId,[
			'etag'=>$etag,
			'mtime'=>$mtime,
			'storage_mtime'=>$storage_mtime,
		]);


		$this->logger->debug('CacheUpdateListener::GroupFolder modified',[
			'path'=>$path,
			'id'=>$id,
			'Etag'=>$etag,
			'mtime'=>$mtime,
			'smtime'=>$storage_mtime,
			'mountPoint'=>$mountPoint,
			'parentMountPoint'=>$parentMountPoint,
			'parentGroupFolderId'=>$parentGroupFolderId,
			'parentFileCachePath'=>$parentFileCachePath,
			'parentFileId'=>$parentFileId,
		]);
	}
}
