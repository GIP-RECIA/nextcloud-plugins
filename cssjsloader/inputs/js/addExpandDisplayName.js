
(function () {
	let referenceNode = document.querySelector("div#settings div#expand.menutoggle div.avatardiv.avatardiv-shown");
	if (referenceNode) {
		let newNode = document.createElement("div", );
		newNode.id="explanDisplayName";
		newNode.classList.add("icon-settings-white");
		referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
	}
})();
