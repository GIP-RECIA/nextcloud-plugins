<?php

declare(strict_types=1);

/**
 * @copyright Copyright (c) 2016, ownCloud, Inc.
 *
 * @author Arthur Schiwon <blizzz@arthur-schiwon.de>
 * @author Bjoern Schiessle <bjoern@schiessle.org>
 * @author Björn Schießle <bjoern@schiessle.org>
 * @author Christoph Wurst <christoph@winzerhof-wurst.at>
 * @author Daniel Calviño Sánchez <danxuliu@gmail.com>
 * @author Joas Schilling <coding@schilljs.com>
 * @author Maxence Lange <maxence@nextcloud.com>
 * @author Morris Jobke <hey@morrisjobke.de>
 * @author Robin Appelman <robin@icewind.nl>
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

namespace OCA\Files_Sharing\Controller;

use Doctrine\DBAL\Connection;
use OCP\IDBConnection;
use function array_filter;
use function array_slice;
use function array_values;
use Generator;
use OC\Collaboration\Collaborators\SearchResult;
use OCP\AppFramework\Http\DataResponse;
use OCP\AppFramework\OCS\OCSBadRequestException;
use OCP\AppFramework\OCSController;
use OCP\Collaboration\Collaborators\ISearch;
use OCP\Collaboration\Collaborators\ISearchResult;
use OCP\Collaboration\Collaborators\SearchResultType;
use OCP\IConfig;
use OCP\IRequest;
use OCP\IURLGenerator;
use OCP\Share;
use OCP\Share\IManager;
use function usort;

class ShareesAPIController extends OCSController {

	/** @var userId */
	protected $userId;

	/** @var IConfig */
	protected $config;

	/** @var IURLGenerator */
	protected $urlGenerator;

	/** @var IManager */
	protected $shareManager;

	/** @var bool */
	protected $shareWithGroupOnly = false;

	/** @var bool */
	protected $shareeEnumeration = true;

	/** @var int */
	protected $offset = 0;

	/** @var int */
	protected $limit = 10;

	/** @var array */
	protected $result = [
		'exact' => [
			'users' => [],
			'groups' => [],
			'remotes' => [],
			'remote_groups' => [],
			'emails' => [],
			'circles' => [],
			'rooms' => [],
		],
		'users' => [],
		'groups' => [],
		'remotes' => [],
		'remote_groups' => [],
		'emails' => [],
		'lookup' => [],
		'circles' => [],
		'rooms' => [],
		'lookupEnabled' => false,
	];

	protected $reachedEndFor = [];
	/** @var ISearch */
	private $collaboratorSearch;

    /** @var IDBConnection */
    protected $db;


    /**
     * @param string $UserId
     * @param string $appName
     * @param IRequest $request
     * @param IConfig $config
     * @param IURLGenerator $urlGenerator
     * @param IManager $shareManager
     * @param ISearch $collaboratorSearch
     * @param IDBConnection $db
     */
	public function __construct(
		$UserId,
		string $appName,
		IRequest $request,
		IConfig $config,
		IURLGenerator $urlGenerator,
		IManager $shareManager,
		ISearch $collaboratorSearch,
        IDBConnection $db
	) {
		parent::__construct($appName, $request);
		$this->userId = $UserId;
		$this->config = $config;
		$this->urlGenerator = $urlGenerator;
		$this->shareManager = $shareManager;
		$this->collaboratorSearch = $collaboratorSearch;
		$this->db = $db;
	}

    /**
     * @NoAdminRequired
     *
     * @param string $search
     * @param string $itemType
     * @param int $page
     * @param int $perPage
     * @param int|int[] $shareType
     * @param bool $lookup
     * @param bool $lookupSchool
     * @return DataResponse
     * @throws OCSBadRequestException
     */
	public function search(string $search = '', string $itemType = null, int $page = 1, int $perPage = 200, $shareType = null, bool $lookup = true, bool $lookupSchool = true): DataResponse {

		// only search for string larger than a given threshold
		$threshold = (int)$this->config->getSystemValue('sharing.minSearchStringLength', 0);
		if (strlen($search) < $threshold) {
			return new DataResponse($this->result);
		}

		// never return more than the max. number of results configured in the config.php
		$maxResults = (int)$this->config->getSystemValue('sharing.maxAutocompleteResults', 0);
		if ($maxResults > 0) {
			$perPage = min($perPage, $maxResults);
		}
		if ($perPage <= 0) {
			throw new OCSBadRequestException('Invalid perPage argument');
		}
		if ($page <= 0) {
			throw new OCSBadRequestException('Invalid page');
		}

		$shareTypes = [
			Share::SHARE_TYPE_USER,
		];

		if ($itemType === null) {
			throw new OCSBadRequestException('Missing itemType');
		} elseif ($itemType === 'file' || $itemType === 'folder') {
			if ($this->shareManager->allowGroupSharing()) {
				$shareTypes[] = Share::SHARE_TYPE_GROUP;
			}

			if ($this->isRemoteSharingAllowed($itemType)) {
				$shareTypes[] = Share::SHARE_TYPE_REMOTE;
			}

			if ($this->isRemoteGroupSharingAllowed($itemType)) {
				$shareTypes[] = Share::SHARE_TYPE_REMOTE_GROUP;
			}

			if ($this->shareManager->shareProviderExists(Share::SHARE_TYPE_EMAIL)) {
				$shareTypes[] = Share::SHARE_TYPE_EMAIL;
			}

			if ($this->shareManager->shareProviderExists(Share::SHARE_TYPE_ROOM)) {
				$shareTypes[] = Share::SHARE_TYPE_ROOM;
			}
		} else {
			$shareTypes[] = Share::SHARE_TYPE_GROUP;
			$shareTypes[] = Share::SHARE_TYPE_EMAIL;
		}

		// FIXME: DI
		if (\OC::$server->getAppManager()->isEnabledForUser('circles') && class_exists('\OCA\Circles\ShareByCircleProvider')) {
			$shareTypes[] = Share::SHARE_TYPE_CIRCLE;
		}

		if ($shareType !== null && is_array($shareType)) {
			$shareTypes = array_intersect($shareTypes, $shareType);
		} else if (is_numeric($shareType)) {
			$shareTypes = array_intersect($shareTypes, [(int) $shareType]);
		}
		sort($shareTypes);

		$this->shareWithGroupOnly = $this->config->getAppValue('core', 'shareapi_only_share_with_group_members', 'no') === 'yes';
		$this->shareeEnumeration = $this->config->getAppValue('core', 'shareapi_allow_share_dialog_user_enumeration', 'yes') === 'yes';
		$this->limit = (int) $perPage;
		$this->offset = $perPage * ($page - 1);

		// In global scale mode we always search the loogup server
		if ($this->config->getSystemValueBool('gs.enabled', false)) {
			$lookup = true;
			$this->result['lookupEnabled'] = true;
		} else {
			$this->result['lookupEnabled'] = $this->config->getAppValue('files_sharing', 'lookupServerEnabled', 'yes') === 'yes';
		}

		// Ancienne recherche
        //list($result, $hasMoreResults) = $this->collaboratorSearch->search($search, $shareTypes, $lookup, $this->limit, $this->offset);
		$result = $this->searchResults($search, $lookup, $lookupSchool);
		// extra treatment for 'exact' subarray, with a single merge expected keys might be lost
		if(isset($result['exact'])) {
			$result['exact'] = array_merge($this->result['exact'], $result['exact']);
		}

		$this->result = array_merge($this->result, $result);
		$response = new DataResponse($this->result);

		// Ancienne pagination
//		if ($hasMoreResults) {
//			$response->addHeader('Link', $this->getPaginationLink($page, [
//				'search' => $search,
//				'itemType' => $itemType,
//				'shareType' => $shareTypes,
//				'perPage' => $perPage,
//			]));
//		}

		return $response;
	}

	/**
	 * @param string $user
	 * @param int $shareType
	 *
	 * @return Generator<array<string>>
	 */
	private function getAllShareesByType(string $user, int $shareType): Generator {
		$offset = 0;
		$pageSize = 50;

		while (count($page = $this->shareManager->getSharesBy(
			$user,
			$shareType,
			null,
			false,
			$pageSize,
			$offset
		))) {
			foreach ($page as $share) {
				yield [$share->getSharedWith(), $share->getSharedWithDisplayName() ?? $share->getSharedWith()];
			}

			$offset += $pageSize;
		}
	}

	private function sortShareesByFrequency(array $sharees): array {
		usort($sharees, function(array $s1, array $s2) {
			return $s2['count'] - $s1['count'];
		});
		return $sharees;
	}

	private $searchResultTypeMap = [
		Share::SHARE_TYPE_USER => 'users',
		Share::SHARE_TYPE_GROUP => 'groups',
		Share::SHARE_TYPE_REMOTE => 'remotes',
		Share::SHARE_TYPE_REMOTE_GROUP => 'remote_groups',
		Share::SHARE_TYPE_EMAIL => 'emails',
	];

	private function getAllSharees(string $user, array $shareTypes): ISearchResult {
		$result = [];
		foreach ($shareTypes as $shareType) {
			$sharees = $this->getAllShareesByType($user, $shareType);
			$shareTypeResults = [];
			foreach ($sharees as list($sharee, $displayname)) {
				if (!isset($this->searchResultTypeMap[$shareType])) {
					continue;
				}

				if (!isset($shareTypeResults[$sharee])) {
					$shareTypeResults[$sharee] = [
						'count' => 1,
						'label' => $displayname,
						'value' => [
							'shareType' => $shareType,
							'shareWith' => $sharee,
						],
					];
				} else {
					$shareTypeResults[$sharee]['count']++;
				}
			}
			$result = array_merge($result, array_values($shareTypeResults));
		}

		$top5 = array_slice(
			$this->sortShareesByFrequency($result),
			0,
			5
		);

		$searchResult = new SearchResult();
		foreach ($this->searchResultTypeMap as $int => $str) {
			$searchResult->addResultSet(new SearchResultType($str), [], []);
			foreach ($top5 as $x) {
				if ($x['value']['shareType'] === $int) {
					$searchResult->addResultSet(new SearchResultType($str), [], [$x]);
				}
			}
		}
		return $searchResult;
	}

	/**
	 * @NoAdminRequired
	 *
	 * @param string $itemType
	 * @return DataResponse
	 * @throws OCSBadRequestException
	 */
	public function findRecommended(string $itemType = null, $shareType = null): DataResponse {
		$shareTypes = [
			Share::SHARE_TYPE_USER,
		];

		if ($itemType === null) {
			throw new OCSBadRequestException('Missing itemType');
		} elseif ($itemType === 'file' || $itemType === 'folder') {
			if ($this->shareManager->allowGroupSharing()) {
				$shareTypes[] = Share::SHARE_TYPE_GROUP;
			}

			if ($this->isRemoteSharingAllowed($itemType)) {
				$shareTypes[] = Share::SHARE_TYPE_REMOTE;
			}

			if ($this->isRemoteGroupSharingAllowed($itemType)) {
				$shareTypes[] = Share::SHARE_TYPE_REMOTE_GROUP;
			}

			if ($this->shareManager->shareProviderExists(Share::SHARE_TYPE_EMAIL)) {
				$shareTypes[] = Share::SHARE_TYPE_EMAIL;
			}

			if ($this->shareManager->shareProviderExists(Share::SHARE_TYPE_ROOM)) {
				$shareTypes[] = Share::SHARE_TYPE_ROOM;
			}
		} else {
			$shareTypes[] = Share::SHARE_TYPE_GROUP;
			$shareTypes[] = Share::SHARE_TYPE_EMAIL;
		}

		// FIXME: DI
		if (\OC::$server->getAppManager()->isEnabledForUser('circles') && class_exists('\OCA\Circles\ShareByCircleProvider')) {
			$shareTypes[] = Share::SHARE_TYPE_CIRCLE;
		}

		if (isset($_GET['shareType']) && is_array($_GET['shareType'])) {
			$shareTypes = array_intersect($shareTypes, $_GET['shareType']);
			sort($shareTypes);
		} else if (is_numeric($shareType)) {
			$shareTypes = array_intersect($shareTypes, [(int) $shareType]);
			sort($shareTypes);
		}

		return new DataResponse(
			$this->getAllSharees($this->userId, $shareTypes)->asArray()
		);
	}

	/**
	 * Method to get out the static call for better testing
	 *
	 * @param string $itemType
	 * @return bool
	 */
	protected function isRemoteSharingAllowed(string $itemType): bool {
		try {
			// FIXME: static foo makes unit testing unnecessarily difficult
			$backend = \OC\Share\Share::getBackend($itemType);
			return $backend->isShareTypeAllowed(Share::SHARE_TYPE_REMOTE);
		} catch (\Exception $e) {
			return false;
		}
	}

	protected function isRemoteGroupSharingAllowed(string $itemType): bool {
		try {
			// FIXME: static foo makes unit testing unnecessarily difficult
			$backend = \OC\Share\Share::getBackend($itemType);
			return $backend->isShareTypeAllowed(Share::SHARE_TYPE_REMOTE_GROUP);
		} catch (\Exception $e) {
			return false;
		}
	}


	/**
	 * Generates a bunch of pagination links for the current page
	 *
	 * @param int $page Current page
	 * @param array $params Parameters for the URL
	 * @return string
	 */
	protected function getPaginationLink(int $page, array $params): string {
		if ($this->isV2()) {
			$url = $this->urlGenerator->getAbsoluteURL('/ocs/v2.php/apps/files_sharing/api/v1/sharees') . '?';
		} else {
			$url = $this->urlGenerator->getAbsoluteURL('/ocs/v1.php/apps/files_sharing/api/v1/sharees') . '?';
		}
		$params['page'] = $page + 1;
		return '<' . $url . http_build_query($params) . '>; rel="next"';
	}

	/**
	 * @return bool
	 */
	protected function isV2(): bool {
		return $this->request->getScriptName() === '/ocs/v2.php';
	}

    /**
     * @param $searchTerm
     * @param $lookup
     * @param $lookupSchool
     * @return mixed
     */
    private function searchResults($searchTerm, $lookup, $lookupSchool) {
        try {
            $result = [
                "exact" => [
                    "users" => [],
                    "groups" => [],
                    "emails" => [],
                    "remotes" => [],
                ],
                "users" => [],
                "groups" => [],
                "emails" => [],
                "remotes" => []
            ];
            $users = [];
            $groups = [];

            if ($lookup === true) {
                $usersQuery = $this->db->getQueryBuilder();
                $usersQuery->select(['u.uid', 'u.displayName', 'a.data'])
                    ->from('users', 'u')
                    ->join('u', 'accounts', 'a', 'u.uid = a.uid')
                    ->where('LOWER(u.displayName) LIKE LOWER(\'%' . $searchTerm . '%\')')
                    ->where('LOWER(JSON_EXTRACT(a.data, \'$.email.value\')) LIKE LOWER(\'%' . $searchTerm . '%\')')
                    ->orderBy('u.displayName');
                $usersFetched = $usersQuery->execute()->fetchAll();

                $groupsQuery = $this->db->getQueryBuilder();
                $groupsQuery->select(['gid', 'displayName'])
                    ->from('groups')
                    ->where('LOWER(displayName) LIKE LOWER(\'%' . $searchTerm . '%\')');

                $groupsFetched = $groupsQuery->execute()->fetchAll();
                $users = array_map(function ($user) {
                    $userEmail = "";
                    if (!is_null($user["data"])) {
                        $accountData = json_decode($user["data"], true);
                        if (array_key_exists("email", $accountData) && array_key_exists("value", $accountData["email"])) {
                            $userEmail =  $accountData["email"]["value"];
                        }

                    }
                    return [
                        "label" => $user["displayName"] . " - " . $userEmail,
                        "email" => $userEmail,
                        "value" => [
                            "shareType" => 0,
                            "shareWith" => $user["uid"],
                        ]
                    ];
                }, $usersFetched);
                $groups = array_map(function ($user) {
                    return [
                        "label" => $user["displayName"],
                        "value" => [
                            "shareType" => 0,
                            "shareWith" => $user["gid"],
                        ]
                    ];
                }, $groupsFetched);
            }
            else {
                if ($lookupSchool === true) {
                    $qb = $this->db->getQueryBuilder();
                    $qb->select('id_etablissement')
                        ->from('asso_uai_user_group')
                        ->where($qb->expr()->eq('user_group', $qb->createNamedParameter($this->userId)));
                    $userEtablissements = $qb->execute()->fetchAll();
                    $userIdEtablissement = array_unique(array_map(function ($asso) {
                        return $asso['id_etablissement'];
                    }, $userEtablissements));

                    $query = $this->db->getQueryBuilder();
                    $query->select('user_group')
                        ->from('asso_uai_user_group')
                        ->where($query->expr()->in('id_etablissement', $query->createNamedParameter(
                            $userIdEtablissement,
                            Connection::PARAM_STR_ARRAY
                        )));
                    $searchedUserGroup = array_map(function ($userGroup) {
                        return $userGroup['user_group'];
                    }, $query->execute()->fetchAll());
                    list($users, $groups) = $this->getUsersAndGroupsFromIdsListAndSearchTerm($searchedUserGroup, $searchTerm);
                }
                else {
                    $currentSiren = $this->getCurrentSirenSchool();
                    if (!is_null($currentSiren)) {
                        $query = $this->db->getQueryBuilder();
                        $query->select('id')
                            ->from('etablissements')
                            ->where($query->expr()->eq('siren', $query->createNamedParameter(
                                $currentSiren
                            )));

                        $etablissements = $query->execute()->fetchAll();
                        if (count($etablissements) > 0) {
                            $query = $this->db->getQueryBuilder();
                            $query->select('user_group')
                                ->from('asso_uai_user_group')
                                ->where($query->expr()->eq('id_etablissement', $query->createNamedParameter(
                                    $etablissements[0]['id']
                                )));
                            $searchedUserGroup = array_map(function ($userGroup) {
                                return $userGroup['user_group'];
                            }, $query->execute()->fetchAll());
                            list($users, $groups) = $this->getUsersAndGroupsFromIdsListAndSearchTerm($searchedUserGroup, $searchTerm);
                        }
                    }
                }
            }
        } catch (\Throwable $t) {
            $users = [];
            $groups = [];
        }
        $result["users"] = $users;
        $result["groups"] = $groups;
        return $result;
    }

    /**
     * @param $searchedUserGroup
     * @param $searchTerm
     * @return mixed
     */
    private function getUsersAndGroupsFromIdsListAndSearchTerm($searchedUserGroup, $searchTerm) {
        $usersQuery = $this->db->getQueryBuilder();
        $usersQuery->select(['u.uid', 'u.displayName', 'a.data'])
            ->from('users', 'u')
            ->where('LOWER(JSON_VALUE(a.data, \'$.email.value\')) LIKE LOWER(\'%' . $searchTerm . '%\')')
            ->where('LOWER(u.displayName) LIKE LOWER(\'%' . $searchTerm . '%\')')
            ->andWhere($usersQuery->expr()->in('u.uid', $usersQuery->createNamedParameter(
                $searchedUserGroup,
                Connection::PARAM_STR_ARRAY
            )))
            ->orderBy('u.displayName');

        $usersFetched = $usersQuery->execute()->fetchAll();
        $groupsQuery = $this->db->getQueryBuilder();
        $groupsQuery->select(['gid', 'displayName'])
            ->from('groups')
            ->where('LOWER(displayName) LIKE LOWER(\'%' . $searchTerm . '%\')')
            ->andWhere($groupsQuery->expr()->in('gid', $groupsQuery->createNamedParameter(
                $searchedUserGroup,
                Connection::PARAM_STR_ARRAY
            )));

        $groupsFetched = $groupsQuery->execute()->fetchAll();
        $users = array_map(function ($user) {
            $userEmail = "";
            if (!is_null($user["data"])) {
                $accountData = json_decode($user["data"], true);
                if (array_key_exists("email", $accountData) && array_key_exists("value", $accountData["email"])) {
                    $userEmail =  $accountData["email"]["value"];
                }

            }
            return [
                "label" => $user["displayName"] . " - " . $userEmail,
                "email" => $userEmail,
                "value" => [
                    "shareType" => 0,
                    "shareWith" => $user["uid"],
                ]
            ];
        }, $usersFetched);
        $groups = array_map(function ($user) {
            return [
                "label" => $user["displayName"],
                "value" => [
                    "shareType" => 0,
                    "shareWith" => $user["gid"],
                ]
            ];
        }, $groupsFetched);
        return [$users, $groups];
    }

    /**
     * @param $baseDn
     * @param $filter
     * @param $attributes
     * @return mixed
     */
    private function searchLdap($baseDn, $filter, $attributes) {
        try {
            $host = $this->config->getAppValue('ldapimporter', 'cas_import_ad_host');

            $ldapConnection = ldap_connect($this->config->getAppValue('ldapimporter', 'cas_import_ad_protocol') . $host . ":" . $this->config->getAppValue('ldapimporter', 'cas_import_ad_port')) or die("Could not connect to " . $host);

            ldap_set_option($ldapConnection, LDAP_OPT_PROTOCOL_VERSION, 3);
            ldap_set_option($ldapConnection, LDAP_OPT_REFERRALS, 0);
            ldap_set_option($ldapConnection, LDAP_OPT_NETWORK_TIMEOUT, 10);

            if ($ldapConnection) {
                $ldapIsBound = ldap_bind($ldapConnection, $this->config->getAppValue('ldapimporter', 'cas_import_ad_user'), $this->config->getAppValue('ldapimporter', 'cas_import_ad_password'));
                if (!$ldapIsBound) {
                    throw new \Exception("LDAP bind failed. Error: " . ldap_error($this->ldapConnection));
                }


                // Query user attributes
                //$results = ldap_search($ldapConnection, 'dc=esco-centre,dc=fr', sprintf('(|(displayName=*%s*)(cn=*%s*))', $searchTerm, $searchTerm), ["uid"]);
                $results = ldap_search($ldapConnection, $baseDn, $filter, $attributes);
                if (ldap_error($ldapConnection) == "No such object") {
                    return [];
                }
                elseif (ldap_error($ldapConnection) != "Success") {
                    throw new \Exception('Error searching LDAP: ' . ldap_error($ldapConnection));
                }

                $attributes = ldap_get_entries($ldapConnection, $results);

            }

        } catch (\Throwable $t) {
            $attributes = [];
        }
        if(isset($ldapConnection)) {
            ldap_close($ldapConnection);
        }
        return $attributes;
    }

    /**
     * @param bool $lookupSchool
     * @param $result
     * @return mixed
     */
    private function filterSchoolUsersGroups(bool $lookupSchool, $result)
    {
        $currentSiren = $this->getCurrentSirenSchool();
        if ($lookupSchool !== true) {
            if (!is_null($currentSiren)) {
                $query = $this->db->getQueryBuilder();
                $query->select('id')
                    ->from('etablissements')
                    ->where($query->expr()->eq('siren', $query->createNamedParameter(
                        $currentSiren
                    )));

                $etablissements = $query->execute()->fetchAll();
                if (count($etablissements) > 0) {
                    $query = $this->db->getQueryBuilder();
                    $query->select('user_group')
                        ->from('asso_uai_user_group')
                        ->where($query->expr()->eq('id_etablissement', $query->createNamedParameter(
                            $etablissements[0]['id']
                        )));
                    $searchedUserGroup = array_map(function ($userGroup) {
                        return $userGroup['user_group'];
                    }, $query->execute()->fetchAll());
                } else {
                    $searchedUserGroup = [
                        "groups" => [],
                        "users" => []
                    ];
                }
            } else {
                $searchedUserGroup = [
                    "groups" => [],
                    "users" => []
                ];
            }
        } else {
            $qb = $this->db->getQueryBuilder();
            $qb->select('id_etablissement')
                ->from('asso_uai_user_group')
                ->where($qb->expr()->eq('user_group', $qb->createNamedParameter($this->userId)));
            $userEtablissements = $qb->execute()->fetchAll();
            $userIdEtablissement = array_unique(array_map(function ($asso) {
                return $asso['id_etablissement'];
            }, $userEtablissements));


            $query = $this->db->getQueryBuilder();
            $query->select('user_group')
                ->from('asso_uai_user_group')
                ->where($query->expr()->in('id_etablissement', $query->createNamedParameter(
                    $userIdEtablissement,
                    Connection::PARAM_STR_ARRAY
                )));
            $searchedUserGroup = array_map(function ($userGroup) {
                return $userGroup['user_group'];
            }, $query->execute()->fetchAll());

        }

        $groups = [];

        foreach ($result["groups"] as $groupFor) {
            if (in_array($groupFor['value']['shareWith'], $searchedUserGroup)) {
                $groups[] = $groupFor;
            }
        }
        $result["groups"] = $groups;


        $users = [];

        foreach ($result["users"] as $userFor) {
            if (in_array($userFor['value']['shareWith'], $searchedUserGroup)) {
                $users[] = $userFor;
            }
        }
        $result["users"] = $users;
        return $result;
    }


    private function getCurrentSirenSchool() {
        try {
            $currentSchool = null;

            $host = $this->config->getAppValue('ldapimporter', 'cas_import_ad_host');

            $ldapConnection = ldap_connect($this->config->getAppValue('ldapimporter', 'cas_import_ad_protocol') . $host . ":" . $this->config->getAppValue('ldapimporter', 'cas_import_ad_port')) or die("Could not connect to " . $host);

            ldap_set_option($ldapConnection, LDAP_OPT_PROTOCOL_VERSION, 3);
            ldap_set_option($ldapConnection, LDAP_OPT_REFERRALS, 0);
            ldap_set_option($ldapConnection, LDAP_OPT_NETWORK_TIMEOUT, 10);

            if ($ldapConnection) {
                $ldapIsBound = ldap_bind($ldapConnection, $this->config->getAppValue('ldapimporter', 'cas_import_ad_user'), $this->config->getAppValue('ldapimporter', 'cas_import_ad_password'));
                if (!$ldapIsBound) {
                    throw new \Exception("LDAP bind failed. Error: " . ldap_error($this->ldapConnection));
                }

                // Disable pagination setting, not needed for individual attribute queries
                ldap_control_paged_result($ldapConnection, 1);

                // Query user attributes
                $results = ldap_search($ldapConnection, 'uid=' . $this->userId . ',ou=people,dc=esco-centre,dc=fr', 'objectClass=*', ["ESCOSIRENCourant"]);
                if (ldap_error($ldapConnection) == "No such object") {
                    return [];
                }
                elseif (ldap_error($ldapConnection) != "Success") {
                    throw new \Exception('Error searching LDAP: ' . ldap_error($ldapConnection));
                }

                $attributes = ldap_get_entries($ldapConnection, $results);

                // Return attributes list
                if (isset($attributes[0]) && array_key_exists('escosirencourant', $attributes[0]) && isset($attributes[0]['escosirencourant'][0])) {
                    $currentSchool = $attributes[0]['escosirencourant'][0];
                }
                else {
                    $currentSchool = null;
                }
            }

        } catch (\Throwable $t) {
            $currentSchool = null;
        }
        if(isset($ldapConnection)) {
            ldap_close($ldapConnection);
        }
        return $currentSchool;

    }
}
