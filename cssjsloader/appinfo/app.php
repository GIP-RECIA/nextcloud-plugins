<?php

namespace OCA\CSSJSLoader\Appinfo;

use OC\Security\CSP\ContentSecurityPolicy;

$config = \OC::$server->getConfig();

$snippet = $config->getAppValue('cssjsloader', 'snippet', '');

if ($snippet !== '') {
	$linkToJs = \OC::$server->getURLGenerator()->linkToRoute(
		'cssjsloader.CSSJS.script',
		[
			'v' => '0',
		]
	);

    $linkToCss = \OC::$server->getURLGenerator()->linkToRoute(
        'cssjsloader.CSSJS.style',
        [
            'v' => '0',
        ]
    );

    \OCP\Util::addHeader(
		'script',
		[
			'src' => $linkToJs,
			'nonce' => \OC::$server->getContentSecurityPolicyNonceManager()->getNonce()
		], ''
	);

    \OCP\Util::addHeader(
        'link',
        [
            'rel' => 'stylesheet',
            'href' => $linkToCss,
        ]
    );

    // whitelist the URL to allow loading JS from this external domain
	$url = $config->getAppValue('cssjsloader', 'url');
	if ($url !== '') {
		$CSPManager = \OC::$server->getContentSecurityPolicyManager();
		$policy = new ContentSecurityPolicy();
		$policy->addAllowedScriptDomain($url);
		$policy->addAllowedImageDomain($url);
		$policy->addAllowedConnectDomain($url);
		$CSPManager->addDefaultPolicy($policy);
	}
}
