var Locale = (function($) {

	this.locale = "";
	this.strings = {};

	function init(lc) {
		locale = lc;
	}

	function ensureLoaded(view, options) {
		if ((strings === undefined) || (strings[view] === undefined))
			load(view, options);
		else if ((options !== undefined) && (options.loaded !== undefined))
			options.loaded();
	}

	function load(view, options) {
		if (locale == "") {
			alert("You should initialize the locale object with Locale.init(\"en\"), where \"en\" is the used locale.");
			return;
		}
		if (view === undefined)
			throw "The view needs to be set calling Locale.load(view, [options = {}])";
		url = "views/" + view + "/strings." + locale + ".kv";
		$.ajax({
			url: url,
			fail: function () {
				console.log("Error fetching " + url);
				if (options.error !== undefined) options.error();
			},
			success: function (data) {
				try {
 					strings[view] = KeyValueParser.parse(data);
					if ((options !== undefined) && (options.loaded !== undefined))
						options.loaded();
				}
				catch (error){
					console.log("Error on parsing " + url);
					strings[view] = {};
					if (options.error !== undefined) options.error();
				}
			}
		});
	}

	function add(view, id, str) {
		if (strings[view] === undefined)
			strings[view] = {};
		strings[view][id] = str;
	}


	function str(view, id) {
		return strings[view][id];
	}

	function rawStrings(views) {
		console.log("--- in rawStrings --- ");
		console.log(strings);
		console.log("--- END in rawStrings --- ");
		result = {}
		for (i in views) {
			view = views[i];
			for (id in strings[view])
				result["locale_str_" + view + "_" + id] = strings[view][id];
		}
		return result;
	}

	return {
		init: init,
		ensureLoaded: ensureLoaded,
		add: add,
		str: str,
		rawStrings: rawStrings
	}

})(jQuery);