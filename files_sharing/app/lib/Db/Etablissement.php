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

use JsonSerializable;

use OCP\AppFramework\Db\Entity;

class Etablissement extends Entity implements JsonSerializable {

    protected $name;
    protected $uai;
    protected $siren;
	protected $selected;

    public function __construct() {
        $this->addType('id','integer');
		$this->selected = false;
    }

    public function jsonSerialize() {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'uai' => $this->uai,
			'siren' => $this->siren,
			'selected'=> $this->selected
        ];
    }
}
