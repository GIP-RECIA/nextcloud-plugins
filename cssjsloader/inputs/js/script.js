
var body = document.getElementsByTagName("body")[0];
if (body.id == 'body-login') {
	window.location.href="apps/user_cas/login";
	window.location.reload();
} else {

	if (typeof EscoNextAddon == 'undefined' ) {
		EscoNextAddon = new Object();

		EscoNextAddon.setClassBody = function(embedded){
			if (EscoNextAddon.classToAdd) {
				var cl = window.document.body.classList;
				cl.add(EscoNextAddon.classToAdd);
				if (embedded) {
					cl.add( embedded);
				}
			}
		}
	}

		
	$(function(){
		var host = window.location.hostname;
		alert(host);
		var dom = new Object();
		dom['test-clg37.giprecia.net']='clg37';
		dom['test-lycee.giprecia.net']='esco';
		dom['nc-lycees.netocentre.fr']='esco';
		dom['nc-agri.netocentre.fr']= 'agri';
		
		EscoNextAddon.classToAdd = dom[host];
		EscoNextAddon.setClassBody('embedded');

	});
}
