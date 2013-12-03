var Modal = (function($) {
	"use strict";

	var idCounter = 0;

	function create(options, onshow) {
		var template = $("#modal_template").html();
		if (typeof options.id !== "undefined") {
			$("#" + options.id).remove(); // Removes the modal if it already exists
		} else {
			options.id = "modal_" + idCounter++;
		}
		options.btn_title = (typeof options.btn_title !== "undefined") ? options.btn_title : Locale.str("system", "save");

		var html = Mustache.render(template, options);
		$("body").appendChild(html);
		if (typeof onshow !== "undefined") {
			onshow(options.id);
		}
	}

	return {
		create: create
	};

})(jQuery);