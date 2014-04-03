var AutoComplete = (function($) {

	"use strict";

	var datasets = {};

	function prepare(input, options) {
		var dataset = options.dataset || options.category || UIDGenerator.get();
		datasets[dataset] = {
			"input": input,
			"options": load_options(options)
		};
		var $input = $(input);
		$(input).after("<ul class='autocomplete-dropdown dropdown-menu hidden' data-toggle='dropdown'></ul>");

		datasets[dataset].$input = $input;
		datasets[dataset].options = load_options(options);
		datasets[dataset].$dropdown = $input.next(".autocomplete-dropdown");

		options = datasets[dataset].options;
		var $dropdown = datasets[dataset].$dropdown;
		var previousValue = "";

		$input
			.blur(function() {
				clearTimeout(options.timer);
				var items = datasets[dataset].$dropdown.children("li");
				if ((items.size() === 1) && (items.first().text() === $(this).val())) {
					items.first().click();
					return;
				}
				setTimeout(function() {
					if ((typeof $input.attr("data-id") === "undefined") || ($input.attr("data-id") === "")) {
						$input.val("");
					}
					$dropdown.addClass("hidden");
				}, 500);
			})
			.keyup(function(e) {
				if (e.keyCode === 27) { // Escape key
					$dropdown.addClass("hidden");
				} else if (e.keyCode === 38) { // Up key
					$dropdown.children("li.active").prev("li").addClass("active").next("li").removeClass("active");
				} else if (e.keyCode === 40) { // Down key
					var $activeItem = $dropdown.children("li.active");
					if ($activeItem.size() === 0) {
						$dropdown.children("li").first().addClass("active");
					} else {
						$activeItem.next().addClass("active").prev().removeClass("active");
					}
				} else if (e.keyCode === 13) { // Enter key
					$dropdown.children("li.active").click();
				}
			})
			.keypress(function() {
				if ((options.timer === null) || (typeof options.timer === "undefined")) {
					clearTimeout(options.timer);
				}
				options.timer = setTimeout(function() {
					load_list(dataset, $input.val());
				}, options.delay);
			});
	}

	function load_options(options) {
		options = options || {};
		options.url = options.url || "__api__/search?keywords=%KEYWORDS%&pagesize=%LENGTH%&category=%CATEGORY%";
		options.item_template = options.item_template || "<li data-id='{{id}}'>{{title}}</li>";
		options.timer = null;
		options.length = options.length || 8;
		options.category = options.category || '';
		options.forceSelection = true;
		options.delay = 1000;
		return options;
	}

	function load_list(dataset, keywords) {
		var $dropdown = datasets[dataset].$dropdown;
		var $input = datasets[dataset].$input;
		var options = datasets[dataset].options;

		if (keywords === "") {
			$dropdown.addClass("hidden");
			return;
		}
		var url = options.url
			.replace(/%KEYWORDS%/, keywords)
			.replace(/%LENGTH%/, options.length)
			.replace(/%CATEGORY%/, options.category);

		$.getJSON(url, function(json) {
			var previousActiveId = "";
			var html = "";
			for (var i in json) {
				html += Mustache.render(options.item_template, json[i]);
			}
			$dropdown.toggleClass("hidden", (html === ""));
			$dropdown.html(html).children("li").click(function() {
				clearTimeout(options.timer);
				$input.attr("data-id", $(this).attr("data-id")).val($(this).text());
				$dropdown.addClass("hidden");
				if (typeof options.onselected !== "undefined") {
					options.onselected($input[0]);
				};
			});
		});
	}

	return {
		prepare: prepare
	}
})(jQuery);