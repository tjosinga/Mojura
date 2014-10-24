var SetupView = (function($) {

	"use strict";

	function run() {
		$("#setup-password-alert").addClass("hidden");
		var username = $("#setup-username").val();
		var realm = $("#setup-realm").val();
		var password = $("#setup-password").val();
		var confirm = $("#setup-confirm-password").val();
		var title = $("#setup-title").val();
		if (password !== confirm) {
			$("#setup-password-alert").removeClass("hidden");
			return;
		}
		var digest = CryptoJS.MD5(username + ":" + realm + ":" + password).toString();
		var url = "__api__/setup?_method=post";
		url += "&username=" + encodeURIComponent(username);
		url += "&digest=" + encodeURIComponent(digest);
		url += "&title=" + encodeURIComponent(title);
		$.getJSON(url, function(data) {
			$("#form-container").addClass("hidden");
			$("#success-container").removeClass("hidden");
		});
	}

	return {
		run: run
	};

})(jQuery);
