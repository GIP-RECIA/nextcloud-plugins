$(document).ready(function() {

	var urlRegex = /https?:\/\/([^\/]+)/,
		$urlInput = $('#cssjsloader-url'),
		$textarea = $('#cssjsloader-snippet'),
		$section = $('#cssjsloader-section'),
		$saveButton = $section.find('button'),
		cachebuster = parseInt($section.data('cachebuster'));

	$('#cssjsloader-save').on('click', function(event) {
		event.preventDefault();

		var selector = '#cssjsloader-message',
			snippetValue = $textarea.val(),
			urlValue = $urlInput.val();

		$textarea.prop('disabled', true);
		$urlInput.prop('disabled', true);
		OC.msg.startSaving(selector);

		OCP.AppConfig.setValue('cssjsloader', 'snippet', snippetValue, {
			success: function(){
				$textarea.prop('disabled', false);

				OCP.AppConfig.setValue('cssjsloader', 'url', urlValue, {
					success: function(){
						$urlInput.prop('disabled', false);
						OC.msg.finishedSuccess(selector, t('settings', 'Saved'));
					},
					error: function(){
						$urlInput.prop('disabled', false);
						OC.msg.finishedError(selector, t('cssjsloader', 'Error while saving'));
					}
				});
			},
			error: function(){
				$textarea.prop('disabled', false);
				$urlInput.prop('disabled', false);
				OC.msg.finishedError(selector, t('cssjsloader', 'Error while saving'));
			}
		});

		cachebuster += 1;
		OCP.AppConfig.setValue('cssjsloader', 'cachebuster', cachebuster);
	});


	/**
	 * try to detect an URL from the snippet input
	 */
	$textarea.on('change', function() {
		var value = $textarea.val(),
			result = urlRegex.exec(value);

		if ($urlInput.val() === '' && result !== null) {
			$urlInput.val(result[1]);
		}

		$saveButton.prop('disabled', false);
	});

	$urlInput.on('change', function() {
		$saveButton.prop('disabled', false);
	})
});
