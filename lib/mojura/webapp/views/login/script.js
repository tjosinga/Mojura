/* global jQuery:false */
/* global CryptoJS:false */

var LoginView = (function ($) {
	"use strict";

	function authenticate(username, password, setCookie, onsuccess, onerror) {
		$.getJSON("__api__/salt", function (data) {
			var digest = CryptoJS.MD5(username + ":" + data.realm + ":" + password).toString();
			var iters = 500 + data.realm.length + username.length;
			var encrypted_digest = CryptoJS.PBKDF2(digest, data.salt, { keySize: 16, iterations: iters });
			var url = "__api__/authenticate?username=" + username + "&password=" + encrypted_digest;
			if (setCookie) {
				url += "&set_cookie=true";
			}
			$.getJSON(url,function (data) {
				if (onsuccess !== undefined) {
					onsuccess();
				}
			}).error(function () {
					if (onerror !== undefined) {
						onerror();
					}
				});
		});
	}

	function authenticateWithForm(form) {
		$(".alert", form).remove();
		$("input[name=submit]", form).button("loading");
		LoginView.authenticate($("input[name=username]", form).val(),
			$("input[name=password]", form).val(),
			$("input[name=set_cookie]", form).attr('checked'),
			function () {
				$(form).attr("onsubmit", "return false");
				$("input[name=submit]", form).button("complete").addClass("btn-success disabled").attr("disabled", "disabled");
				var redirect = $("input[name=redirect]", form).val();
				if (typeof redirect === "undefined") {
					redirect = "/";
				}
				window.location.href = redirect;
			},
			function () {
				var test = Alert.create({ text: Locale.str("login", "failed") });
				$(form).prepend(test);
				$("input[name=submit]", form).button("reset");
			});
	}

	function signOff(onsuccess) {
		$.getJSON("__api__/signoff", function (data) {
			if (onsuccess !== undefined) {
				onsuccess();
			}
		});
	}

	function signOffWithForm(form) {
		$("#submit", form).button("loading");
		LoginView.signOff(function () {
			$(form).attr("onsubmit", "return false");
			$("#submit", form).button("complete").addClass("btn-success disabled").attr("disabled", "disabled");
			window.location.href = "/";
		});
	}


	return {
		authenticate: authenticate,
		authenticateWithForm: authenticateWithForm,
		signOff: signOff,
		signOffWithForm: signOffWithForm
	};

})(jQuery);