<?php
/**
 * @var \OC_Defaults $theme
 * @var array $_
 * @var  \OC_Theme $escoTheme
 */

$cacheBuster = date("Ymd");

$getUserAvatar = static function (int $size) use ($_): string {
	return \OC::$server->getURLGenerator()->linkToRoute('core.avatar.getAvatar', [
		'userId' => $_['user_uid'],
		'size' => $size,
		'v' => $_['userAvatarVersion']
	]);
}

?><!DOCTYPE html>
<html class="ng-csp" data-placeholder-focus="false" lang="<?php p($_['language']); ?>" data-locale="<?php p($_['locale']); ?>" translate="no" >
	<head data-user="<?php p($_['user_uid']); ?>" data-user-displayname="<?php p($_['user_displayname']); ?>" data-requesttoken="<?php p($_['requesttoken']); ?>">
		<meta charset="utf-8">
		<?php //mise en place du bandeau ENT
			emit_script_tag("/commun/extended-uportal-header.min.js?$cacheBuster"); 
			emit_script_tag("/commun/extended-uportal-footer.min.js?$cacheBuster"); 
			$request = \OC::$server->getRequest();
		?>
		<title>
			<?php
				p(!empty($_['pageTitle']) && $_['pageTitle'] !== $_['application'] ? $_['pageTitle'].' - ' : '');
p(!empty($_['application']) ? $_['application'].' - ' : '');
				p($theme->getTitle());
			?>
		</title>
		<meta name="viewport" content="width=device-width, initial-scale=1.0" />

		<?php if ($theme->getiTunesAppId() !== '') { ?>
		<meta name="apple-itunes-app" content="app-id=<?php p($theme->getiTunesAppId()); ?>">
		<?php } ?>
		<meta name="apple-mobile-web-app-capable" content="yes">
		<meta name="apple-mobile-web-app-status-bar-style" content="black">
		<meta name="apple-mobile-web-app-title" content="<?php p((!empty($_['application']) && $_['appid'] != 'files')? $_['application']:$theme->getTitle()); ?>">
		<meta name="mobile-web-app-capable" content="yes">
		<meta name="theme-color" content="<?php p($theme->getColorPrimary()); ?>">
		<link rel="icon" href="<?php print_unescaped(image_path($_['appid'], 'favicon.ico')); /* IE11+ supports png */ ?>">
		<link rel="apple-touch-icon" href="<?php print_unescaped(image_path($_['appid'], 'favicon-touch.png')); ?>">
		<link rel="apple-touch-icon-precomposed" href="<?php print_unescaped(image_path($_['appid'], 'favicon-touch.png')); ?>">
		<link rel="mask-icon" sizes="any" href="<?php print_unescaped(image_path($_['appid'], 'favicon-mask.svg')); ?>" color="<?php p($theme->getColorPrimary()); ?>">
		<link rel="manifest" href="<?php print_unescaped(image_path($_['appid'], 'manifest.json')); ?>" crossorigin="use-credentials">
		<?php emit_css_loading_tags($_); ?>
		<?php emit_css_tag(\OC_Theme::getContext($request) . "/themes/esco/css/reciaStyle.css?$cacheBuster"); ?>

		<?php emit_script_loading_tags($_); ?>
		<?php   emit_script_tag(\OC_Theme::getContext($request) . "/themes/esco/js/recia.js?$cacheBuster"); ?>

		<?php print_unescaped($_['headers']); ?>

	</head>
	<body id="<?php p($_['bodyid']);?>"  class="<?php p(\OC_Theme::getCssClass($request)) ?>" >

	<!--?php foreach ($_['enabledThemes'] as $themeId) {
				p("data-theme-$themeId ");
			}?> data-themes=<?php p(join(',', $_['enabledThemes'])) ?> -->
	<?php include 'layout.noscript.warning.php'; ?>

<div id="escoDiv" >
	<header id="escoHeader" >
		<extended-uportal-header
			service-name="nextcloud"
			context-api-url="/portail"
			sign-out-url="/portail/Logout"
			default-org-logo-path="/annuaire_images/default_banner_v1.jpg"
			default-avatar-path="/images/icones/noPictureUser.svg"
			default-org-icon-path="/images/partners/netocentre-simple.svg"
			favorite-api-url="/portail/api/layout"
			layout-api-url="/portail/api/v4-3/dlm/layout.json"
			organization-api-url="/change-etablissement/rest/v2/structures/structs/"
			portlet-api-url="/portail/api/v4-3/dlm/portletRegistry.json?category=All%20categories"
			user-info-api-url="/portail/api/v5-1/userinfo?claims=private,picture,name,ESCOSIRENCourant,ESCOSIREN&groups="
			user-info-portlet-url="/portail/api/ExternalURLStats?fname=ESCO-MCE&amp;service=/MCE"
			template-api-path="/commun/portal_template_api.tpl.json"
			switch-org-portlet-url="/portail/p/etablissement-swapper"
			favorites-portlet-card-size="small"
			grid-portlet-card-size="auto"
			hide-action-mode="never"
			show-favorites-in-slider="true"
			return-home-title="Aller à l'accueil"
			return-home-target="_self"
			icon-type="nine-square"
			messages='[{"locales": ["fr", "fr-FR"], "messages": { "message": {"header": {"login": "Connexion ENT" } }}}]'
			height="38px"
			session-api-url="/portail/api/session.json"
<?php
	$portal_domain = \OC_Theme::getDomain($request);
//	error_log("portal_domain = $portal_domain \n", 3, "/home/esco/logs/themes.esco.log" );
	if ($portal_domain) {
		$portal_login_url = \OC_Theme::getPortailLoginUrl($request);
		print_unescaped('				domain="' . $portal_domain . '"'  . "\n" );
		if ($portal_login_url) {
			print_unescaped('			sign-in-url="'. $portal_login_url . '"' ."\n");
		}
	}
?>
		>
			<div slot="not-loaded">
				<a href="https://netocentre.fr/">Connection à votre ENT</a> 
			</div>
		</extended-uportal-header>
	</header>
	<footer>
		<extended-uportal-footer id="reciaFooter"
			template-api-path="/commun/portal_template_api.tpl.json"
<?php
				if ($portal_domain) {
					print_unescaped('			domain="' . $portal_domain . '"'  . "\n" );
				}
?>
		>
		</extended-uportal-footer> 
	</footer>

	
		<?php foreach ($_['initialStates'] as $app => $initialState) { ?>
			<input type="hidden" id="initial-state-<?php p($app); ?>" value="<?php p(base64_encode($initialState)); ?>">
		<?php }?>

		<div id="skip-actions">
			<?php if ($_['id-app-content'] !== null) { ?><a href="<?php p($_['id-app-content']); ?>" class="button primary skip-navigation skip-content"><?php p($l->t('Skip to main content')); ?></a><?php } ?>
			<?php if ($_['id-app-navigation'] !== null) { ?><a href="<?php p($_['id-app-navigation']); ?>" class="button primary skip-navigation"><?php p($l->t('Skip to navigation of app')); ?></a><?php } ?>
		</div>

		<header id="header" class="escoDivWrapper">
			<div class="header-left">
				<a href="<?php print_unescaped($_['logoUrl'] ?: link_to('', 'index.php')); ?>"
					aria-label="<?php p($l->t('Go to %s', [$_['logoUrl'] ?: $_['defaultAppName']])); ?>"
					id="nextcloud">
					<div class="logo logo-icon"></div>
				</a>

				<nav id="header-left__appmenu"></nav>
			</div>

			<div class="header-right">
				<div id="unified-search"></div>
				<div id="notifications"></div>
				<div id="contactsmenu"></div>
				<div id="user-menu"></div>
			</div>
		</header>
</div>

		<main id="content" class="app-<?php p($_['appid']) ?>">
			<h1 class="hidden-visually" id="page-heading-level-1">
				<?php p((!empty($_['application']) && !empty($_['pageTitle']) && $_['application'] != $_['pageTitle'])
					? $_['application'].': '.$_['pageTitle']
					: (!empty($_['pageTitle']) ? $_['pageTitle'] : $theme->getName())
				); ?>
			</h1>
			<?php print_unescaped($_['content']); ?>
		</main>
		<div id="profiler-toolbar"></div>
		
<footer class="escoDiv">
			<extended-uportal-footer id="reciaFooter"
				template-api-path="/commun/portal_template_api.tpl.json"
			<?php
				if ($portal_domain) {
					print_unescaped('				domain="' . $portal_domain . '"'  . "\n" );
				}
			?>
			>
			</extended-uportal-footer> 
		</footer>
	</body>
</html>
