var BooleanBoxes = (function($) {

	"use strict";

	function init($parent) {
		var $checkboxes = $("input[type=checkbox]").filter("input[data-type=boolean]").not(".initialized");

		$checkboxes.each(function() {
			var name = $(this).attr("name");
			var value = ($(this).attr("value").toString() === "true") ? "true" : "false";
			if (value === "true") {
				$(this).attr("checked", "checked");
			}

			$(this).after($("<input type='hidden' name='" + name + "' value='" + value + "'/>"));
			$(this).change(function() {
				var newValue = $(this).is(":checked") ? "true" : "false";
				$(this).next().attr("value", newValue);
			});
			$(this).removeAttr("name").removeAttr("value").addClass("initialized");
		});
	}

	return {
		init: init
	};

})(jQuery);