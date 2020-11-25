
var body = document.getElementsByTagName("body")[0];
if (body.id == 'body-login') {
//	window.location.href="apps/user_cas/login";
//	window.location.reload();
} else {

	if (typeof EscoNextAddon == 'undefined' ) {
		EscoNextAddon = new Object();

		EscoNextAddon.setClassBody = function(embedded){
			var cl = window.document.body.classList;
			if (EscoNextAddon.classToAdd) {
				cl.add(EscoNextAddon.classToAdd);
			}
			if (embedded) {
				cl.add( embedded);
			}
		}
	}

		
	$(function(){
		var embedded = parent == window ? 'not_embedded' : 'embedded';
		var host = window.location.hostname;

		var dom = new Object();
		dom['test-clg37.giprecia.net']='clg37';
		dom['test-lycee.giprecia.net']='esco';
		dom['recette-pub.nextcloud.recia.aquaray.com']='esco';
		dom['nc-lycees.netocentre.fr']='esco';
		dom['nc-agri.netocentre.fr']= 'agri';
		dom['nc.touraine-eschool.fr'] = 'clg37';
		dom['nc.chercan.fr'] = 'clg18';
		dom['nc.colleges41.fr'] = 'clg41';
		dom['nc.mon-e-college.loiret.fr'] = 'clg45';
		dom['nc.e-college.indre.fr'] = 'clg36';
		dom['nc-ent.recia.fr'] = 'esco';


		
		EscoNextAddon.classToAdd = dom[host];
		EscoNextAddon.setClassBody(embedded);

		$('div#personal-settings form input').attr('readonly', true)
	});
}
