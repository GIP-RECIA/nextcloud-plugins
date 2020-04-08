<?php

namespace OCA\CSSJSLoader\Appinfo;

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