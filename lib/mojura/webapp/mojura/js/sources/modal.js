var Modal = (function($) {
	"use strict";

	var idCounter = 1;

	function create(options) {
		Locale.ensureLoaded("system", { loaded: function() {
			var template = $("#modal_template").html();
			if (typeof options.id === "undefined") {
				options.id = "modal_" + idCounter++;
			}
			options.btn_action = (typeof options.btn_action !== "undefined") ? options.btn_action : Locale.str("system", "save");
			options.btn_class = (typeof options.btn_class !== "undefined") ? options.btn_class : "btn-primary";
			options.btn_cancel = (typeof options.btn_cancel !== "undefined") ? options.btn_cancel : Locale.str("system", "cancel");
			options.modal_large = (options.modal_large === true);
			options.fade = (options.fade !== false);
			options.urid = UIDGenerator.get();
			options.save_form = (options.save_form !== false);

			var html = Mustache.render(template, options);
			$("body").append(html);

			$("#" + options.id).on("hidden.bs.modal", function(elem) {
				if ($("#" + options.id).hasClass("fade")) {
					$("#" + options.id).remove();
				}
			}); //Self-destructs, only if it contains the class fade (otherwise hides in favour of a sub modal)

			var $btn = $("." + options.btn_class, "#" + options.id);
			$btn.click(function() {
				if ($("#" + options.id).has("form")) {
					if (!Validator.validateForm($("form", "#" + options.id)[0])) {
						return false;
					}
					try {
						if (typeof options.onaction !== "undefined") {
							$btn.button("loading");
							options.onaction(options.id);
						}
						else if (options.save_form) {
							var $form = $("form", "#" + options.id);
							if ($form.size() == 0) {
								$("#" + options.id).modal("hide");
							}
							else {
								$btn.button("loading");
								$form.on("submit", function () {
									return false;
								}).ajaxSubmit({
									success: function (data) {
										$btn.button("complete").addClass("btn-success disabled");
										setTimeout(function () {
											if (typeof options.onsubmitted !== "undefined") {
												options.onsubmitted(options.id, data);
											}
											$("#" + options.id).modal("hide");
										}, 200);
									},
									error: function (e) {
										$btn.button('reset');
										if (typeof options.onerror !== "undefined") {
											options.onerror(options.id, e.status);
										}
									}
								});
							}
						}
						else {
							$("#" + options.id).modal("hide");
						}

					}
					catch(exception) {}
					finally {
						return false;
					}
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