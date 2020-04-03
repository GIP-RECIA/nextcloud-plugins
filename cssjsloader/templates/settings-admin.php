<?php

/** @var array $_ */
/** @var \OCP\IL10N $l */
script('cssjsloader', 'admin');
style('cssjsloader', 'admin');
?>

<div id="cssjsloader-section" class="section" data-cachebuster="<?php print_unescaped($_['cachebuster']); ?>">
	<h2 class="inlineblock"><?php p($l->t('JavaScript loader')); ?></h2>
	<p>
		<?php p($l->t('Paste the JS code snippet here. It will be loaded on every page.')); ?>
	</p>
	<textarea id="cssjsloader-snippet"><?php print_unescaped($_['snippet']); ?></textarea>
	<label for="cssjsloader-url"><?php p($l->t('Domain where external JavaScript is loaded from. This is needed to work with the CSP policy that is in place. It is tried to automatically detect this based on the snippet above if empty.')); ?></label>
	<input id="cssjsloader-url" name="cssjsloader-url" type="text" value="<?php print_unescaped($_['url']); ?>">
	<button id="cssjsloader-save" class="btn btn-primary" disabled="disabled"><?php p($l->t('Save')); ?></button>
	<span id="cssjsloader-message" class="msg"></span>
</div>
