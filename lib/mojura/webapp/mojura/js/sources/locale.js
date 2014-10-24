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
		if (typeof strings[view] === 'undefined') {
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
		if (typeof view === "undefined") {
			throw "The view needs to be set calling Locale.load(view, [options = {}])";
		}

		var url = (view === "system") ? "mojura/views/strings." + locale + ".kv" : "views/" + view + "/strings." + locale + ".kv";
		$.ajax({
			url: url,
			error: function () {
				if ((typeof options !== 'undefined') && (typeof options.loaded !== 'undefined') && (options.breakOnFail !== true)) {
					options.loaded();
				}
			},
			fail: function () {
				window.console.log("Error fetching " + url);
				if (typeof options.error !== 'undefined') {
					options.error();
				}
				if ((typeof options !== 'undefined') && (typeof options.loaded !== 'undefined') && (options.breakOnFail !== true)) {
					options.loaded();
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
		if (typeof strings[view] === 'undefined') {
			strings[view] = {};
		}
		strings[view][id] = str;
	}


	function str(view, id) {
		if ((typeof strings[view] !== 'undefined') && (typeof strings[view][id] !== 'undefined')) {
			return strings[view][id];
		}
		else {
			return "__" + view + "_" + id + "__";
		}
	}

	function loadedViews() {
		var result = [];
		$.each(strings, function(view, strs) {
			result.push(view);
		});
		return result;
	}

	function getViewStrings(view, formattedKeys, filter) {
		formattedKeys = (typeof	formattedKeys === 'undefined') || (formattedKeys === true);
		var filtered = (typeof filter !== 'undefined');
		var result = {};
		if (typeof strings[view] !== 'undefined') {
			$.each(strings[view], function(id, str) {
				if ((!filtered) || (id.indexOf(filter) === 0)) {
					if (formattedKeys) {
						result["locale_str_" + view + "_" + id] = str;
					} else {
						result[id] = str;
					}
				}
			});
		}
		return result;
	}

	function getViewsStrings(views, formattedKeys, filter) {
		formattedKeys = (typeof	formattedKeys === 'undefined') || (formattedKeys === true);
		var result = {};
		if (typeof views === 'undefined') {
			return result;
		}
		$.each(views, function(index, view) {
			var strs = getViewStrings(view, formattedKeys, filter);
			if (formattedKeys) {
				result = $.extend({}, result, strs);
			} else {
				result[view] = strs;
			}
		});
		return result;
	}

	return {
		init: init,
		ensureLoaded: ensureLoaded,
		loadedViews: loadedViews,
		add: add,
		str: str,
		getViewStrings: getViewStrings,
		getViewsStrings: getViewsStrings
	};

})(jQuery);