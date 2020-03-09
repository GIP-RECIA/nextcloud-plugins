/**
 * @copyright (c) 2016 Joas Schilling <coding@schilljs.com>
 *
 * @author Joas Schilling <coding@schilljs.com>
 *
 * This file is licensed under the Affero General Public License version 3 or
 * later. See the COPYING file.
 */

(function(OC, OCA) {
	OCA.Activity = OCA.Activity || {};

	OCA.Activity.RichObjectStringParser = {
		avatarsEnabled: true,

		/**
		 * @param {string} message
		 * @param {Object} parameters
		 * @returns {string}
		 */
		parseMessage: function(message, parameters) {
			message = escapeHTML(message);
			var self = this,
				regex = /\{([a-z\-_0-9]+)\}/gi,
				matches = message.match(regex);

			_.each(matches, function(parameter) {
				parameter = parameter.substring(1, parameter.length - 1);
				if (!parameters.hasOwnProperty(parameter) || !parameters[parameter]) {
					// Malformed translation?
					console.error('Potential malformed ROS string: parameter {' + parameter + '} was found in the string but is missing from the parameter list');
					return;
				}

				var parsed = self.parseParameter(parameters[parameter]);
				message = message.replace('{' + parameter + '}', parsed);
			});

			return message.replace(new RegExp("\n", 'g'), '<br>');
		},

		/**
		 * @param {Object} parameter
		 * @param {string} parameter.type
		 * @param {string} parameter.id
		 * @param {string} parameter.name
		 * @param {string} parameter.link
		 */
		parseParameter: function(parameter) {
			switch (parameter.type) {
				case 'file':
					return this.parseFileParameter(parameter).trim("\n");

				case 'systemtag':
					var name = parameter.name;
					if (parameter.visibility !== '1') {
						name = t('activity', '{name} (invisible)', parameter);
					} else if (parameter.assignable !== '1') {
						name = t('activity', '{name} (restricted)', parameter);
					}

					return OCA.Activity.Templates.systemTag({
						name: name
					}).trim("\n");

				case 'email':
					return OCA.Activity.Templates.email(parameter).trim("\n");

				case 'open-graph':
					return OCA.Activity.Templates.openGraph(parameter).trim("\n");

				case 'user':
					if (_.isUndefined(parameter.server)) {
						return OCA.Activity.Templates.userLocal(parameter).trim("\n");
					}

					return OCA.Activity.Templates.userRemote(parameter).trim("\n");

				default:
					if (!_.isUndefined(parameter.link)) {
						return OCA.Activity.Templates.unkownLink(parameter).trim("\n");
					}

					return OCA.Activity.Templates.unknown(parameter).trim("\n");
			}
		},

		/**
		 * @param {Object} parameter
		 * @param {string} parameter.type
		 * @param {string} parameter.id
		 * @param {string} parameter.name
		 * @param {string} parameter.path
		 * @param {string} parameter.link
		 */
		parseFileParameter: function(parameter) {
			if (parameter.path === '') {
				return OCA.Activity.Templates.fileRoot(_.extend(parameter, {
					homeTXT: t('activity', 'Home')
				}));
			}

			var lastSlashPosition = parameter.path.lastIndexOf('/'),
				firstSlashPosition = parameter.path.indexOf('/');
			parameter.path = parameter.path.substring(firstSlashPosition === 0 ? 1 : 0, lastSlashPosition);

			if (!parameter.link) {
				parameter.link = OC.generateUrl('/f/{fileId}', {fileId: parameter.id});
			}

			if (parameter.path === '' || parameter.path === '/') {
				return OCA.Activity.Templates.fileNoPath(parameter);
			}
			return OCA.Activity.Templates.file(_.extend(parameter, {
				title: parameter.path.length === 0 ? '' : t('activity', 'in {path}', parameter)
			}));
		}
	};

})(OC, OCA);


(function() {
  var template = Handlebars.template, templates = OCA.Activity.Templates = OCA.Activity.Templates || {};
templates['activitytabview'] = template({"compiler":[8,">= 4.3.0"],"main":function(container,depth0,helpers,partials,data) {
    var helper, alias1=depth0 != null ? depth0 : (container.nullContext || {}), alias2=container.hooks.helperMissing, alias3="function", alias4=container.escapeExpression, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "<div class=\"activity-section\">\n	<div class=\"loading hidden\" style=\"height: 50px\"></div>\n	<div class=\"emptycontent\">\n		<div class=\"icon-activity\"></div>\n		<p>"
    + alias4(((helper = (helper = lookupProperty(helpers,"emptyMessage") || (depth0 != null ? lookupProperty(depth0,"emptyMessage") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"emptyMessage","hash":{},"data":data,"loc":{"start":{"line":5,"column":5},"end":{"line":5,"column":21}}}) : helper)))
    + "</p>\n	</div>\n	<ul class=\"activities hidden\">\n	</ul>\n	<input type=\"button\" class=\"showMore\" value=\""
    + alias4(((helper = (helper = lookupProperty(helpers,"moreLabel") || (depth0 != null ? lookupProperty(depth0,"moreLabel") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"moreLabel","hash":{},"data":data,"loc":{"start":{"line":9,"column":46},"end":{"line":9,"column":59}}}) : helper)))
    + "\">\n</div>\n";
},"useData":true});
templates['activitytabview_activity'] = template({"1":function(container,depth0,helpers,partials,data) {
    return " monochrome";
},"3":function(container,depth0,helpers,partials,data) {
    var helper, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "			<img src=\""
    + container.escapeExpression(((helper = (helper = lookupProperty(helpers,"icon") || (depth0 != null ? lookupProperty(depth0,"icon") : depth0)) != null ? helper : container.hooks.helperMissing),(typeof helper === "function" ? helper.call(depth0 != null ? depth0 : (container.nullContext || {}),{"name":"icon","hash":{},"data":data,"loc":{"start":{"line":4,"column":13},"end":{"line":4,"column":21}}}) : helper)))
    + "\" alt=\"\">\n";
},"compiler":[8,">= 4.3.0"],"main":function(container,depth0,helpers,partials,data) {
    var stack1, helper, alias1=depth0 != null ? depth0 : (container.nullContext || {}), alias2=container.hooks.helperMissing, alias3="function", alias4=container.escapeExpression, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "<li class=\"activity box\">\n	<div class=\"activity-icon"
    + ((stack1 = lookupProperty(helpers,"if").call(alias1,(depth0 != null ? lookupProperty(depth0,"isMonochromeIcon") : depth0),{"name":"if","hash":{},"fn":container.program(1, data, 0),"inverse":container.noop,"data":data,"loc":{"start":{"line":2,"column":26},"end":{"line":2,"column":68}}})) != null ? stack1 : "")
    + "\">\n"
    + ((stack1 = lookupProperty(helpers,"if").call(alias1,(depth0 != null ? lookupProperty(depth0,"icon") : depth0),{"name":"if","hash":{},"fn":container.program(3, data, 0),"inverse":container.noop,"data":data,"loc":{"start":{"line":3,"column":2},"end":{"line":5,"column":9}}})) != null ? stack1 : "")
    + "	</div>\n	<div class=\"activitysubject\">"
    + ((stack1 = ((helper = (helper = lookupProperty(helpers,"subject") || (depth0 != null ? lookupProperty(depth0,"subject") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"subject","hash":{},"data":data,"loc":{"start":{"line":7,"column":30},"end":{"line":7,"column":43}}}) : helper))) != null ? stack1 : "")
    + "</div>\n	<span class=\"activitytime has-tooltip live-relative-timestamp\" data-timestamp=\""
    + alias4(((helper = (helper = lookupProperty(helpers,"timestamp") || (depth0 != null ? lookupProperty(depth0,"timestamp") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"timestamp","hash":{},"data":data,"loc":{"start":{"line":8,"column":80},"end":{"line":8,"column":93}}}) : helper)))
    + "\" title=\""
    + alias4(((helper = (helper = lookupProperty(helpers,"formattedDateTooltip") || (depth0 != null ? lookupProperty(depth0,"formattedDateTooltip") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"formattedDateTooltip","hash":{},"data":data,"loc":{"start":{"line":8,"column":102},"end":{"line":8,"column":126}}}) : helper)))
    + "\">"
    + alias4(((helper = (helper = lookupProperty(helpers,"formattedDate") || (depth0 != null ? lookupProperty(depth0,"formattedDate") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"formattedDate","hash":{},"data":data,"loc":{"start":{"line":8,"column":128},"end":{"line":8,"column":145}}}) : helper)))
    + "</span>\n	<div class=\"activitymessage\">"
    + ((stack1 = ((helper = (helper = lookupProperty(helpers,"message") || (depth0 != null ? lookupProperty(depth0,"message") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"message","hash":{},"data":data,"loc":{"start":{"line":9,"column":30},"end":{"line":9,"column":43}}}) : helper))) != null ? stack1 : "")
    + "</div>\n</li>\n";
},"useData":true});
templates['email'] = template({"compiler":[8,">= 4.3.0"],"main":function(container,depth0,helpers,partials,data) {
    var helper, alias1=depth0 != null ? depth0 : (container.nullContext || {}), alias2=container.hooks.helperMissing, alias3="function", alias4=container.escapeExpression, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "<a class=\"email\" href=\"mailto:"
    + alias4(((helper = (helper = lookupProperty(helpers,"id") || (depth0 != null ? lookupProperty(depth0,"id") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"id","hash":{},"data":data,"loc":{"start":{"line":1,"column":30},"end":{"line":1,"column":36}}}) : helper)))
    + "\">"
    + alias4(((helper = (helper = lookupProperty(helpers,"name") || (depth0 != null ? lookupProperty(depth0,"name") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"name","hash":{},"data":data,"loc":{"start":{"line":1,"column":38},"end":{"line":1,"column":46}}}) : helper)))
    + "</a>\n";
},"useData":true});
templates['file'] = template({"compiler":[8,">= 4.3.0"],"main":function(container,depth0,helpers,partials,data) {
    var helper, alias1=depth0 != null ? depth0 : (container.nullContext || {}), alias2=container.hooks.helperMissing, alias3="function", alias4=container.escapeExpression, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "<a class=\"filename has-tooltip\" href=\""
    + alias4(((helper = (helper = lookupProperty(helpers,"link") || (depth0 != null ? lookupProperty(depth0,"link") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"link","hash":{},"data":data,"loc":{"start":{"line":1,"column":38},"end":{"line":1,"column":46}}}) : helper)))
    + "\" title=\""
    + alias4(((helper = (helper = lookupProperty(helpers,"title") || (depth0 != null ? lookupProperty(depth0,"title") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"title","hash":{},"data":data,"loc":{"start":{"line":1,"column":55},"end":{"line":1,"column":64}}}) : helper)))
    + "\">"
    + alias4(((helper = (helper = lookupProperty(helpers,"name") || (depth0 != null ? lookupProperty(depth0,"name") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"name","hash":{},"data":data,"loc":{"start":{"line":1,"column":66},"end":{"line":1,"column":74}}}) : helper)))
    + "</a>\n";
},"useData":true});
templates['fileNoPath'] = template({"compiler":[8,">= 4.3.0"],"main":function(container,depth0,helpers,partials,data) {
    var helper, alias1=depth0 != null ? depth0 : (container.nullContext || {}), alias2=container.hooks.helperMissing, alias3="function", alias4=container.escapeExpression, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "<a class=\"filename\" href=\""
    + alias4(((helper = (helper = lookupProperty(helpers,"link") || (depth0 != null ? lookupProperty(depth0,"link") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"link","hash":{},"data":data,"loc":{"start":{"line":1,"column":26},"end":{"line":1,"column":34}}}) : helper)))
    + "\">"
    + alias4(((helper = (helper = lookupProperty(helpers,"name") || (depth0 != null ? lookupProperty(depth0,"name") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"name","hash":{},"data":data,"loc":{"start":{"line":1,"column":36},"end":{"line":1,"column":44}}}) : helper)))
    + "</a>\n";
},"useData":true});
templates['fileRoot'] = template({"compiler":[8,">= 4.3.0"],"main":function(container,depth0,helpers,partials,data) {
    var helper, alias1=depth0 != null ? depth0 : (container.nullContext || {}), alias2=container.hooks.helperMissing, alias3="function", alias4=container.escapeExpression, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "<a class=\"filename has-tooltip\" href=\""
    + alias4(((helper = (helper = lookupProperty(helpers,"link") || (depth0 != null ? lookupProperty(depth0,"link") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"link","hash":{},"data":data,"loc":{"start":{"line":1,"column":38},"end":{"line":1,"column":46}}}) : helper)))
    + "\" title=\""
    + alias4(((helper = (helper = lookupProperty(helpers,"homeTXT") || (depth0 != null ? lookupProperty(depth0,"homeTXT") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"homeTXT","hash":{},"data":data,"loc":{"start":{"line":1,"column":55},"end":{"line":1,"column":66}}}) : helper)))
    + "\"><span class=\"icon icon-home\"></span></a>\n";
},"useData":true});
templates['openGraph'] = template({"1":function(container,depth0,helpers,partials,data) {
    var helper, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "	<a href=\""
    + container.escapeExpression(((helper = (helper = lookupProperty(helpers,"link") || (depth0 != null ? lookupProperty(depth0,"link") : depth0)) != null ? helper : container.hooks.helperMissing),(typeof helper === "function" ? helper.call(depth0 != null ? depth0 : (container.nullContext || {}),{"name":"link","hash":{},"data":data,"loc":{"start":{"line":2,"column":10},"end":{"line":2,"column":18}}}) : helper)))
    + "\">\n";
},"3":function(container,depth0,helpers,partials,data) {
    var helper, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "			<div class=\"opengraph-thumb\" style=\"background-image: url('"
    + container.escapeExpression(((helper = (helper = lookupProperty(helpers,"thumb") || (depth0 != null ? lookupProperty(depth0,"thumb") : depth0)) != null ? helper : container.hooks.helperMissing),(typeof helper === "function" ? helper.call(depth0 != null ? depth0 : (container.nullContext || {}),{"name":"thumb","hash":{},"data":data,"loc":{"start":{"line":6,"column":62},"end":{"line":6,"column":71}}}) : helper)))
    + "')\"></div>\n";
},"5":function(container,depth0,helpers,partials,data) {
    return "opengraph-with-thumb";
},"7":function(container,depth0,helpers,partials,data) {
    return "	</a>\n";
},"compiler":[8,">= 4.3.0"],"main":function(container,depth0,helpers,partials,data) {
    var stack1, helper, alias1=depth0 != null ? depth0 : (container.nullContext || {}), alias2=container.hooks.helperMissing, alias3="function", alias4=container.escapeExpression, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return ((stack1 = lookupProperty(helpers,"if").call(alias1,(depth0 != null ? lookupProperty(depth0,"link") : depth0),{"name":"if","hash":{},"fn":container.program(1, data, 0),"inverse":container.noop,"data":data,"loc":{"start":{"line":1,"column":0},"end":{"line":3,"column":7}}})) != null ? stack1 : "")
    + "	<div id=\"opengraph-"
    + alias4(((helper = (helper = lookupProperty(helpers,"id") || (depth0 != null ? lookupProperty(depth0,"id") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"id","hash":{},"data":data,"loc":{"start":{"line":4,"column":20},"end":{"line":4,"column":26}}}) : helper)))
    + "\" class=\"opengraph\">\n"
    + ((stack1 = lookupProperty(helpers,"if").call(alias1,(depth0 != null ? lookupProperty(depth0,"thumb") : depth0),{"name":"if","hash":{},"fn":container.program(3, data, 0),"inverse":container.noop,"data":data,"loc":{"start":{"line":5,"column":2},"end":{"line":7,"column":9}}})) != null ? stack1 : "")
    + "		<div class=\"opengraph-name "
    + ((stack1 = lookupProperty(helpers,"if").call(alias1,(depth0 != null ? lookupProperty(depth0,"thumb") : depth0),{"name":"if","hash":{},"fn":container.program(5, data, 0),"inverse":container.noop,"data":data,"loc":{"start":{"line":8,"column":29},"end":{"line":8,"column":69}}})) != null ? stack1 : "")
    + "\">"
    + alias4(((helper = (helper = lookupProperty(helpers,"name") || (depth0 != null ? lookupProperty(depth0,"name") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"name","hash":{},"data":data,"loc":{"start":{"line":8,"column":71},"end":{"line":8,"column":79}}}) : helper)))
    + "</div>\n		<div class=\"opengraph-description "
    + ((stack1 = lookupProperty(helpers,"if").call(alias1,(depth0 != null ? lookupProperty(depth0,"thumb") : depth0),{"name":"if","hash":{},"fn":container.program(5, data, 0),"inverse":container.noop,"data":data,"loc":{"start":{"line":9,"column":36},"end":{"line":9,"column":76}}})) != null ? stack1 : "")
    + "\">"
    + alias4(((helper = (helper = lookupProperty(helpers,"description") || (depth0 != null ? lookupProperty(depth0,"description") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"description","hash":{},"data":data,"loc":{"start":{"line":9,"column":78},"end":{"line":9,"column":93}}}) : helper)))
    + "</div>\n		<span class=\"opengraph-website\">"
    + alias4(((helper = (helper = lookupProperty(helpers,"website") || (depth0 != null ? lookupProperty(depth0,"website") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"website","hash":{},"data":data,"loc":{"start":{"line":10,"column":34},"end":{"line":10,"column":45}}}) : helper)))
    + "</span>\n	</div>\n"
    + ((stack1 = lookupProperty(helpers,"if").call(alias1,(depth0 != null ? lookupProperty(depth0,"link") : depth0),{"name":"if","hash":{},"fn":container.program(7, data, 0),"inverse":container.noop,"data":data,"loc":{"start":{"line":12,"column":0},"end":{"line":14,"column":7}}})) != null ? stack1 : "");
},"useData":true});
templates['systemTag'] = template({"compiler":[8,">= 4.3.0"],"main":function(container,depth0,helpers,partials,data) {
    var helper, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "<strong class=\"systemtag\">"
    + container.escapeExpression(((helper = (helper = lookupProperty(helpers,"name") || (depth0 != null ? lookupProperty(depth0,"name") : depth0)) != null ? helper : container.hooks.helperMissing),(typeof helper === "function" ? helper.call(depth0 != null ? depth0 : (container.nullContext || {}),{"name":"name","hash":{},"data":data,"loc":{"start":{"line":1,"column":26},"end":{"line":1,"column":34}}}) : helper)))
    + "</strong>\n";
},"useData":true});
templates['unknown'] = template({"compiler":[8,">= 4.3.0"],"main":function(container,depth0,helpers,partials,data) {
    var helper, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "<strong>"
    + container.escapeExpression(((helper = (helper = lookupProperty(helpers,"name") || (depth0 != null ? lookupProperty(depth0,"name") : depth0)) != null ? helper : container.hooks.helperMissing),(typeof helper === "function" ? helper.call(depth0 != null ? depth0 : (container.nullContext || {}),{"name":"name","hash":{},"data":data,"loc":{"start":{"line":1,"column":8},"end":{"line":1,"column":16}}}) : helper)))
    + "</strong>\n";
},"useData":true});
templates['unkownLink'] = template({"compiler":[8,">= 4.3.0"],"main":function(container,depth0,helpers,partials,data) {
    var helper, alias1=depth0 != null ? depth0 : (container.nullContext || {}), alias2=container.hooks.helperMissing, alias3="function", alias4=container.escapeExpression, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "<a href=\""
    + alias4(((helper = (helper = lookupProperty(helpers,"link") || (depth0 != null ? lookupProperty(depth0,"link") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"link","hash":{},"data":data,"loc":{"start":{"line":1,"column":9},"end":{"line":1,"column":17}}}) : helper)))
    + "\">"
    + alias4(((helper = (helper = lookupProperty(helpers,"name") || (depth0 != null ? lookupProperty(depth0,"name") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"name","hash":{},"data":data,"loc":{"start":{"line":1,"column":19},"end":{"line":1,"column":27}}}) : helper)))
    + "</a>\n";
},"useData":true});
templates['userLocal'] = template({"compiler":[8,">= 4.3.0"],"main":function(container,depth0,helpers,partials,data) {
    var helper, alias1=depth0 != null ? depth0 : (container.nullContext || {}), alias2=container.hooks.helperMissing, alias3="function", alias4=container.escapeExpression, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "<span class=\"avatar-name-wrapper\" data-user=\""
    + alias4(((helper = (helper = lookupProperty(helpers,"id") || (depth0 != null ? lookupProperty(depth0,"id") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"id","hash":{},"data":data,"loc":{"start":{"line":1,"column":45},"end":{"line":1,"column":51}}}) : helper)))
    + "\"><div class=\"avatar\" data-user=\""
    + alias4(((helper = (helper = lookupProperty(helpers,"id") || (depth0 != null ? lookupProperty(depth0,"id") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"id","hash":{},"data":data,"loc":{"start":{"line":1,"column":84},"end":{"line":1,"column":90}}}) : helper)))
    + "\" data-user-display-name=\""
    + alias4(((helper = (helper = lookupProperty(helpers,"name") || (depth0 != null ? lookupProperty(depth0,"name") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"name","hash":{},"data":data,"loc":{"start":{"line":1,"column":116},"end":{"line":1,"column":124}}}) : helper)))
    + "\"></div><strong>"
    + alias4(((helper = (helper = lookupProperty(helpers,"name") || (depth0 != null ? lookupProperty(depth0,"name") : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"name","hash":{},"data":data,"loc":{"start":{"line":1,"column":140},"end":{"line":1,"column":148}}}) : helper)))
    + "</strong></span>\n";
},"useData":true});
templates['userRemote'] = template({"compiler":[8,">= 4.3.0"],"main":function(container,depth0,helpers,partials,data) {
    var helper, lookupProperty = container.lookupProperty || function(parent, propertyName) {
        if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
          return parent[propertyName];
        }
        return undefined
    };

  return "<strong>"
    + container.escapeExpression(((helper = (helper = lookupProperty(helpers,"name") || (depth0 != null ? lookupProperty(depth0,"name") : depth0)) != null ? helper : container.hooks.helperMissing),(typeof helper === "function" ? helper.call(depth0 != null ? depth0 : (container.nullContext || {}),{"name":"name","hash":{},"data":data,"loc":{"start":{"line":1,"column":8},"end":{"line":1,"column":16}}}) : helper)))
    + "</strong>\n";
},"useData":true});
})();

/*
 * Copyright (c) 2015
 *
 * This file is licensed under the Affero General Public License version 3
 * or later.
 *
 * See the COPYING-README file.
 *
 */

(function() {
	/**
	 * @class OCA.Activity.ActivityModel
	 * @classdesc
	 *
	 * Displays activity information for a given file
	 *
	 */
	var ActivityModel = OC.Backbone.Model.extend(/** @lends OCA.Activity.ActivityModel.prototype */{
		/**
		 *
		 * @returns int UNIX milliseconds timestamp
		 */
		getUnixMilliseconds: function () {
			if (_.isUndefined(this.unixMilliseconds)) {
				this.unixMilliseconds = moment(this.get('datetime')).valueOf();
			}
			return this.unixMilliseconds;
		},

		/**
		 * @returns string E.g. "seconds ago"
		 */
		getRelativeDate: function () {
			return OC.Util.relativeModifiedDate(this.getUnixMilliseconds());
		},

		/**
		 * @returns string E.g. "April 26, 2016 10:53 AM"
		 */
		getFullDate: function () {
			return OC.Util.formatDate(this.getUnixMilliseconds());
		},

		/**
		 * @returns bool
		 */
		isMonochromeIcon: function () {
			return this.get('type') !== 'file_created' && this.get('type') !== 'file_deleted' && this.get('type') !== 'favorite';
		}
	});

	OCA.Activity = OCA.Activity || {};
	OCA.Activity.ActivityModel = ActivityModel;
})();



/*
 * Copyright (c) 2015
 *
 * This file is licensed under the Affero General Public License version 3
 * or later.
 *
 * See the COPYING-README file.
 *
 */

(function() {

	OCA.Activity = OCA.Activity || {};

	/**
	 * @class OCA.Activity.ActivityCollection
	 * @classdesc
	 *
	 * Displays activity information for a given file
	 *
	 */
	var ActivityCollection = OC.Backbone.Collection.extend(
		/** @lends OCA.Activity.ActivityCollection.prototype */ {

		firstKnownId: 0,
		lastGivenId: 0,
		hasMore: false,

		/**
		 * Id of the file for which to filter activities by
		 *
		 * @var int
		 */
		_objectId: null,

		/**
		 * Type of the object to filter by
		 *
		 * @var string
		 */
		_objectType: null,

		model: OCA.Activity.ActivityModel,

		/**
		 * Sets the object id to filter by or null for all.
		 * 
		 * @param {int} objectId file id or null
		 */
		setObjectId: function(objectId) {
			this._objectId = objectId;
			this.firstKnownId = 0;
			this.lastGivenId = 0;
			this.hasMore = false;
		},

		/**
		 * Sets the object type to filter by or null for all.
		 * 
		 * @param {string} objectType string
		 */
		setObjectType: function(objectType) {
			this._objectType = objectType;
			this.firstKnownId = 0;
			this.lastGivenId = 0;
			this.hasMore = false;
		},

		/**
		 *
		 * @param ocsResponse
		 * @param response
		 * @returns {Array}
		 */
		parse: function(ocsResponse, response) {
			this._saveHeaders(response.xhr.getAllResponseHeaders());

			if (response.xhr.status === 304) {
				// No activities found
				return [];
			}

			return ocsResponse.ocs.data;
		},

		/**
		 * Read the X-Activity-First-Known and X-Activity-Last-Given headers
		 * @param headers
		 */
		_saveHeaders: function(headers) {
			var self = this;
			this.hasMore = false;

			headers = headers.split("\n");
			_.each(headers, function (header) {
				var parts = header.split(':');
				if (parts[0].toLowerCase() === 'x-activity-first-known') {
					self.firstKnownId = parseInt(parts[1].trim(), 10);
				} else if (parts[0].toLowerCase() === 'x-activity-last-given') {
					self.lastGivenId = parseInt(parts[1].trim(), 10);
				} else if (parts[0].toLowerCase() === 'link') {
					self.hasMore = true;
				}
			});
		},

		url: function() {
			var query = {
				format: 'json'
			};
			var url = OC.linkToOCS('apps/activity/api/v2/activity', 2) + 'filter';
			if (this.lastGivenId) {
				query.since = this.lastGivenId;
			}
			if (this._objectId && this._objectType) {
				query.object_type = this._objectType;
				query.object_id = this._objectId;
			}
			url += '?' + OC.buildQueryString(query);
			return url;
		}
	});

	OCA.Activity.ActivityCollection = ActivityCollection;
})();



/*
 * Copyright (c) 2015
 *
 * This file is licensed under the Affero General Public License version 3
 * or later.
 *
 * See the COPYING-README file.
 *
 */

(function() {

	/**
	 * @class OCA.Activity.ActivityTabView
	 * @classdesc
	 *
	 * Displays activity information for a given file
	 *
	 */
	var ActivityTabView = OCA.Files.DetailTabView.extend(/** @lends OCA.Activity.ActivityTabView.prototype */ {
		id: 'activityTabView',
		className: 'activityTabView tab',

		events: {
			'click .showMore': '_onClickShowMore'
		},

		_loading: false,
		_plugins: [],

		initialize: function() {
			this.collection = new OCA.Activity.ActivityCollection();
			this.collection.setObjectType('files');
			this.collection.on('request', this._onRequest, this);
			this.collection.on('sync', this._onEndRequest, this);
			this.collection.on('error', this._onError, this);
			this.collection.on('add', this._onAddModel, this);

			this._plugins = OC.Plugins.getPlugins('OCA.Activity.RenderingPlugins');
			_.each(this._plugins, function(plugin) {
				if (_.isFunction(plugin.initialize)) {
					plugin.initialize();
				}
			});
		},

		template: function(data) {
			return OCA.Activity.Templates['activitytabview'](data);
		},

		get$: function() {
			return this.$el;
		},

		getLabel: function() {
			return t('activity', 'Activity');
		},

		getIcon: function() {
			return 'icon-activity';
		},

		setFileInfo: function(fileInfo) {
			this._fileInfo = fileInfo;
			if (this._fileInfo) {
				this.collection.setObjectId(this._fileInfo.get('id'));
				this.collection.reset();
				this.collection.fetch();

				_.each(this._plugins, function(plugin) {
					if (_.isFunction(plugin.setFileInfo)) {
						plugin.setFileInfo('files', fileInfo.get('id'));
					}
				});
			} else {
				this.collection.reset();

				_.each(this._plugins, function(plugin) {
					if (_.isFunction(plugin.resetFileInfo)) {
						plugin.resetFileInfo();
					}
				});
			}
		},

		_onError: function() {
			var $emptyContent = this.$el.find('.emptycontent');
			$emptyContent.removeClass('hidden');
			$emptyContent.find('p').text(t('activity', 'An error occurred while loading activities'));
		},

		_onRequest: function() {
			if (this.collection.lastGivenId === 0) {
				this.render();
			}
			this.$el.find('.showMore').addClass('hidden');
		},

		_onEndRequest: function() {
			this.$container.removeClass('hidden');
			this.$el.find('.loading').addClass('hidden');
			if (this.collection.length) {
				this.$el.find('.emptycontent').addClass('hidden');
			}
			if (this.collection.hasMore) {
				this.$el.find('.showMore').removeClass('hidden');
			}
		},

		_onClickShowMore: function() {
			this.collection.fetch({
				reset: false
			});
		},

		/**
		 * Format an activity model for display
		 *
		 * @param {OCA.Activity.ActivityModel} activity
		 * @return {Object}
		 */
		_formatItem: function(activity) {

			var subject = escapeHTML(activity.get('subject')),
				subject_rich = activity.get('subject_rich');
			if (subject_rich[0].length > 1) {
				subject = OCA.Activity.RichObjectStringParser.parseMessage(subject_rich[0], subject_rich[1]);
			}
			var message = escapeHTML(activity.get('message')),
				message_rich = activity.get('message_rich');
			if (message_rich[0].length > 1) {
				message = OCA.Activity.RichObjectStringParser.parseMessage(message_rich[0], message_rich[1]);
			}

			var output = {
				subject: subject,
				formattedDate: activity.getRelativeDate(),
				formattedDateTooltip: activity.getFullDate(),
				isMonochromeIcon: activity.isMonochromeIcon(),
				timestamp: moment(activity.get('datetime')).valueOf(),
				message: message,
				icon: activity.get('icon')
			};

			/**
			 * Disable previews in the rightside bar,
			 * it's always the same image anyway.
			 if (activity.has('previews')) {
					output.previews = _.map(activity.get('previews'), function(data) {
						return {
							previewClass: data.isMimeTypeIcon ? 'preview-mimetype-icon': '',
							source: data.source
						};
					});
				}
			 */
			return output;
		},

		activityTemplate: function(params) {
			return OCA.Activity.Templates['activitytabview_activity'](params);
		},

		_onAddModel: function(model, collection, options) {
			var $el = $(this.activityTemplate(this._formatItem(model)));

			_.each(this._plugins, function(plugin) {
				if (_.isFunction(plugin.prepareModelForDisplay)) {
					plugin.prepareModelForDisplay(model, $el, 'ActivityTabView');
				}
			});

			if (!_.isUndefined(options.at) && collection.length > 1) {
				this.$container.find('li').eq(options.at).before($el);
			} else {
				this.$container.append($el);
			}

			this._postRenderItem($el);
		},

		_postRenderItem: function($el) {
			$el.find('.avatar').each(function() {
				var element = $(this);
				if (element.data('user-display-name')) {
					element.avatar(element.data('user'), 21, undefined, false, undefined, element.data('user-display-name'));
				} else {
					element.avatar(element.data('user'), 21);
				}
			});
			$el.find('.avatar-name-wrapper').each(function() {
				var element = $(this);
				var avatar = element.find('.avatar');
				var label = element.find('strong');

				$.merge(avatar, label).contactsMenu(element.data('user'), 0, element);
			});
			$el.find('.has-tooltip').tooltip({
				placement: 'bottom'
			});
		},


		/**
		 * Renders this details view
		 */
		render: function() {
			if (this._fileInfo) {
				this.$el.html(this.template({
					emptyMessage: t('activity', 'No activity yet'),
					moreLabel: t('activity', 'Load more activities')
				}));
				this.$container = this.$el.find('ul.activities');
			}
		}
	});

	OCA.Activity = OCA.Activity || {};
	OCA.Activity.ActivityTabView = ActivityTabView;
})();


/*
 * Copyright (c) 2015
 *
 * This file is licensed under the Affero General Public License version 3
 * or later.
 *
 * See the COPYING-README file.
 *
 */

(function(OCA) {

var FilesPlugin = {
	attach: function(fileList) {
		fileList.registerTabView(new OCA.Activity.ActivityTabView({order: -50}));
	}
};

OC.Plugins.register('OCA.Files.FileList', FilesPlugin);

})(OCA);



