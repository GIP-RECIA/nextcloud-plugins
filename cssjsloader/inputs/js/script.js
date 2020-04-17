
var body = document.getElementsByTagName("body")[0];
if (body.id == 'body-login') {
	window.location.href="apps/user_cas/login";
	window.location.reload();
} else {

if (typeof EscoNextAddon == 'undefined' ) {
    EscoNextAddon = new Object();

    EscoNextAddon.mylog = function() {};
    if (window['console'] !== undefined && false) {
        EscoNextAddon.mylog = function(s) { console.log(s); };
        EscoNextAddon.mylog("EscoNextAddon mylog defined!");
    }

    EscoNextAddon.getvalueCSS = function getvalueCSS( myWindow,  oEle, styleProp ){
        var sResult = undefined, oCss = null;
        if ( myWindow.getComputedStyle ) {
            if (oEle.ownerDocument.defaultView.opener ) {
                oCss = oEle.ownerDocument.defaultView.getComputedStyle( oEle, null );
            } else {
                oCss = myWindow.getComputedStyle( oEle, null );
        }
        sResult =  oCss.getPropertyValue(styleProp);
        } else if ( myWindow.document.documentElement.currentStyle ) {
            oCss = oEle.currentStyle;
            if(typeof oCss.getPropertyValue !='undefined'){
                sResult = oCss.getPropertyValue(styleProp);
            } else {
                sResult = oCss[styleProp];
            }
        }
        return sResult;
    }
    EscoNextAddon.initParent = function() {
        // init de resizer de l'iframe parent
        try {
            var parWin = window.parent;
            if (parWin) {
                //detection de la couleur du bandeau du portail:
                var bandeauPortal = parWin.document.getElementById('wrapper');
                var header = bandeauPortal.getElementsByTagName('header');
                var color = EscoNextAddon.getvalueCSS(parWin, header[0], 'background-color');

                EscoNextAddon.classToAdd = 'embedded';
                EscoNextAddon.mylog("color = " + color);
                if (color == 'rgb(37, 178, 243)') {
                    //#25b2f3
                    EscoNextAddon.classToAdd ="esco"
                } else if (color == 'rgb(45, 140, 23)') {
                	//#2d8c17
                    	EscoNextAddon.classToAdd = "agri";
                } else if (color == 'rgb(198, 4, 64)') {
                    	//#c60440
                    EscoNextAddon.classToAdd = "clg37";
                }
                EscoNextAddon.mylog("class to add = " + EscoNextAddon.classToAdd);
                // supression de la scroll
                var parBody = parWin.document.body;
                if (parBody) {

                    parBody = parWin.document.getElementById('portalPageBodyColumns');
                    if (parBody) {
                        var ifr;
                        EscoNextAddon.iframe = ifr = parBody.getElementsByTagName('iframe')[0];
                        var previousHeight = ifr.getAttribute('height');

                        if (ifr.style.minHeight == '' ){
                            ifr.style.minHeight = ""+ previousHeight+"px";
                                                }

                        ifr.style.overflow = "hidden";
                        ifr.setAttribute("allowfullscreen" ,'true');
                        EscoNextAddon.initParent = function(){return true;}
                    } else {
                        EscoNextAddon.mylog("erreur can't init iframe " );
                    }
                } else {
                    EscoNextAddon.mylog("erreur can't get parent body  " );
                }
                
                // decalage des modals en fonction de la scrollBar du parent
                // on ne decale que les modals invisible, quand la modal est visible 
                // elle se deplace avec le scroll
                var scrolling = parWin.document.scrollingElement;
                if (scrolling) {
                    //	console.log("Scrolling ok");
                    var modals = $('div.modal-content');
                    if (modals) {
                    //	console.log("modals ok");
                        parWin.document.onscroll= function(){
                            $(modals).each(function(){
                                if ( ! $(this).is(':visible')){
                                    $(this).css('top', scrolling.scrollTop);
            }
                            });
                        //	$(modals).css('top', scrolling.scrollTop); 
                        };
                    }
                }
                return true;
            }

            return false;
        } catch (err) {
            EscoNextAddon.mylog("erreur can't init parent " + err);
            EscoNextAddon.initParent = function(){return false;}
            return false;
        }

    }

    EscoNextAddon.setClassBody = function(embedded){
        if (EscoNextAddon.classToAdd) {
            var cl = window.document.body.classList;
            cl.add(EscoNextAddon.classToAdd);
            if (embedded) {
				cl.add( embedded);
			}
        }
    }

    function resizeIfr(ifr){
        var doc;
        if (ifr) {
            ifr.style.overflow = "hidden";
            doc = ifr.contentDocument;
        } else {
            doc = window.document;
            }
        if (doc == 'undefined') {
            doc = ifr.contentWindow.document;
        }
        if (doc) {
            var body = doc.body;

            if (body) {
                if (ifr) body.style.overflow = "hidden";
                var allIfr = body.getElementsByTagName('iframe');
                var cpt;
                for (cpt = 0; cpt < allIfr.length; cpt++ ) {
                    EscoNextAddon.resizeIfr(allIfr[cpt]);
				}
				var height = body.offsetHeight + 0;
                if (ifr) {
             //       console.log(height);
                    ifr.setAttribute("height", height);
				} else {
						if (typeof EscoNextAddon.target == "undefined" ) {
							EscoNextAddon.target.postMessage("iframeHeight " + height, "*");
						}
				}
                return true;
			}
        } else {
            return false;
        }
    }
    EscoNextAddon.resizeIfr = resizeIfr;

/*    function resizeIfrTimer(ifr) {
	  setInterval(function(){
		 resizeIfr(ifr) 
	  }, 500);

}
    EscoNextAddon.resizeIfrTimer = resizeIfrTimer;
*/

	EscoNextAddon.initPostMessage = function  {
		EscoNextAddon.target = parent.postMessage ? parent : (parent.document.postMessage ? parent.document : undefined);
		if (typeof target == "undefined") return true;
		return false;
	}
	
	function postMessageResize(height){
		EscoNextAddon.target.postMessage("iframeHeight " + height, "*");
	}
	
} else {
    EscoNextAddon.mylog('rechargement EscoNextAddon');
}

	
$(function(){

	if (EscoNextAddon.initPostMessage()) {
		alert('post message init');
		EscoNextAddon.resizeIfr();
			setInterval(function(){ EscoNextAddon.resizeIfr()} , 500);
	} else {
    
    if (EscoNextAddon.initParent()) {
		EscoNextAddon.setClassBody('embedded');

        EscoNextAddon.mylog("EscoNextAddon.initParent = true");
        var ifr = EscoNextAddon.iframe;
        if (ifr) {
			EscoNextAddon.resizeIfr(ifr);
			setInterval(function(){ EscoNextAddon.resizeIfr(ifr)} , 500);
			$('[target="_blank"]').attr("target", '');
		}
    } else {
		var host = window.location.hostname;
		var dom = new Object();
		dom['test-clg37.giprecia.net']='clg37';
		dom['test-lycee.giprecia.net']='esco';
		EscoNextAddon.classToAdd = dom[host];
		EscoNextAddon.setClassBody();
	}
}
});
}
