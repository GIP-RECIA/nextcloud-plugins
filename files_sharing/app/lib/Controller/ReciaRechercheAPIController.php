<?php

declare(strict_types=1);

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

namespace OCA\Files_Sharing\Controller;

use OCP\Constants;
use OCP\IRequest;
use OCP\AppFramework\Http\DataResponse;
use OCP\AppFramework\OCS\OCSBadRequestException;
use OCP\AppFramework\OCSController;
use OCP\IConfig;
use OCP\Share\IManager;
use OCP\IDBConnection;
use OCP\IGroupManager;
use OC\URLGenerator;

// use OCA\Files_Sharing\Controller\ShareesAPIController;
use OCA\Files_Sharing\Db\EtablissementMapper;
use OCA\Files_Sharing\Db\SearchDB;
use Symfony\Component\Routing\Generator\UrlGenerator as GeneratorUrlGenerator;

class ReciaRechercheAPIController extends OCSController {

	/** @var string */
	protected $userId;

	/** @var IConfig */
	protected $config;

	/** @var IManager */
	protected $shareManager;

	/**
	 * @var IGroupManager
	 */
	private $groupManager;

	/**
	 * @var EtablissementMapper
	 */
	private $etabMapper;

	/**
	 * @var SearchDB
	 */
	private $searchDB;

	/**
	 * @var urlGenerator
	 */
	private $urlGenerator;

	/**
	 * @var boolean
	 */
	private $debug = false;

	/**
	 * @param string $UserId
	 * @param string $appName
	 * @param IRequest $request
	 * @param IConfig $config
	 * @param IManager $shareManager
	 * @param EtablissementMapper $etabMapper
	 * @param IGroupManager $groupManager
	 */
	public function __construct(
		$UserId,
		string $appName,
		IRequest $request,
		IConfig $config,
		IManager $shareManager,
        IDBConnection $db,
		EtablissementMapper $etabMapper,
		SearchDB $searchDB,
		IGroupManager $groupManager,
		URLGenerator $urlGenerator
	)
	{
		parent::__construct($appName, $request);
		$this->userId = $UserId;
		$this->config = $config;
		$this->shareManager = $shareManager;
		$this->db = $db;
		$this->etabMapper = $etabMapper;
		$this->searchDB = $searchDB;
		$this->groupManager = $groupManager;
		$this->urlGenerator = $urlGenerator;
		$this->debug = (bool)$this->config->getSystemValue('debug', false);
	}

	/**
	 * Renvoie la liste des établissements liés à l'utilisateur courant
	 * Route : /api/v1/recia_list_etabs
	 *
	 * @NoAdminRequired
	 *
	 * @return DataResponse
	 * @throws OCSBadRequestException
	 */
	public function listUserEtabs():DataResponse{
		if($this->debug)$result['debug']['user'] = $this->userId;
		if($this->isAdmin()){
			$result['data'] = $this->etabMapper->findAll();
			if($this->debug)$result['debug']['isadmin'] = true;
		}else{
			$result['data'] = $this->etabMapper->findAllByUser($this->userId);
			if($this->debug)$result['debug']['isadmin'] = false;
		}
		if($result['data'] && count($result['data'])>=1){
			$currentEtabSiren = $this->getCurrentSirenSchool();
			$selected = false;
			array_walk($result['data'],function($etab) use ($currentEtabSiren,&$selected){
				if ($etab->getSiren() == $currentEtabSiren){
					$etab->setSelected(true);
					$selected = true;
				}
			});
			if(!$selected)$result['data'][0]->setSelected(true);
		}
		return new DataResponse($result);
	}

	/**
	 * Cherche les utilisateurs et les groupes correspondants à la recherche et la liste des établissements fournis
	 * Route : /api/v1/recia_search
	 *
	 * @NoAdminRequired
	 *
	 * @return DataResponse
	 * @throws OCSBadRequestException
	 */
	public function search(string $search,array $etabs = [], string $itemType = null, int $page = 1, int $perPage = 200):DataResponse{

		// only search if there is an etab
		if(empty($etabs)){
			return new DataResponse($this->result);
		}

		// only search for string larger than a given threshold
		$threshold = (int)$this->config->getSystemValue('sharing.minSearchStringLength', 0);
		if (strlen($search) < $threshold) {
			return new DataResponse($this->result);
		}

		// never return more than the max. number of results configured in the config.php
		$maxResults = $this->config->getSystemValueInt('sharing.maxAutocompleteResults', Constants::SHARING_MAX_AUTOCOMPLETE_RESULTS_DEFAULT);
		if ($maxResults > 0) {
			$perPage = min($perPage, $maxResults);
		}
		if ($perPage <= 0) {
			throw new OCSBadRequestException('Invalid perPage argument');
		}
		if ($page <= 0) {
			throw new OCSBadRequestException('Invalid page');
		}

		$this->limit = $perPage;
		$this->offset = $perPage * ($page - 1);

		//RECHERCHE
		list($result, $hasMoreResults) = $this->searchDB->searchAll($search, $etabs, $this->limit, $this->offset);

		$response = new DataResponse($result);

		if ($hasMoreResults) {
			$response->addHeader('Link', $this->getPaginationLink($page, [
				'search' => $search,
				'itemType' => $itemType,
				'perPage' => $perPage,
			]));
		}

		return $response;
	}

	/**
	 * Returns whether the currently logged in user is an administrator
	 *
	 * @return bool is admin
	 */
	private function isAdmin() {
		return $this->groupManager->isAdmin($this->userId);
	}
	/**
	 * Renvoie l'établissement courrant de l'utilisateur
	 *
	 * @return string siren de l'établissement courrant
	 */
	private function getCurrentSirenSchool() {
    	//return '19450042700035';
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
                //ldap_control_paged_result($ldapConnection, 1);
				// php 8 fix for ldap_control_paged_result deprecation
				$ldap_controls = [['oid' => LDAP_CONTROL_PAGEDRESULTS, 'value' => ['size' => 1, 'cookie' => '']]];

                // Query user attributes
                $results = ldap_search($ldapConnection, 'uid=' . $this->userId . ',ou=people,dc=esco-centre,dc=fr', 'objectClass=*', ["ESCOSIRENCourant"],0,-1,-1,LDAP_DEREF_NEVER,$ldap_controls);
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

	/**
	 * Generates a bunch of pagination links for the current page
	 *
	 * @param int $page Current page
	 * @param array $params Parameters for the URL
	 * @return string
	 */
	protected function getPaginationLink(int $page, array $params): string {
		if ($this->isV2()) {
			$url = $this->urlGenerator->getAbsoluteURL('/ocs/v2.php/apps/files_sharing/api/v1/recia_search') . '?';
		} else {
			$url = $this->urlGenerator->getAbsoluteURL('/ocs/v1.php/apps/files_sharing/api/v1/recia_search') . '?';
		}
		$params['page'] = $page + 1;
		return '<' . $url . http_build_query($params) . '>; rel="next"';
	}

	/**
	 * Renvoie si la version de l'api ocs est la v2
	 *
	 * @return bool
	 */
	protected function isV2(): bool {
		return $this->request->getScriptName() === '/ocs/v2.php';
	}

}
