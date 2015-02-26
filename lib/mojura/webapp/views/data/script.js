var DataView = (function($) {

	"use strict";

	var prettify = (function () {
		return function (text, render) {
			return moment(render(text)).format("L LT");
		};
	});

	function load(id, step) {
		moment.lang("nl");

		var $container = $("#" + id);
		var page = parseInt($container.attr("data-page"));
		step = $.isNumeric(step) ? step : 1;

		$("tbody", $container).html("");
		$(".loading", $container).removeClass("hidden");

		var url = "__api__/data?page=" + (page + step);
		$.getJSON(url, function(data) {
			var template = $("#template-data-table-body").html();
			data.prettify = prettify;
			var html = Mustache.to_html(template, data);
			$(".loading", $container).addClass("hidden");
			$("tbody", $container).html(html);
			$(".pager .previous", $container).toggleClass("disabled", data.pageinfo.current === 1);
			$(".pager .next", $container).toggleClass("disabled", data.pageinfo.current === data.pageinfo.pagecount);
			$container.attr("data-page", data.pageinfo.current);
		});

	}

	function previous(id) {
		if (!$("#" + id + " .pager .previous").hasClass("disabled")) {
			load(id, -1);
		}
	}

	function next(id) {
		if (!$("#" + id + " .pager .next").hasClass("disabled")) {
			load(id, 1);
		}
	}

	function showInfo(dataId) {
		Modal.create({
			id: "dataInfo",
			title: Locale.str("data", "details"),
			btn_cancel: false,
			btn_action: Locale.str("system", "close"),
			oncreated: function(modalId, onLoaded) {
				$("#" + modalId).modal("show");
				var url = "__api__/data/" + dataId;
				$.getJSON(url, function(data) {
					var template = $("#template-data-details").html();
					var values = [];
					for (var k in data.values) {
						var v = data.values[k];
						var large = false;
						if (typeof v === "object") {
							v = JSON.stringify(v);
							large = true;
						} else {
							v = v.toString();
							large = (v.length > 100);
						}
						values.push({key: k, value: v, large: large});
					}
					data.values = values;
					data.prettify = prettify;
					var html = Mustache.to_html(template, data);
					$(".modal-body", "#" + modalId).html(html);
					onLoaded();
				});
				return true;
			},
		});
	}

	return {
		load: load,
		previous: previous,
		next: next,
		showInfo: showInfo
	};


})(jQuery);