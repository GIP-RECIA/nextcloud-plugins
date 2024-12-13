/*! For license information please see calendar-dashboard.js.LICENSE.txt */
(()=>{var e,t,r,n,o={95208:(e,t,r)=>{const n=r(49324),{MAX_LENGTH:o,MAX_SAFE_INTEGER:s}=r(50908),{safeRe:i,t:d}=r(99692),a=r(53632),{compareIdentifiers:l}=r(94113);class c{constructor(e,t){if(t=a(t),e instanceof c){if(e.loose===!!t.loose&&e.includePrerelease===!!t.includePrerelease)return e;e=e.version}else if("string"!=typeof e)throw new TypeError(`Invalid version. Must be a string. Got type "${typeof e}".`);if(e.length>o)throw new TypeError(`version is longer than ${o} characters`);n("SemVer",e,t),this.options=t,this.loose=!!t.loose,this.includePrerelease=!!t.includePrerelease;const r=e.trim().match(t.loose?i[d.LOOSE]:i[d.FULL]);if(!r)throw new TypeError(`Invalid Version: ${e}`);if(this.raw=e,this.major=+r[1],this.minor=+r[2],this.patch=+r[3],this.major>s||this.major<0)throw new TypeError("Invalid major version");if(this.minor>s||this.minor<0)throw new TypeError("Invalid minor version");if(this.patch>s||this.patch<0)throw new TypeError("Invalid patch version");r[4]?this.prerelease=r[4].split(".").map((e=>{if(/^[0-9]+$/.test(e)){const t=+e;if(t>=0&&t<s)return t}return e})):this.prerelease=[],this.build=r[5]?r[5].split("."):[],this.format()}format(){return this.version=`${this.major}.${this.minor}.${this.patch}`,this.prerelease.length&&(this.version+=`-${this.prerelease.join(".")}`),this.version}toString(){return this.version}compare(e){if(n("SemVer.compare",this.version,this.options,e),!(e instanceof c)){if("string"==typeof e&&e===this.version)return 0;e=new c(e,this.options)}return e.version===this.version?0:this.compareMain(e)||this.comparePre(e)}compareMain(e){return e instanceof c||(e=new c(e,this.options)),l(this.major,e.major)||l(this.minor,e.minor)||l(this.patch,e.patch)}comparePre(e){if(e instanceof c||(e=new c(e,this.options)),this.prerelease.length&&!e.prerelease.length)return-1;if(!this.prerelease.length&&e.prerelease.length)return 1;if(!this.prerelease.length&&!e.prerelease.length)return 0;let t=0;do{const r=this.prerelease[t],o=e.prerelease[t];if(n("prerelease compare",t,r,o),void 0===r&&void 0===o)return 0;if(void 0===o)return 1;if(void 0===r)return-1;if(r!==o)return l(r,o)}while(++t)}compareBuild(e){e instanceof c||(e=new c(e,this.options));let t=0;do{const r=this.build[t],o=e.build[t];if(n("prerelease compare",t,r,o),void 0===r&&void 0===o)return 0;if(void 0===o)return 1;if(void 0===r)return-1;if(r!==o)return l(r,o)}while(++t)}inc(e,t,r){switch(e){case"premajor":this.prerelease.length=0,this.patch=0,this.minor=0,this.major++,this.inc("pre",t,r);break;case"preminor":this.prerelease.length=0,this.patch=0,this.minor++,this.inc("pre",t,r);break;case"prepatch":this.prerelease.length=0,this.inc("patch",t,r),this.inc("pre",t,r);break;case"prerelease":0===this.prerelease.length&&this.inc("patch",t,r),this.inc("pre",t,r);break;case"major":0===this.minor&&0===this.patch&&0!==this.prerelease.length||this.major++,this.minor=0,this.patch=0,this.prerelease=[];break;case"minor":0===this.patch&&0!==this.prerelease.length||this.minor++,this.patch=0,this.prerelease=[];break;case"patch":0===this.prerelease.length&&this.patch++,this.prerelease=[];break;case"pre":{const e=Number(r)?1:0;if(!t&&!1===r)throw new Error("invalid increment argument: identifier is empty");if(0===this.prerelease.length)this.prerelease=[e];else{let n=this.prerelease.length;for(;--n>=0;)"number"==typeof this.prerelease[n]&&(this.prerelease[n]++,n=-2);if(-1===n){if(t===this.prerelease.join(".")&&!1===r)throw new Error("invalid increment argument: identifier already exists");this.prerelease.push(e)}}if(t){let n=[t,e];!1===r&&(n=[t]),0===l(this.prerelease[0],t)?isNaN(this.prerelease[1])&&(this.prerelease=n):this.prerelease=n}break}default:throw new Error(`invalid increment argument: ${e}`)}return this.raw=this.format(),this.build.length&&(this.raw+=`+${this.build.join(".")}`),this}}e.exports=c},90296:(e,t,r)=>{const n=r(95208);e.exports=(e,t)=>new n(e,t).major},17744:(e,t,r)=>{const n=r(95208);e.exports=(e,t,r=!1)=>{if(e instanceof n)return e;try{return new n(e,t)}catch(e){if(!r)return null;throw e}}},73424:(e,t,r)=>{const n=r(17744);e.exports=(e,t)=>{const r=n(e,t);return r?r.version:null}},50908:e=>{const t=Number.MAX_SAFE_INTEGER||9007199254740991;e.exports={MAX_LENGTH:256,MAX_SAFE_COMPONENT_LENGTH:16,MAX_SAFE_BUILD_LENGTH:250,MAX_SAFE_INTEGER:t,RELEASE_TYPES:["major","premajor","minor","preminor","patch","prepatch","prerelease"],SEMVER_SPEC_VERSION:"2.0.0",FLAG_INCLUDE_PRERELEASE:1,FLAG_LOOSE:2}},49324:(e,t,r)=>{var n=r(26512);const o="object"==typeof n&&n.env&&n.env.NODE_DEBUG&&/\bsemver\b/i.test(n.env.NODE_DEBUG)?(...e)=>console.error("SEMVER",...e):()=>{};e.exports=o},94113:e=>{const t=/^[0-9]+$/,r=(e,r)=>{const n=t.test(e),o=t.test(r);return n&&o&&(e=+e,r=+r),e===r?0:n&&!o?-1:o&&!n?1:e<r?-1:1};e.exports={compareIdentifiers:r,rcompareIdentifiers:(e,t)=>r(t,e)}},53632:e=>{const t=Object.freeze({loose:!0}),r=Object.freeze({});e.exports=e=>e?"object"!=typeof e?t:e:r},99692:(e,t,r)=>{const{MAX_SAFE_COMPONENT_LENGTH:n,MAX_SAFE_BUILD_LENGTH:o,MAX_LENGTH:s}=r(50908),i=r(49324),d=(t=e.exports={}).re=[],a=t.safeRe=[],l=t.src=[],c=t.t={};let u=0;const _="[a-zA-Z0-9-]",E=[["\\s",1],["\\d",s],[_,o]],h=(e,t,r)=>{const n=(e=>{for(const[t,r]of E)e=e.split(`${t}*`).join(`${t}{0,${r}}`).split(`${t}+`).join(`${t}{1,${r}}`);return e})(t),o=u++;i(e,o,t),c[e]=o,l[o]=t,d[o]=new RegExp(t,r?"g":void 0),a[o]=new RegExp(n,r?"g":void 0)};h("NUMERICIDENTIFIER","0|[1-9]\\d*"),h("NUMERICIDENTIFIERLOOSE","\\d+"),h("NONNUMERICIDENTIFIER",`\\d*[a-zA-Z-]${_}*`),h("MAINVERSION",`(${l[c.NUMERICIDENTIFIER]})\\.(${l[c.NUMERICIDENTIFIER]})\\.(${l[c.NUMERICIDENTIFIER]})`),h("MAINVERSIONLOOSE",`(${l[c.NUMERICIDENTIFIERLOOSE]})\\.(${l[c.NUMERICIDENTIFIERLOOSE]})\\.(${l[c.NUMERICIDENTIFIERLOOSE]})`),h("PRERELEASEIDENTIFIER",`(?:${l[c.NUMERICIDENTIFIER]}|${l[c.NONNUMERICIDENTIFIER]})`),h("PRERELEASEIDENTIFIERLOOSE",`(?:${l[c.NUMERICIDENTIFIERLOOSE]}|${l[c.NONNUMERICIDENTIFIER]})`),h("PRERELEASE",`(?:-(${l[c.PRERELEASEIDENTIFIER]}(?:\\.${l[c.PRERELEASEIDENTIFIER]})*))`),h("PRERELEASELOOSE",`(?:-?(${l[c.PRERELEASEIDENTIFIERLOOSE]}(?:\\.${l[c.PRERELEASEIDENTIFIERLOOSE]})*))`),h("BUILDIDENTIFIER",`${_}+`),h("BUILD",`(?:\\+(${l[c.BUILDIDENTIFIER]}(?:\\.${l[c.BUILDIDENTIFIER]})*))`),h("FULLPLAIN",`v?${l[c.MAINVERSION]}${l[c.PRERELEASE]}?${l[c.BUILD]}?`),h("FULL",`^${l[c.FULLPLAIN]}$`),h("LOOSEPLAIN",`[v=\\s]*${l[c.MAINVERSIONLOOSE]}${l[c.PRERELEASELOOSE]}?${l[c.BUILD]}?`),h("LOOSE",`^${l[c.LOOSEPLAIN]}$`),h("GTLT","((?:<|>)?=?)"),h("XRANGEIDENTIFIERLOOSE",`${l[c.NUMERICIDENTIFIERLOOSE]}|x|X|\\*`),h("XRANGEIDENTIFIER",`${l[c.NUMERICIDENTIFIER]}|x|X|\\*`),h("XRANGEPLAIN",`[v=\\s]*(${l[c.XRANGEIDENTIFIER]})(?:\\.(${l[c.XRANGEIDENTIFIER]})(?:\\.(${l[c.XRANGEIDENTIFIER]})(?:${l[c.PRERELEASE]})?${l[c.BUILD]}?)?)?`),h("XRANGEPLAINLOOSE",`[v=\\s]*(${l[c.XRANGEIDENTIFIERLOOSE]})(?:\\.(${l[c.XRANGEIDENTIFIERLOOSE]})(?:\\.(${l[c.XRANGEIDENTIFIERLOOSE]})(?:${l[c.PRERELEASELOOSE]})?${l[c.BUILD]}?)?)?`),h("XRANGE",`^${l[c.GTLT]}\\s*${l[c.XRANGEPLAIN]}$`),h("XRANGELOOSE",`^${l[c.GTLT]}\\s*${l[c.XRANGEPLAINLOOSE]}$`),h("COERCEPLAIN",`(^|[^\\d])(\\d{1,${n}})(?:\\.(\\d{1,${n}}))?(?:\\.(\\d{1,${n}}))?`),h("COERCE",`${l[c.COERCEPLAIN]}(?:$|[^\\d])`),h("COERCEFULL",l[c.COERCEPLAIN]+`(?:${l[c.PRERELEASE]})?`+`(?:${l[c.BUILD]})?(?:$|[^\\d])`),h("COERCERTL",l[c.COERCE],!0),h("COERCERTLFULL",l[c.COERCEFULL],!0),h("LONETILDE","(?:~>?)"),h("TILDETRIM",`(\\s*)${l[c.LONETILDE]}\\s+`,!0),t.tildeTrimReplace="$1~",h("TILDE",`^${l[c.LONETILDE]}${l[c.XRANGEPLAIN]}$`),h("TILDELOOSE",`^${l[c.LONETILDE]}${l[c.XRANGEPLAINLOOSE]}$`),h("LONECARET","(?:\\^)"),h("CARETTRIM",`(\\s*)${l[c.LONECARET]}\\s+`,!0),t.caretTrimReplace="$1^",h("CARET",`^${l[c.LONECARET]}${l[c.XRANGEPLAIN]}$`),h("CARETLOOSE",`^${l[c.LONECARET]}${l[c.XRANGEPLAINLOOSE]}$`),h("COMPARATORLOOSE",`^${l[c.GTLT]}\\s*(${l[c.LOOSEPLAIN]})$|^$`),h("COMPARATOR",`^${l[c.GTLT]}\\s*(${l[c.FULLPLAIN]})$|^$`),h("COMPARATORTRIM",`(\\s*)${l[c.GTLT]}\\s*(${l[c.LOOSEPLAIN]}|${l[c.XRANGEPLAIN]})`,!0),t.comparatorTrimReplace="$1$2$3",h("HYPHENRANGE",`^\\s*(${l[c.XRANGEPLAIN]})\\s+-\\s+(${l[c.XRANGEPLAIN]})\\s*$`),h("HYPHENRANGELOOSE",`^\\s*(${l[c.XRANGEPLAINLOOSE]})\\s+-\\s+(${l[c.XRANGEPLAINLOOSE]})\\s*$`),h("STAR","(<|>)?=?\\s*\\*"),h("GTE0","^\\s*>=\\s*0\\.0\\.0\\s*$"),h("GTE0PRE","^\\s*>=\\s*0\\.0\\.0-0\\s*$")},26512:e=>{var t,r,n=e.exports={};function o(){throw new Error("setTimeout has not been defined")}function s(){throw new Error("clearTimeout has not been defined")}function i(e){if(t===setTimeout)return setTimeout(e,0);if((t===o||!t)&&setTimeout)return t=setTimeout,setTimeout(e,0);try{return t(e,0)}catch(r){try{return t.call(null,e,0)}catch(r){return t.call(this,e,0)}}}!function(){try{t="function"==typeof setTimeout?setTimeout:o}catch(e){t=o}try{r="function"==typeof clearTimeout?clearTimeout:s}catch(e){r=s}}();var d,a=[],l=!1,c=-1;function u(){l&&d&&(l=!1,d.length?a=d.concat(a):c=-1,a.length&&_())}function _(){if(!l){var e=i(u);l=!0;for(var t=a.length;t;){for(d=a,a=[];++c<t;)d&&d[c].run();c=-1,t=a.length}d=null,l=!1,function(e){if(r===clearTimeout)return clearTimeout(e);if((r===s||!r)&&clearTimeout)return r=clearTimeout,clearTimeout(e);try{return r(e)}catch(t){try{return r.call(null,e)}catch(t){return r.call(this,e)}}}(e)}}function E(e,t){this.fun=e,this.array=t}function h(){}n.nextTick=function(e){var t=new Array(arguments.length-1);if(arguments.length>1)for(var r=1;r<arguments.length;r++)t[r-1]=arguments[r];a.push(new E(e,t)),1!==a.length||l||i(_)},E.prototype.run=function(){this.fun.apply(null,this.array)},n.title="browser",n.browser=!0,n.env={},n.argv=[],n.version="",n.versions={},n.on=h,n.addListener=h,n.once=h,n.off=h,n.removeListener=h,n.removeAllListeners=h,n.emit=h,n.prependListener=h,n.prependOnceListener=h,n.listeners=function(e){return[]},n.binding=function(e){throw new Error("process.binding is not supported")},n.cwd=function(){return"/"},n.chdir=function(e){throw new Error("process.chdir is not supported")},n.umask=function(){return 0}},38580:(e,t,r)=>{"use strict";r.d(t,{SI:()=>i,Ww:()=>d,eo:()=>c});var n=r(18444);let o;const s=[];function i(){if(void 0===o){const e=document?.getElementsByTagName("head")[0];o=e?e.getAttribute("data-requesttoken"):null}return o}function d(e){s.push(e)}(0,n.Cc)("csrf-token-update",(e=>{o=e.token,s.forEach((t=>{try{t(e.token)}catch(e){console.error("error updating CSRF token observer",e)}}))}));const a=(e,t)=>e?e.getAttribute(t):null;let l;function c(){if(void 0!==l)return l;const e=document?.getElementsByTagName("head")[0];if(!e)return null;const t=a(e,"data-user");return null===t?(l=null,l):(l={uid:t,displayName:a(e,"data-user-displayname"),isAdmin:!!window._oc_isadmin},l)}},18444:(e,t,r)=>{"use strict";r.d(t,{Cc:()=>l,Ix:()=>u,K2:()=>c});var n=r(73424),o=r(90296);class s{bus;constructor(e){"function"==typeof e.getVersion&&n(e.getVersion())?o(e.getVersion())!==o(this.getVersion())&&console.warn("Proxying an event bus of version "+e.getVersion()+" with "+this.getVersion()):console.warn("Proxying an event bus with an unknown or invalid version"),this.bus=e}getVersion(){return"3.1.0"}subscribe(e,t){this.bus.subscribe(e,t)}unsubscribe(e,t){this.bus.unsubscribe(e,t)}emit(e,t){this.bus.emit(e,t)}}class i{handlers=new Map;getVersion(){return"3.1.0"}subscribe(e,t){this.handlers.set(e,(this.handlers.get(e)||[]).concat(t))}unsubscribe(e,t){this.handlers.set(e,(this.handlers.get(e)||[]).filter((e=>e!=t)))}emit(e,t){(this.handlers.get(e)||[]).forEach((e=>{try{e(t)}catch(e){console.error("could not invoke event listener",e)}}))}}let d=null;function a(){return null!==d?d:"undefined"==typeof window?new Proxy({},{get:()=>()=>console.error("Window not available, EventBus can not be established!")}):(void 0!==window.OC&&window.OC._eventBus&&void 0===window._nc_event_bus&&(console.warn("found old event bus instance at OC._eventBus. Update your version!"),window._nc_event_bus=window.OC._eventBus),d=void 0!==window?._nc_event_bus?new s(window._nc_event_bus):window._nc_event_bus=new i,d)}function l(e,t){a().subscribe(e,t)}function c(e,t){a().unsubscribe(e,t)}function u(e,t){a().emit(e,t)}},78296:(e,t,r)=>{"use strict";r.d(t,{AF:()=>d,QP:()=>s,U$:()=>c,gJ:()=>l,gz:()=>n,o0:()=>o,o1:()=>a});const n=(e,t)=>l(e,"",t),o=(e,t)=>{var r;return(null!=(r=null==t?void 0:t.baseURL)?r:c())+(e=>"/remote.php/"+e)(e)},s=(e,t,r)=>{var n;const o=1===Object.assign({ocsVersion:2},r||{}).ocsVersion?1:2;return(null!=(n=null==r?void 0:r.baseURL)?n:c())+"/ocs/v"+o+".php"+i(e,t,r)},i=(e,t,r)=>{const n=Object.assign({escape:!0},r||{});return"/"!==e.charAt(0)&&(e="/"+e),o=(o=t||{})||{},e.replace(/{([^{}]*)}/g,(function(e,t){const r=o[t];return n.escape?encodeURIComponent("string"==typeof r||"number"==typeof r?r.toString():e):"string"==typeof r||"number"==typeof r?r.toString():e}));var o},d=(e,t,r)=>{var n,o,s;const d=Object.assign({noRewrite:!1},r||{}),a=null!=(n=null==r?void 0:r.baseURL)?n:u();return!0!==(null==(s=null==(o=null==window?void 0:window.OC)?void 0:o.config)?void 0:s.modRewriteWorking)||d.noRewrite?a+"/index.php"+i(e,t,r):a+i(e,t,r)},a=(e,t)=>-1===t.indexOf(".")?l(e,"img",t+".svg"):l(e,"img",t),l=(e,t,r)=>{var n,o,s;const i=null!=(s=null==(o=null==(n=null==window?void 0:window.OC)?void 0:n.coreApps)?void 0:o.includes(e))&&s,d="php"===r.slice(-3);let a=u();return d&&!i?(a+="/index.php/apps/".concat(e),t&&(a+="/".concat(encodeURI(t))),"index.php"!==r&&(a+="/".concat(r))):d||i?(("settings"===e||"core"===e||"search"===e)&&"ajax"===t&&(a+="/index.php"),e&&(a+="/".concat(e)),t&&(a+="/".concat(t)),a+="/".concat(r)):(a=function(e){var t,r;return null!=(r=(null!=(t=window._oc_appswebroots)?t:{})[e])?r:""}(e),t&&(a+="/".concat(t,"/")),"/"!==a.at(-1)&&(a+="/"),a+=r),a},c=()=>window.location.protocol+"//"+window.location.host+u();function u(){let e=window._oc_webroot;if(typeof e>"u"){e=location.pathname;const t=e.indexOf("/index.php/");if(-1!==t)e=e.slice(0,t);else{const t=e.indexOf("/",1);e=e.slice(0,t>0?t:void 0)}}return e}}},s={};function i(e){var t=s[e];if(void 0!==t)return t.exports;var r=s[e]={id:e,loaded:!1,exports:{}};return o[e].call(r.exports,r,r.exports,i),r.loaded=!0,r.exports}i.m=o,i.amdD=function(){throw new Error("define cannot be used indirect")},i.amdO={},i.n=e=>{var t=e&&e.__esModule?()=>e.default:()=>e;return i.d(t,{a:t}),t},t=Object.getPrototypeOf?e=>Object.getPrototypeOf(e):e=>e.__proto__,i.t=function(r,n){if(1&n&&(r=this(r)),8&n)return r;if("object"==typeof r&&r){if(4&n&&r.__esModule)return r;if(16&n&&"function"==typeof r.then)return r}var o=Object.create(null);i.r(o);var s={};e=e||[null,t({}),t([]),t(t)];for(var d=2&n&&r;"object"==typeof d&&!~e.indexOf(d);d=t(d))Object.getOwnPropertyNames(d).forEach((e=>s[e]=()=>r[e]));return s.default=()=>r,i.d(o,s),o},i.d=(e,t)=>{for(var r in t)i.o(t,r)&&!i.o(e,r)&&Object.defineProperty(e,r,{enumerable:!0,get:t[r]})},i.f={},i.e=e=>Promise.all(Object.keys(i.f).reduce(((t,r)=>(i.f[r](e,t),t)),[])),i.u=e=>"calendar-"+e+".js?v="+{"vendors-node_modules_nextcloud_capabilities_dist_index_js-node_modules_nextcloud_vue-select_d-732246":"6caeb7154861390f56c2","vendors-node_modules_nextcloud_cdav-library_dist_dist_js-node_modules_nextcloud_logger_dist_i-e05aee":"6fb31759e260ef25bf12","vendors-node_modules_webdav_dist_web_index_js":"4eb954c840bec79f9883","vendors-node_modules_vue-material-design-icons_CalendarBlankOutline_vue-node_modules_nextclou-05d07d":"3e2bdc6dbbfb5db7cf0f","vendors-node_modules_nextcloud_vue-dashboard_dist_vue-dashboard_js-node_modules_css-loader_di-97ac2a":"767abffd20c7226223cb","src_models_rfcProps_js-src_services_timezoneDataProviderService_js-src_services_timezoneDetec-33af66":"02c5393d39f3a890b5b7",src_store_index_js:"4988033f8a438bf8d345","dashboard-lazy":"ed5c8610d19e982764e9","vendors-node_modules_linkifyjs_dist_linkify_es_js-node_modules_vue-material-design-icons_Cale-9f7b09":"16672b23384a1820edc8","vendors-node_modules_vue-material-design-icons_CalendarBlank_vue-node_modules_vue-material-de-e2c1f8":"7dfb731e8bef4b707091","vendors-node_modules_path-browserify_index_js-node_modules_nextcloud_dialogs_dist_chunks_Dial-e0595f":"bc92fc5480106e01efb2",node_modules_nextcloud_dialogs_dist_legacy_mjs:"e33a6e762e59d81fb5fa","vendors-node_modules_nextcloud_dialogs_dist_chunks_FilePicker-8ibBgPg__mjs":"301c544d1ca03e7bf0ae","vendors-node_modules_moment_locale_af_js-node_modules_moment_locale_ar-dz_js-node_modules_mom-582c96":"3db23d04f5680d395467",node_modules_moment_locale_sync_recursive_:"dd37718fd5a48c6df57f"}[e],i.g=function(){if("object"==typeof globalThis)return globalThis;try{return this||new Function("return this")()}catch(e){if("object"==typeof window)return window}}(),i.o=(e,t)=>Object.prototype.hasOwnProperty.call(e,t),r={},n="calendar:",i.l=(e,t,o,s)=>{if(r[e])r[e].push(t);else{var d,a;if(void 0!==o)for(var l=document.getElementsByTagName("script"),c=0;c<l.length;c++){var u=l[c];if(u.getAttribute("src")==e||u.getAttribute("data-webpack")==n+o){d=u;break}}d||(a=!0,(d=document.createElement("script")).charset="utf-8",d.timeout=120,i.nc&&d.setAttribute("nonce",i.nc),d.setAttribute("data-webpack",n+o),d.src=e),r[e]=[t];var _=(t,n)=>{d.onerror=d.onload=null,clearTimeout(E);var o=r[e];if(delete r[e],d.parentNode&&d.parentNode.removeChild(d),o&&o.forEach((e=>e(n))),t)return t(n)},E=setTimeout(_.bind(null,void 0,{type:"timeout",target:d}),12e4);d.onerror=_.bind(null,d.onerror),d.onload=_.bind(null,d.onload),a&&document.head.appendChild(d)}},i.r=e=>{"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(e,"__esModule",{value:!0})},i.nmd=e=>(e.paths=[],e.children||(e.children=[]),e),i.p="/apps/calendar/js/",(()=>{i.b=document.baseURI||self.location.href;var e={dashboard:0};i.f.j=(t,r)=>{var n=i.o(e,t)?e[t]:void 0;if(0!==n)if(n)r.push(n[2]);else{var o=new Promise(((r,o)=>n=e[t]=[r,o]));r.push(n[2]=o);var s=i.p+i.u(t),d=new Error;i.l(s,(r=>{if(i.o(e,t)&&(0!==(n=e[t])&&(e[t]=void 0),n)){var o=r&&("load"===r.type?"missing":r.type),s=r&&r.target&&r.target.src;d.message="Loading chunk "+t+" failed.\n("+o+": "+s+")",d.name="ChunkLoadError",d.type=o,d.request=s,n[1](d)}}),"chunk-"+t,t)}};var t=(t,r)=>{var n,o,[s,d,a]=r,l=0;if(s.some((t=>0!==e[t]))){for(n in d)i.o(d,n)&&(i.m[n]=d[n]);if(a)a(i)}for(t&&t(r);l<s.length;l++)o=s[l],i.o(e,o)&&e[o]&&e[o][0](),e[o]=0},r=self.webpackChunkcalendar=self.webpackChunkcalendar||[];r.forEach(t.bind(null,0)),r.push=t.bind(null,r.push.bind(r))})(),i.nc=void 0,(()=>{"use strict";var e=i(78296),t=i(38580);i.nc=btoa((0,t.SI)()),i.p=(0,e.gJ)("calendar","","js/"),document.addEventListener("DOMContentLoaded",(function(){OCA.Dashboard.register("calendar",(async e=>{const{default:t}=await Promise.all([i.e("vendors-node_modules_nextcloud_capabilities_dist_index_js-node_modules_nextcloud_vue-select_d-732246"),i.e("vendors-node_modules_nextcloud_cdav-library_dist_dist_js-node_modules_nextcloud_logger_dist_i-e05aee"),i.e("vendors-node_modules_webdav_dist_web_index_js"),i.e("vendors-node_modules_vue-material-design-icons_CalendarBlankOutline_vue-node_modules_nextclou-05d07d"),i.e("vendors-node_modules_nextcloud_vue-dashboard_dist_vue-dashboard_js-node_modules_css-loader_di-97ac2a"),i.e("src_models_rfcProps_js-src_services_timezoneDataProviderService_js-src_services_timezoneDetec-33af66"),i.e("src_store_index_js"),i.e("dashboard-lazy")]).then(i.bind(i,7768)),{translate:r,translatePlural:n}=await Promise.all([i.e("vendors-node_modules_nextcloud_capabilities_dist_index_js-node_modules_nextcloud_vue-select_d-732246"),i.e("vendors-node_modules_nextcloud_cdav-library_dist_dist_js-node_modules_nextcloud_logger_dist_i-e05aee"),i.e("vendors-node_modules_webdav_dist_web_index_js"),i.e("vendors-node_modules_vue-material-design-icons_CalendarBlankOutline_vue-node_modules_nextclou-05d07d"),i.e("vendors-node_modules_nextcloud_vue-dashboard_dist_vue-dashboard_js-node_modules_css-loader_di-97ac2a"),i.e("src_models_rfcProps_js-src_services_timezoneDataProviderService_js-src_services_timezoneDetec-33af66"),i.e("src_store_index_js"),i.e("dashboard-lazy")]).then(i.bind(i,59620)),{default:o}=await Promise.all([i.e("vendors-node_modules_nextcloud_capabilities_dist_index_js-node_modules_nextcloud_vue-select_d-732246"),i.e("vendors-node_modules_nextcloud_cdav-library_dist_dist_js-node_modules_nextcloud_logger_dist_i-e05aee"),i.e("vendors-node_modules_webdav_dist_web_index_js"),i.e("vendors-node_modules_vue-material-design-icons_CalendarBlankOutline_vue-node_modules_nextclou-05d07d"),i.e("vendors-node_modules_nextcloud_vue-dashboard_dist_vue-dashboard_js-node_modules_css-loader_di-97ac2a"),i.e("src_models_rfcProps_js-src_services_timezoneDataProviderService_js-src_services_timezoneDetec-33af66"),i.e("src_store_index_js"),i.e("dashboard-lazy")]).then(i.bind(i,65860)),{default:s}=await Promise.all([i.e("vendors-node_modules_nextcloud_capabilities_dist_index_js-node_modules_nextcloud_vue-select_d-732246"),i.e("vendors-node_modules_nextcloud_cdav-library_dist_dist_js-node_modules_nextcloud_logger_dist_i-e05aee"),i.e("vendors-node_modules_webdav_dist_web_index_js"),i.e("vendors-node_modules_vue-material-design-icons_CalendarBlankOutline_vue-node_modules_nextclou-05d07d"),i.e("vendors-node_modules_nextcloud_vue-dashboard_dist_vue-dashboard_js-node_modules_css-loader_di-97ac2a"),i.e("src_models_rfcProps_js-src_services_timezoneDataProviderService_js-src_services_timezoneDetec-33af66"),i.e("src_store_index_js"),i.e("dashboard-lazy")]).then(i.bind(i,6752));t.prototype.t=r,t.prototype.n=n,t.prototype.OC=OC,t.prototype.OCA=OCA;new(t.extend(o))({store:s,propsData:{}}).$mount(e)}))}))})()})();
//# sourceMappingURL=calendar-dashboard.js.map?v=4ae0c19f852c631e786d