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

use OCP\DB\QueryBuilder\IQueryBuilder;
use OCP\IDBConnection;
use OCP\Share\IShare;

class SearchDB {
	private $db;

	public function __construct(IDBConnection $db)
	{
		$this->db = $db;
	}

	public function searchAll($search, $etabs, $limit, $offset){
		$result = [
			'exact' => [
				'users' => [],
				'groups' => [],
			],
			'users' => [],
			'groups' => [],
		];
		list($result['users'],$hasMoreUsers)=$this->searchUsers($search, $etabs, $limit, $offset);
		$result['exact']['users']=array_filter($result['users'],function($user) use ($search){
			return $user['label'] == $search || $user['shareWithDisplayNameUnique'] == $search;
		});
		list($result['groups'],$hasMoreGroups)=$this->searchGroups($search, $etabs, $limit, $offset);
		$result['exact']['groups']=array_filter($result['groups'],function($groups) use ($search){
			return $groups['label'] == $search;
		});
		return [$result,$hasMoreUsers||$hasMoreGroups];
	}

	protected function searchUsers($search, $etabs, $limit, $offset):array {
		$hasMore=false;

		$qb = $this->db->getQueryBuilder();

		$whereClauses = $qb->expr()->andx();
		$whereClauses->add($qb->expr()->in('e.siren',$qb->createNamedParameter($etabs,IQueryBuilder::PARAM_STR_ARRAY)));
		$nameSearchClause = $qb->expr()->orx();
		$nameSearchClause->add($qb->expr()->ilike('u.displayName',$qb->createNamedParameter('%' . $this->db->escapeLikeParameter($search) . '%',IQueryBuilder::PARAM_STR)));
		$nameSearchClauseIfNull = $qb->expr()->andx();
		$nameSearchClauseIfNull->add($qb->expr()->isNull('u.displayName'));
		$nameSearchClauseIfNull->add($qb->expr()->ilike('u.uid',$qb->createNamedParameter('%' . $this->db->escapeLikeParameter($search) . '%',IQueryBuilder::PARAM_STR)));
		$nameSearchClause->add($nameSearchClauseIfNull);
		$whereClauses->add($nameSearchClause);
		$whereClauses->add($qb->expr()->ilike($qb->createFunction("JSON_EXTRACT(a.data, '$.email.value')"),$qb->createNamedParameter('%' . $this->db->escapeLikeParameter($search) . '%',IQueryBuilder::PARAM_STR)));
		$qb->select(
				'u.uid',
				'u.displayName',
				$qb->createFunction("JSON_EXTRACT(a.data, '$.email.value') as email"))
			->from('users', 'u')
			->join('u', 'accounts', 'a', 'u.uid = a.uid')
			->join('u', 'asso_uai_user_group', 'egu', 'u.uid = egu.user_group')
			->join('egu', 'etablissements', 'e', 'egu.id_etablissement = e.id')
			->where($whereClauses)
			->orderBy('u.displayName')
			->setMaxResults($limit+1)
			->setFirstResult($offset);
		$usersFetched = $qb->execute()->fetchAll();
		if(count($usersFetched)>$limit){
			$hasMore = true;
			array_pop($usersFetched);
		}

		$formattedUsers = array_map(function($user){
			$formattedUser = [
				'label' => $user['displayName']??$user['uid'],
				'subline' => '',
				'icon' => 'icon-user',
				'value' => [
					'shareType' => IShare::TYPE_USER,
					'shareWith' => $user['uid'],
				],
				'shareWithDisplayNameUnique' =>  $user['email'],
				'status' => []
			];
			return $formattedUser;
		},$usersFetched);
		return [$formattedUsers??[],$hasMore];

	}

	protected function searchGroups($search, $etabs, $limit, $offset) {
		$hasMore=false;

		$qb = $this->db->getQueryBuilder();

		$whereClauses = $qb->expr()->andx();
		$whereClauses->add($qb->expr()->in('e.siren',$qb->createNamedParameter($etabs,IQueryBuilder::PARAM_STR_ARRAY)));
		$nameSearchClause = $qb->expr()->orx();
		$nameSearchClause->add($qb->expr()->ilike('g.displayName',$qb->createNamedParameter('%' . $this->db->escapeLikeParameter($search) . '%',IQueryBuilder::PARAM_STR)));
		$nameSearchClauseIfNull = $qb->expr()->andx();
		$nameSearchClauseIfNull->add($qb->expr()->isNull('g.displayName'));
		$nameSearchClauseIfNull->add($qb->expr()->ilike('g.gid',$qb->createNamedParameter('%' . $this->db->escapeLikeParameter($search) . '%',IQueryBuilder::PARAM_STR)));
		$nameSearchClause->add($nameSearchClauseIfNull);
		$whereClauses->add($nameSearchClause);

		$qb->select('g.gid', 'g.displayName')
			->from('groups', 'g')
			->join('g', 'asso_uai_user_group', 'egu', 'g.gid = egu.user_group')
			->join('egu', 'etablissements', 'e', 'egu.id_etablissement = e.id')
			->where($whereClauses)
			->setMaxResults($limit+1)
			->setFirstResult($offset);
		$groupsFetched = $qb->execute()->fetchAll();
		if(count($groupsFetched)>$limit){
			$hasMore = true;
			array_pop($usersFetched);
		}

		$formattedGroups = array_map(function($group){
			$formattedGroup = [
				'label' => $group['displayName']??$group['gid'],
				'subline' => '',
				'icon' => 'icon-group',
				'value' => [
					'shareType' => IShare::TYPE_GROUP,
					'shareWith' => $group['gid'],
				]
			];
			return $formattedGroup;
		},$groupsFetched);
		return [$formattedGroups??[],$hasMore];
	}
}
