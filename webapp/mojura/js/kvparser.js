var KeyValueParser = (function ($) {

	lastResult = undefined;

	function parse(str, options) {
		if (options == undefined) options = {};
		if (options["sep_char"] == undefined) options["sep_char"] = "=";
		if (options["trim_values"] == undefined) options["trim_values"] = true;
		if (options["comment_char"] == undefined) options["comment_char"] = "#";

		result = {};
		lines = str.match(/[^\r\n]+/g);
		for (i in lines) {
			line = lines[i].replace(/^\s+|\s+$/g, "");
			if (line != "") {
				arr = line.split(options["sep_char"], 2);
				key = arr[0].replace(/^\s+|\s+$/g, "");
				value = arr[1];
				if (key[0] != options["comment_char"]) {
					key.replace(/' '/g, "_");
					if (options["trim_values"])
						value = value.replace(/^\s+|\s+$/g, "");
					result[key] = value;
				}
			}
		}
		lastResult = result;
		return result;
	}

	function toString() {
		result = "";
		if (lastResult != undefined)
			for (var key in lastResult)
				result += key + ": " + lastResult[key] + "\n";
		return result;
	}

	return { parse: parse, toString: toString };

})(jQuery);