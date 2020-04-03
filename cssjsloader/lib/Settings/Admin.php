<?php

namespace OCA\CSSJSLoader\Settings;

use OCP\AppFramework\Http\TemplateResponse;
use OCP\IL10N;
use OCP\ILogger;
use OCP\Settings\ISettings;
use OCP\IConfig;

class Admin implements ISettings {

	/** @var IL10N */
	private $l;

	/** @var ILogger */
	private $logger;

	/** @var IConfig */
	private $config;

	public function __construct(
		IL10N $l,
		ILogger $logger,
		IConfig $config
	) {
		$this->l = $l;
		$this->logger = $logger;
		$this->config = $config;
	}

	/**
	 * @return TemplateResponse
	 */
	public function getForm() {
		$parameters = [
			'snippet'     => $this->config->getAppValue('cssjsloader', 'snippet', ''),
			'url'         => $this->config->getAppValue('cssjsloader', 'url', ''),
			'cachebuster' => $this->config->getAppValue('cssjsloader', 'cachebuster', '0'),
		];

		return new TemplateResponse('cssjsloader', 'settings-admin', $parameters, '');
	}

	/**
	 * @return string the section ID, e.g. 'sharing'
	 */
	public function getSection() {
		return 'cssjsloader';
	}

	/**
	 * @return int whether the form should be rather on the top or bottom of
	 * the admin section. The forms are arranged in ascending order of the
	 * priority values. It is required to return a value between 0 and 100.
	 *
	 * E.g.: 70
	 */
	public function getPriority() {
		return 70;
	}

}
