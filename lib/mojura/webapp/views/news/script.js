var NewsView = (function($) {
	"use strict";

	$(document).ready(function () {
		Locale.ensureLoaded("system");
		Locale.ensureLoaded("news");
	});

	function showAdd() {
		showEdit("new");
	}

	function showEdit(newsid) {
		Modal.create({
			id: "newsAddEditModal",
			modal_large: true,
			title: Locale.str("news", "edit"),
			oncreated: function(modalId, onLoaded) {
				$("#" + modalId).modal("show");
				var url = "__api__/news/" + newsid + '?include_settings=news.categories';
				$.getJSON(url, function(data) {
					var template = $("#template-news-addedit").html();
					data = $.extend({}, data, Locale.getViewsStrings(["system", "news"]));
					data.method = (newsid === "new") ? "post" : "put";
					data.newsid = newsid;
					var cats = data.settings.news.categories;
					if ((typeof cats !== "null") || ((typeof cats !== "undefined"))) {
						data.has_categories = true;
						if (typeof cats === "string") {
							data.categories = cats.split(",");
						} else {
							data.categories = cats;
						}
						for (var i in data.categories) {
							data.categories[i] = data.categories[i].replace(/(^\s+|\s+$)/, '');
						}
					}
					data.urid = UIDGenerator.get();
					data.simple_rights_visible = ((data.rights.rights & 4) > 0);
					var partials = {"rights-controls": $("#template-rights-controls").html() };
					var html = Mustache.render(template, data, partials);
					$(".modal-body", "#" + modalId).html(html);
					onLoaded();
				});
				return true;
			},
			onsubmitted: function(modalId, data) {
				location.reload();
			}
		});
	}

	function showDelete(newsid) {
		Modal.create({
			id: "newsDeleteModal",
			btn_class: "btn-danger",
			btn_action: Locale.str("system", "delete"),
			title: Locale.str("news", "delete"),
			oncreated: function(modalId) {
				$("#" + modalId).modal("show");
				var template = $("#template-news-delete").html();
				var data = Locale.getViewsStrings(["system", "news"]);
				data.newsid = newsid;
				data.urid = UIDGenerator.get();
				var html = Mustache.render(template, data);
				$(".modal-body", "#" + modalId).html(html);
			},
			onsubmitted: function(modalId, data) {
				gotoList();
			}
		});
	}

	function gotoList() {
		document.location = $("base").attr("href") + "news";
	}

	return {
		showAdd: showAdd,
		showEdit: showEdit,
		showDelete: showDelete,
		gotoList: gotoList
	};


})(jQuery);