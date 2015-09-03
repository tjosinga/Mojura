/* global jQuery:false */

var Validator = (function ($) {
	"use strict";

	var errors = {};

	function validateForm(form) {
		//select all visible inputs which need validation
		errors = {};
		try {
			$("[data-validation]:visible", form).each(function () {
				validateInput(this);
			});
		}
		catch (err) {
			return false;
		}
		return (Object.keys(errors).length === 0);
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
				return isUrl(elem, params);
			case "date":
				return isDate(elem, params);
			case "time":
				return isTime(elem, params);
			case "datetime":
				return isDateTime(elem, params);
			default:
				return true;
		}
	}

	function isRequired(elem, params) {
		return ((elem.nodeName === "INPUT") && (elem.type === "checkbox")) ? elem.checked : (elem.value.replace(/\s+$/, '') !== "");
	}

	function isNumeric(elem, params) {
		var s = elem.value;
		if (params.decimalChar !== ".") {
			s = s.replace(params.decimalChar, ".");
		}
		return !isNaN(s);
	}

	function isEmail(elem, params) {
		var filter = /^.+@.+\..+$/;
		return filter.test(elem.value);
	}

	function isUrl(elem, params) {
		var filter = /^[-a-zA-Z0-9@:%_\+.~#?&//=]{2,256}\.[a-z]{2,4}\b(\/[-a-zA-Z0-9@:%_\+.~#?&//=]*)?$/gi;
		return filter.test(elem.value);
	}

	function isDate(elem, params) {
		// Does not check if Feb 29 is in a leap year.
		var filter = /^\d{4}-(((0?1|0?3|0?5|0?7|0?8|10|12)-(0?[1-9]|[12]?\d|3[01]))|((0?4|0?6|0?9|11)-(0?[1-9]|[12]?\d|30))|((0?2)-(0?[1-9]|[12]\d)))$/gi;
		return filter.test(elem.value);
	}

	function isTime(elem, params) {
		var filter = /^([01]?[0-9]|2[0-3]):[0-5][0-9](:([0-5][0-9]))?$/gi;
		return filter.test(elem.value);
	}

	function isDateTime(elem, params) {
		var filter = /^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$/gi;
		return filter.test(elem.value);
	}




	return {
		validateForm: validateForm,
		isRequired: isRequired,
		isNumberic: isNumeric,
		isEmail: isEmail,
		isUrl: isUrl,
		isDate: isDate,
		isTime: isTime,
		isDateTime: isDateTime
	};

})(jQuery);