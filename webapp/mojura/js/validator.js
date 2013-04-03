var Validator = (function ($) {

	var errors = {};

	function validateForm(form) {

		//select all visible inputs which need validation
		errors = {};
		$("[data-validation]:visible").each(function (index) {
			validateInput(this);
		});
		alert(JSON.stringify(errors));
	};

	function validateInput(elem) {
		validations = $(elem).attr("data-validation").split(" ");
		$.each(validations, function (index, validation) {
			params = {};
			if (!validateByString(validation, elem, params)) {
				if (errors[elem.name] === undefined) errors[elem.name] = [];
				errors[elem.name].push(validation);
				return false;
			}
		});
		return true;
	};

	function validateByString(validation, elem, params) {
		switch (validation) {
			case "required":
				return isRequired(elem, params);
				break;
			case "numeric":
				return isNumeric(elem, params);
				break;
			case "email":
				return isEmail(elem, params);
				break;
			default:
				return true;
		}
	};

	function isRequired(elem, params) {
		if ((elem.nodeName == "INPUT") && (elem.type == "checkbox"))
			return elem.checked;
		else
			return (elem.value != "");
	};

	function isNumeric(elem, params) {
		s = elem.value;
		if (params.decimalChar != ".")
			s = s.replace(params.decimalChar, ".");
		return !isNaN(s);
	};

	function isEmail(elem, params) {
		var filter = /^([a-zA-Z0-9_\.\-])+@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
		return filter.test(elem.value);
	};

	return {validateForm: validateForm,
		isRequired: isRequired,
		isNumberic: isNumeric,
		isEmail: isEmail
	};

})(jQuery);