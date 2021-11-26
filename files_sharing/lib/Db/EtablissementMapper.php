<?php
/**
 * @copyright Copyright (c) 2021, GIP Recia.
 *
 * @author Grégory Brousse <pro@gregory-brousse.fr>
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

namespace OCA\Files_Sharing\Db;

use OCP\IDBConnection;
use OCP\AppFramework\Db\QBMapper;

class EtablissementMapper extends QBMapper {

    public function __construct(IDBConnection $db) {
        parent::__construct($db, 'etablissements', Etablissement::class);
    }

    public function findByUid(string $uid) {
        $qb = $this->db->getQueryBuilder();

        $qb->select('*')
            ->from($this->getTableName())
            ->where(
                    $qb->expr()->eq('uid', $qb->createNamedParameter($uid))
            );

        return $this->findEntity($qb);
    }

	public function findBySiren(string $siren) {
        $qb = $this->db->getQueryBuilder();

        $qb->select('*')
            ->from($this->getTableName())
            ->where(
                    $qb->expr()->eq('siren', $qb->createNamedParameter($siren))
            );

        return $this->findEntity($qb);
    }

    public function findAll($limit=null, $offset=null) {
        $qb = $this->db->getQueryBuilder();

        $qb->select('*')
           ->from($this->getTableName())
           ->setMaxResults($limit)
           ->setFirstResult($offset);

        return $this->findEntities($qb);
    }

	public function findAllByUser(string $userId,$limit=null, $offset=null) {
        $qb = $this->db->getQueryBuilder();

        $qb->select('etab.*')
           ->from($this->getTableName(),'etab')
		   ->join('etab','asso_uai_user_group','etabgrp','etab.id = etabgrp.id_etablissement')
		   ->where(
				$qb->expr()->eq('etabgrp.user_group', $qb->createNamedParameter($userId))
			)
		   ->orderBy('etab.name')
           ->setMaxResults($limit)
           ->setFirstResult($offset);

		return $this->findEntities($qb);
    }

}
