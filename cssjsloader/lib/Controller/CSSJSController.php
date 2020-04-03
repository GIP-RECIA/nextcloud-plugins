<?php

namespace OCA\CSSJSLoader\Controller;

use OCP\AppFramework\Controller;
use OCP\AppFramework\Http\DataDownloadResponse;
use OCP\AppFramework\Http\Response;
use OCP\IConfig;
use OCP\IRequest;

class CSSJSController extends Controller {

	/** @var \OCP\IConfig */
	protected $config;

	/**
	 * constructor of the controller
	 *
	 * @param string $appName
	 * @param IRequest $request
	 * @param IConfig $config
	 */
	public function __construct($appName,
								IRequest $request,
								IConfig $config) {
		parent::__construct($appName, $request);
		$this->config = $config;
	}

	/**
	 * @NoAdminRequired
	 * @NoCSRFRequired
	 * @PublicPage
	 *
	 * @return Response
	 */
	public function script() {
        $jsCode = '';
        $filesList = scandir('./apps/cssjsloader/inputs/js');
        foreach ($filesList as $file) {
            if ($this->endsWith($file, ".js")) {
                $jsCode .= ';' . file_get_contents('./apps/cssjsloader/inputs/js/' . $file);
            }
        }
		if ($jsCode !== '') {
            $jsCode = '$(document).ready(function() {' . $jsCode . '});';
		}
		return new DataDownloadResponse($jsCode, 'script', 'text/javascript');
	}

    /**
     * @NoAdminRequired
     * @NoCSRFRequired
     * @PublicPage
     *
     * @return Response
     */
	public function style() {
        $customCss = '';
        $filesList = scandir('./apps/cssjsloader/inputs/css');
        foreach ($filesList as $file) {
            if ($this->endsWith($file, ".css")) {
                $customCss .= file_get_contents('./apps/cssjsloader/inputs/css/' . $file);
            }
        }
        return new DataDownloadResponse($customCss, 'style', 'text/css');
	}

    private function endsWith($string, $endString)
    {
        $len = strlen($endString);
        if ($len == 0) {
            return true;
        }
        return (substr($string, -$len) === $endString);
    }
}