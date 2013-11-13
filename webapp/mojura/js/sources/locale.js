/* global KeyValueParser:false */
/* global jQuery:false */

var Locale = (function($) {
	"use strict";

	var locale = "";
	var strings = {};

	function init(lc) {
		locale = lc;
	}

	function ensureLoaded(view, options) {
		if ((typeof strings === 'undefined') || (typeof strings[view] === 'undefined')) {
			load(view, options);
		}
		else if ((typeof options !== 'undefined') && (typeof options.loaded !== 'undefined')) {
			options.loaded();
		}
	}

	function load(view, options) {
		if (locale === "") {
			window.alert("You should initialize the locale object with Locale.init(\"en\"), where \"en\" is the used locale.");
			return;
		}
		if (view === undefined) {
			throw "The view needs to be set calling Locale.load(view, [options = {}])";
		}
		var url = "views/" + view + "/strings." + locale + ".kv";
		$.ajax({
			url: url,
			fail: function () {
				window.console.log("Error fetching " + url);
				if (typeof options.error !== 'undefined') {
					options.error();
				}
			},
			success: function (data) {
				try {
					strings[view] = KeyValueParser.parse(data);
					if ((typeof options !== 'undefined') && (typeof options.loaded !== 'undefined')) {
						options.loaded();
					}
				}
				catch (error) {
					window.console.log("Error on parsing " + url + ": " + error.message);
					strings[view] = {};
					if (typeof options.error !== 'undefined') {
						options.error();
					}
				}
			}
		});
	}

	function add(view, id, str) {
		if (strings[view] === undefined){
			strings[view] = {};
		}
		strings[view][id] = str;
	}


	function str(view, id) {
		return strings[view][id];
	}

	function rawStrings(views) {
		window.console.log("--- in rawStrings --- ");
		window.console.log(strings);
		window.console.log("--- END in rawStrings --- ");
		var result = {};
		for (var i in views) {
			if (views.hasOwnProperty(i)) {
				var view = views[i];
				for (var id in strings[view]) {
					if (strings[view].hasOwnProperty(id)) {
						result["locale_str_" + view + "_" + id] = strings[view][id];
					}
				}
			}
		}
		return result;
	}

	return {
		init: init,
		ensureLoaded: ensureLoaded,
		add: add,
		str: str,
		rawStrings: rawStrings
	};

})(jQuery);