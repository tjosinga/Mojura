var Modal = (function($) {
	"use strict";

	var idCounter = 1;
	var $modal;
	var options;
	var $form;
	var $btn;

	function create(opts) {
		options = opts;
		Locale.ensureLoaded("system", { loaded: function() {
			var template = $("#template-modal").html();
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

			$modal = $("#" + options.id);
			$modal.on("hidden.bs.modal", function (elem) {
				if ($modal.hasClass("fade")) {
					$modal.remove();
				}
			}); //Self-destructs, only if it contains the class fade (otherwise hides in favour of a sub modal)

			if ((!options.oncreated) || (!options.oncreated(options.id, onLoaded))) {
				onLoaded();
			}
		}});
	}

	function onLoaded() {
		$btn = $("." + options.btn_class, $modal);
		$form = $("form", $modal);
		var submitFormOnClick = (options.save_form) && ($form.size() > 0);

		if (submitFormOnClick) {
			$form.on("submit", onSubmit);
		}

		$btn.click(function () {
			if (submitFormOnClick) {
				onSubmit();
			} else if (typeof options.onaction !== "undefined") {
				$btn.button("loading");
				try {
					options.onaction(options.id);
				} catch (exception) {
					//TODO: Better error handling
				}
			} else {
				$("#" + options.id).modal("hide");
			}
		});
		$modal.modal("show");
	}

	function onSubmit() {
		$form = $("form", $modal);
		if (!Validator.validateForm($form[0])) {
			return false;
		}
		$btn.button("loading");
		$form.ajaxSubmit({
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
		return false;
	}

	return {
		create: create
	};

})(jQuery);