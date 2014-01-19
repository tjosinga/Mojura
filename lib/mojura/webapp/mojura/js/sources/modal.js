var Modal = (function($) {
	"use strict";

	var idCounter = 0;

	function create(options) {
		Locale.ensureLoaded("system", { loaded: function() {
			var template = $("#modal_template").html();
			if (typeof options.id !== "undefined") {
				$("#" + options.id).remove(); // Removes the modal if it already exists
			} else {
				options.id = "modal_" + idCounter++;
			}
			options.btn_action = (typeof options.btn_action !== "undefined") ? options.btn_action : Locale.str("system", "save");
			options.btn_class = (typeof options.btn_class !== "undefined") ? options.btn_class : "btn-primary";
			options.btn_cancel = Locale.str("system", "cancel");
			options.modal_large = (options.modal_large === true);

			var html = Mustache.render(template, options);
			$("body").append(html);

			var jBtn = $("." + options.btn_class, "#" + options.id);
			jBtn.click(function() {
				jBtn.button('loading');
				try {
					if (typeof options.onaction !== "undefined") {
						options.onaction(options.id);
					}
					else {
						$("form", "#" + options.id).ajaxSubmit(function(data) {
							if (typeof options.onsubmitted !== "undefined") {
								options.onsubmitted(data);
							}
							$("#" + options.id).modal("hide");
						});
					}
				}
				catch(exception) {}
				finally {
					return false;
				}
			});
			if (typeof options.oncreated !== "undefined") {
				options.oncreated(options.id);
			}
		}});
	}

	return {
		create: create
	};

})(jQuery);