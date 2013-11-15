var KeyValueParser = (function () {
	"use strict";

	var lastResult;

	function parse(str, options) {
		options = (typeof options !== 'undefined') ? options : {};
		options.sep_char = (typeof options.sep_char !== 'undefined') ? options.sep_char : "=";
		options.trim_values = (typeof options.trim_values !== 'undefined') ? options.trim_values : true;
		options.comment_char = (typeof options.comment_char !== 'undefined') ? options.comment_char : "#";

		var result = {};
		var lines = str.match(/[^\r\n]+/g);
		for (var i in lines) {
			if (lines.hasOwnProperty(i)) {
				var line = lines[i].replace(/^\s+|\s+$/g);
				if ((line !== "") && (line[0] !== options.comment_char)) {
					var arr = line.split(options.sep_char, 2);
					var key = arr[0].replace(/^\s+|\s+$/g, "");
					var value = arr[1];
					if (options.trim_values) {
						value = value.replace(/^\s+|\s+$/g, "");
					}
					result[key] = value;
				}
			}
		}

		lastResult = result;
		return result;
	}

	function toString() {
		var result = "";
		if (typeof lastResult !== 'undefined') {
			for (var key in lastResult) {
				if (lastResult.hasOwnProperty(key)) {
					result += key + ": " + lastResult[key] + "\n";
				}
			}
		}
		return result;
	}

	return { parse: parse, toString: toString };

})();