<?php

declare(strict_types=1);

namespace OCA\LdapImporter\AppInfo;

return [
	'routes' => [
		[
			'name' => 'Settings#saveSettings',
			'url' => '/settings/save',
			'verb' => 'POST'
		]
	],
];
