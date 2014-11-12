var Alert = (function() {

	"use strict";

	var template;

	function create(options) {
		options.type = (typeof options.type !== "undefined") ? options.type : "danger";
		options.dismissable = (typeof options.dismissable !== "undefined") ? options.dismissable : true;
		if (typeof options.title === "undefined") {
			options.title = Locale.str("system", "alert_title_" + options.type)
		}
		if (typeof template === "undefined") {
			template = $("#template-alert").html();
		}
		return Mustache.render(template, options);
	}

	return {
		create: create
	}

})();