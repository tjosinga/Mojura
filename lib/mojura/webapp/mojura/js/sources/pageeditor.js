/* global jQuery:false */
/* global Mustache:false */
/* global Locale:false */
/* global UIDGenerator:false */

var PageEditor = (function ($) {
	"use strict";

	var pageId = "";
	var views = [];


	function init(_pageId, _views) {
		pageId = _pageId;
		views = _views;

		var oldPosition = "";
		$(".page-content-parts").sortable({
			handle: ".editable .sortable-handle",
			itemSelector: ".editable",
			vertical: true,
			nested: true,
			placeholder: "<i class='fa fa-chain text-danger'></i>",
			containerSelector: ".page-content-parts, .view-subviews",
			onDragStart: function ($item, container, _super) {
				oldPosition = getViewIdFromView($item[0]);
			},
			onDrag: function ($item, position, _super) {
				$item.css(position);
				_super($item, position);
			},
			onDrop: function ($item, container, _super) {
				_super($item, container);
				var newPosition = getViewIdFromView($item[0]);
				if (newPosition !== oldPosition) {
					window.alert("moved");
				}
			}
		});
	}

	function togglePageAdmins() {
		$(".btn-edit-page").toggleClass("hidden");
		$(".view-admin").toggleClass("hidden").parent().toggleClass("editable");
		var url = window.location.toString().replace(/#+editing/, "");
		if ($(".btn-edit-page").is(":visible")) {
			url += "#editing";
		}
		history.pushState({}, document.title, url);
	}

	function showAddSubpage() {
		showAddEditPage("post", pageId);
	}

	function showAddMainpage() {
		showAddEditPage("post", "");
	}

	function showEditPage() {
		showAddEditPage("put");
	}

	function showAddEditPage(method, parentId) {
		var titleId = (method === "post") ? "add_page" : "edit_page";
		Modal.create({
			title: Locale.str("system", titleId),
			oncreated: function(modalId, onLoaded) {
				var url = "__api__/pages/";
				url += (method === "put") ? pageId : "new";
				$("#" + modalId).modal("show");
				$.getJSON(url, function(data) {
					var template = $("#template-pageview-addedit-page").html();
					data = $.extend({}, data, Locale.getViewsStrings(["system"]));
					if (typeof parentId !== "undefined") {
						data.parentid = parentId;
					}
					data.method = method;
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
				var url = "";
				if (typeof data.breadcrumbs !== "undefined") {
					for (var i = 0; i < data.breadcrumbs.length; i++) {
						url += encodeURI(data.breadcrumbs[i].title) + "/";
					}
				}
				url += encodeURI(data.title) + "#editing";
				document.location = url;
			}
		});
	}

	function showDeletePage() {
		Modal.create({
			title: Locale.str("system", "delete_page"),
			btn_action: Locale.str("system", "delete"),
			btn_class: 'btn-danger',
			oncreated: function(modalId) {
				var template = $("#template-pageview-delete-page").html();
				var data = Locale.getViewsStrings(["system"]);
				data.pageid = pageId;
				data.urid = UIDGenerator.get();
				var html = Mustache.render(template, data);
				$(".modal-body", "#" + modalId).html(html);
				$("#" + modalId).modal("show");
			},
			onsubmitted: function(modalId, data) {
				var url = document.location.toString();
				document.location = url.slice(0, url.lastIndexOf("/"));
			}
		});
	}

	function getViewIdFromView(viewObj) {
		var result = "";
		$(viewObj).parents(".view").each(function (index, obj) {
			result = $(obj).index().toString() + "," + result;
		});
		return result + $(viewObj).index();
	}


	function showEditView(viewObj) {
		var original_view = '';
		var original_settings = {};
		var viewId = '';
		Modal.create({
			title: Locale.str("system", "edit_view"),
			modal_large: true,
			oncreated: function(modalId, onLoaded) {
				viewId = getViewIdFromView(viewObj);
				var url = "__api__/pages/" + pageId + "/view/" + viewId;
				$("#" + modalId).modal("show");
				$.getJSON(url, function(data) {
					original_view = data.view;
					original_settings = $.extend({}, data.settings);
					var template = $("#template-pageview-edit-view").html();
					data = $.extend({}, data, Locale.getViewsStrings(["system"]));
					data.urid = UIDGenerator.get();
					data.pageid = pageId;
					data.views = views;
					data.available_col_spans = [];
					for (var i = 1; i <= 12; i++) {
						data.available_col_spans.push(i);
					}
					data.available_col_offsets = [];
					for (i = 0; i <= 12; i++) {
						data.available_col_offsets.push(i);
					}
					var html = Mustache.render(template, data);
					$(".modal-body", "#" + modalId).html(html);
					setEditViewData("#" + modalId, data);
					onLoaded();
				});
				return true;
			},
			onsubmitted: function(modalId, data) {
				if ((original_view !== data.view) || (JSON.stringify(original_settings) !== JSON.stringify(data.settings))) {
					location.reload();
				}
				else {
					$(viewObj).children('.view-text').html(data.content.html);
				}
			}
		});
	}

	function setEditViewData(modalId, data) {
		$("select[name=view]", modalId).change(function () {
			var view = $(this).val();
			if (view === "") {
				$(".view-settings", modalId).html("");
				$(".view_texteditor textarea", modalId).removeClass("small");
				return;
			}
			$(".view_texteditor textarea", modalId).addClass("small");

			$(".view-settings", modalId).html("<div class='loading'></div>");
			Locale.ensureLoaded(view, { loaded: function() {
				var url = "views/" + view + "/coworkers/view_edit_settings.mustache?static_only=true";
				$.get(url, {cache: false}, function (template) {
					var strs = Locale.getViewsStrings(["system", view]);
					data.urid = UIDGenerator.get();
					data.pageid = pageId;
					if (typeof data.settings === "undefined") {
						data.settings = {};
					}
					data.settings.modalId = modalId.replace(/^#/, "");
					for (var id in strs) {
						if (strs.hasOwnProperty(id)) {
							data.settings[id] = strs[id];
						}
					}
					var html = Mustache.to_html(template, data.settings); //TODO: Convert all coworkers to use data instead.
					$(".view-settings", modalId).html(html);
				}).error(function () {
					$(".view-settings", modalId).html("");
				});
			}});
		}).val(data.view).trigger("change");

		$("select[name=col_span]", modalId).val(data.col_span);
		$("select[name=col_offset]", modalId).val(data.col_offset);
		$("select[name=row_offset]", modalId).val(data.row_offset);
		$("select[name=view] option", modalId).removeAttr("disabled");

		if (data.col_span < 12) {
			var min_col_spans = [];
			for (var i = 12; i > data.col_span; i--) {
				min_col_spans.push(".min-col-span" + i);
			}
			$(min_col_spans.join(",")).attr("disabled", "disabled");
		}

		TextEditor.init("#content_" + data.urid, modalId);
	}


	function showDeleteView(viewObj) {
		Modal.create({
			title: Locale.str("system", "delete_view"),
			btn_action: Locale.str("system", "delete"),
			btn_class: 'btn-danger',
			oncreated: function(modalId) {
				var template = $("#template-pageview-delete-view").html();
				var data = Locale.getViewsStrings(["system"]);
				data.pageid = pageId;
				data.viewid = getViewIdFromView(viewObj);
				data.urid = UIDGenerator.get();
				var html = Mustache.render(template, data);
				$(".modal-body", "#" + modalId).html(html);
			},
			onsubmitted: function(modalId, data) {
				$(viewObj).remove();
			}
		});
	}


	function addSubview(templateid, path) {
		var url = "__api__/pages/" + pageId + "/views/?_method=post&template=" + templateid;
		if ((path !== undefined) && (path !== "")) {
			url += "&parentid=" + path;
		}
		$.getJSON(url, function (data) {
			location.reload();
		});
	}

	return {
		init: init,
		togglePageAdmins: togglePageAdmins,
		showAddSubpage: showAddSubpage,
		showAddMainpage: showAddMainpage,
		showEditPage: showEditPage,
		showDeletePage: showDeletePage,
		showEditView: showEditView,
		showDeleteView: showDeleteView,
		addSubview: addSubview
	};

})(jQuery);