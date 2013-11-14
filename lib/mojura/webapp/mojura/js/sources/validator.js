/* global jQuery:false */

var Validator = (function ($) {
	"use strict";

	var errors = {};

	function validateForm(form) {
		//select all visible inputs which need validation
		errors = {};
		try {
			$("[data-validation]:visible").each(function () {
				validateInput(this);
			});
		}
		catch (err) {
			return false;
		}
		return (errors.length === 0);
	}

	function validateInput(elem) {
		var validations = $(elem).attr("data-validation").split(" ");
		var result = true;
		$.each(validations, function (index, validation) {
			var params = {};
			$(elem).parent().removeClass("has-error");
			if (!validateByString(validation, elem, params)) {
				errors[elem.name] = (typeof errors[elem.name] !== "undefined") ? errors[elem.name] : [];
				errors[elem.name].push(validation);
				$(elem).parent().addClass("has-error");
				result = false;
			}
		});
		return result;
	}

	function validateByString(validation, elem, params) {
		switch (validation) {
			case "required":
				return isRequired(elem, params);
			case "numeric":
				return isNumeric(elem, params);
			case "email":
				return isEmail(elem, params);
			case "url":
				return isEmail(elem, params);
			default:
				return true;
		}
	}

	function isRequired(elem, params) {
		return ((elem.nodeName === "INPUT") && (elem.type === "checkbox")) ? elem.checked : (elem.value !== "");
	}

	function isNumeric(elem, params) {
		var s = elem.value;
		if (params.decimalChar !== ".") {
			s = s.replace(params.decimalChar, ".");
		}
		return !isNaN(s);
	}

	function isEmail(elem, params) {
		var filter = /^([a-zA-Z0-9_\.\-])+@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
		return filter.test(elem.value);
	}

	function isUrl(elem, params) {
		var filter = /[-a-zA-Z0-9@:%_\+.~#?&//=]{2,256}\.[a-z]{2,4}\b(\/[-a-zA-Z0-9@:%_\+.~#?&//=]*)?/gi;
		return filter.test(elem.value);
	}

	return {
		validateForm: validateForm,
		isRequired: isRequired,
		isNumberic: isNumeric,
		isEmail: isEmail,
		isUrl: isUrl
	};

})(jQuery);