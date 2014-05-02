/* This file is generated with Mojura's tool 'combine_js'.
   It combines all JavaScript files which are stored in lib/mojura/webapp/mojura/js/sources/.*/

/* advancedobjectrights.js */

var AdvancedObjectRights = (function($) {

	"use strict";

	var modalId;

	function show(rights, userIds, groupIds, options) {
		var parentModalId = options.parentModalId;
		Modal.create({
			title: Locale.str("system", "advanced_object_rights"),
			oncreated: function (id) {
				modalId = id;
				createForm(rights, userIds, groupIds);
				if (typeof parentModalId !== "undefined") {
					$("#" + parentModalId)
						.removeClass("fade")
						.one("hidden.bs.modal", function() {
							$("#" + modalId)
								.removeClass("fade")
								.one("hidden.bs.modal", function () {
									$("#" + parentModalId)
										.one("shown.bs.modal", function () {
											$(this).addClass("fade")
										})
										.modal("show");
								})
								.modal("show");
						})
						.modal("hide");
				} else {
					$("#" + modalId).modal("show");
				}
			},
			onaction: function() {
				if (typeof options.onsave !== "undefined") {
					options.onsave(getRights(), getIds("users"), getIds("groups"));
				}
				$("#" + modalId).modal("hide");
			}
		});
	}

	function createForm(rights, userIds, groupIds) {
		var template = $("#template-advanced-object-rights").html();
		var data = Locale.getViewStrings("system");
		data.categories = [
			{"name": Locale.str("system", "guests"), "bits": [4, 3, 2, 1] },
			{"name": Locale.str("system", "users"), "bits": [8, 7, 6, 5] },
			{"name": Locale.str("system", "groupmembers"), "bits": [12, 11, 10, 9] },
			{"name": Locale.str("system", "owners"), "bits": [16, 15, 14, 13] }
		];
		var html = Mustache.render(template, data);
		$(".modal-body", "#" + modalId).html(html);
		setRights(rights);
		setIds("users", userIds);
		setIds("groups", groupIds);
		var onselected = function(input) {
			$(input).closest(".input-group").find(".btn-success").toggleClass("disabled", $(input).attr("data-id") === "");
		};
		AutoComplete.prepare("#" + modalId + " .add-users input", {category: "users", onselected: onselected});
		AutoComplete.prepare("#" + modalId + " .add-groups input", {category: "groups", onselected: onselected});
	}

	function setRights(rights) {
		$(".advanced-rights-checkbox", "#" + modalId).each(function() {
			var bit = parseInt($(this).attr("data-bit"), 10);
			var bitValue = 1 << (bit - 1);
			var result = (rights & bitValue);
			$(this).prop("checked", (rights & bitValue));
		});
	}

	function getRights() {
		var sum = 0;
		$(".advanced-rights-checkbox:checked", "#" + modalId).each(function() {
			var bit = parseInt($(this).attr("data-bit"), 10);
			sum += 1 << (bit - 1);
		});
		return sum;
	}

	function setIds(type, ids) {
		if (ids.length > 0) {
			$(".advanced-rights-" + type  + "-list", "#" + modalId).html("<div class='loading'></div>");
			var url = "__api__/" + type  + "?filter=id:(" + ids.join(encodeURIComponent("|")) + ")";
			$.getJSON(url, function(json) {
				var template = $("#template-advanced-object-rights-" + type).html();
				var data = {};
				data[type] = json.items;
				var html = Mustache.render(template, data);
				$(".advanced-rights-" + type  + "-list", "#" + modalId).html(html);
				$(".advanced-rights-" + type  + "-alert", "#" + modalId).toggleClass("hidden", json.items.length !== 0);
			});
		} else {
			$(".advanced-rights-" + type  + "-alert", "#" + modalId).removeClass("hidden");
		}
	}

	function getIds(type) {
		var ids = [];
		$(".advanced-rights-" + type  + "-list .listitem", "#" + modalId).each(function() {
			ids.push($(this).attr("data-id"));
		});
		return ids;
	}

	function removeId(object, type) {
		$(object).parent().parent().remove();
		var shouldAdd = ($(".advanced-rights-" + type  + "-list .listitem", "#" + modalId).size() > 0);
		$(".advanced-rights-" + type  + "-alert", "#" + modalId).toggleClass("hidden", shouldAdd);
	}

	function showAdd(type) {
		$("#" + modalId + " .add-" + type).removeClass("hidden").find(".btn-success").addClass("disabled");
	}

	function confirmAdd(type) {
		var $input = $(".add-" + type + " input", "#" + modalId);
		var id = $input.attr("data-id");
		var title = $input.val();
		var data = {};
		if (type === "users") {
			data = {users: {id: id, fullname: title}};
		} else {
			data = {groups: {id: id, name: title}};
		}
		var template = $("#template-advanced-object-rights-" + type).html();
		var html = Mustache.render(template, data);

		$(".advanced-rights-" + type + "-list", "#" + modalId).append(html);
		$(".advanced-rights-" + type + "-alert").addClass("hidden");
		$("#" + modalId + " .add-" + type).addClass("hidden");
}

	function cancelAdd(type) {
		$("#" + modalId + " .add-" + type).addClass("hidden");
	}

	return {
		show: show,
		removeId: removeId,
		showAdd: showAdd,
		confirmAdd: confirmAdd,
		cancelAdd: cancelAdd
	};

})(jQuery);


/* autocomplete.js */

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


/* kvparser.js */

var KeyValueParser = (function () {
	"use strict";

	var lastResult;

	function parse(str, options) {
		options = (typeof options !== 'undefined') ? options : {};
		options.sep_char = (typeof options.sep_char !== 'undefined') ? options.sep_char : "=";
		options.trim_values = (typeof options.trim_values !== 'undefined') ? options.trim_values : true;
		options.comment_char = (typeof options.comment_char !== 'undefined') ? options.comment_char : "#";

		var result = {};
		var lines = str.match(/[^\r\n]+/g);
		for (var i in lines) {
			if (lines.hasOwnProperty(i)) {
				var line = lines[i].replace(/^\s+|\s+$/g);
				if ((line !== "") && (line[0] !== options.comment_char)) {
					var arr = line.split(options.sep_char, 2);
					var key = arr[0].toString().replace(/^\s+|\s+$/g, ""); //toString() to please the IDE
					var value = arr[1];
					if (options.trim_values) {
						value = value.replace(/^\s+|\s+$/g, "");
					}
					result[key] = value;
				}
			}
		}

		lastResult = result;
		return result;
	}

	function toString() {
		var result = "";
		if (typeof lastResult !== 'undefined') {
			for (var key in lastResult) {
				if (lastResult.hasOwnProperty(key)) {
					result += key + ": " + lastResult[key] + "\n";
				}
			}
		}
		return result;
	}

	return { parse: parse, toString: toString };

})();


/* locale.js */

/* global KeyValueParser:false */
/* global jQuery:false */

var Locale = (function($) {
	"use strict";

	var locale = "";
	var strings = {};

	function init(lc) {
		locale = lc;
	}

	function ensureLoaded(view, options) {
		if (typeof strings[view] === 'undefined') {
			load(view, options);
		}
		else if ((typeof options !== 'undefined') && (typeof options.loaded !== 'undefined')) {
			options.loaded();
		}
	}

	function load(view, options) {
		if (locale === "") {
			window.alert("You should initialize the locale object with Locale.init(\"en\"), where \"en\" is the used locale.");
			return;
		}
		if (typeof view === "undefined") {
			throw "The view needs to be set calling Locale.load(view, [options = {}])";
		}

		var url = (view === "system") ? "mojura/views/strings." + locale + ".kv" : "views/" + view + "/strings." + locale + ".kv";
		$.ajax({
			url: url,
			fail: function () {
				window.console.log("Error fetching " + url);
				if (typeof options.error !== 'undefined') {
					options.error();
				}
			},
			success: function (data) {
				try {
					strings[view] = KeyValueParser.parse(data);
					if ((typeof options !== 'undefined') && (typeof options.loaded !== 'undefined')) {
						options.loaded();
					}
				}
				catch (error) {
					window.console.log("Error on parsing " + url + ": " + error.message);
					strings[view] = {};
					if (typeof options.error !== 'undefined') {
						options.error();
					}
				}
			}
		});
	}

	function add(view, id, str) {
		if (typeof strings[view] === 'undefined') {
			strings[view] = {};
		}
		strings[view][id] = str;
	}


	function str(view, id) {
		if ((typeof strings[view] !== 'undefined') && (typeof strings[view][id] !== 'undefined')) {
			return strings[view][id];
		}
		else {
			return "__" + view + "_" + id + "__";
		}
	}

	function loadedViews() {
		var result = [];
		$.each(strings, function(view, strs) {
			result.push(view);
		});
		return result;
	}

	function getViewStrings(view, formattedKeys, filter) {
		formattedKeys = (typeof	formattedKeys === 'undefined') || (formattedKeys === true);
		var filtered = (typeof filter !== 'undefined');
		var result = {};
		if (typeof strings[view] !== 'undefined') {
			$.each(strings[view], function(id, str) {
				if ((!filtered) || (id.indexOf(filter) === 0)) {
					if (formattedKeys) {
						result["locale_str_" + view + "_" + id] = str;
					} else {
						result[id] = str;
					}
				}
			});
		}
		return result;
	}

	function getViewsStrings(views, formattedKeys, filter) {
		formattedKeys = (typeof	formattedKeys === 'undefined') || (formattedKeys === true);
		var result = {};
		if (typeof views === 'undefined') {
			return result;
		}
		$.each(views, function(index, view) {
			var strs = getViewStrings(view, formattedKeys, filter);
			if (formattedKeys) {
				result = $.extend({}, result, strs);
			} else {
				result[view] = strs;
			}
		});
		return result;
	}

	return {
		init: init,
		ensureLoaded: ensureLoaded,
		loadedViews: loadedViews,
		add: add,
		str: str,
		getViewStrings: getViewStrings,
		getViewsStrings: getViewsStrings
	};

})(jQuery);


/* modal.js */

var Modal = (function($) {
	"use strict";

	var idCounter = 1;

	function create(options) {
		Locale.ensureLoaded("system", { loaded: function() {
			var template = $("#modal_template").html();
			if (typeof options.id === "undefined") {
				options.id = "modal_" + idCounter++;
			}
			options.btn_action = (typeof options.btn_action !== "undefined") ? options.btn_action : Locale.str("system", "save");
			options.btn_class = (typeof options.btn_class !== "undefined") ? options.btn_class : "btn-primary";
			options.btn_cancel = (typeof options.btn_cancel !== "undefined") ? options.btn_cancel : Locale.str("system", "cancel");
			options.modal_large = (options.modal_large === true);
			options.fade = (options.fade !== false);
			options.urid = UIDGenerator.get();
			options.save_form = (options.save_form !== false);

			var html = Mustache.render(template, options);
			$("body").append(html);

			$("#" + options.id).on("hidden.bs.modal", function(elem) {
				if ($("#" + options.id).hasClass("fade")) {
					$("#" + options.id).remove();
				}
			}); //Self-destructs, only if it contains the class fade (otherwise hides in favour of a sub modal)

			var $btn = $("." + options.btn_class, "#" + options.id);
			$btn.click(function() {
				if ($("#" + options.id).has("form")) {
					if (!Validator.validateForm($("form", "#" + options.id)[0])) {
						return false;
					}
					try {
						if (typeof options.onaction !== "undefined") {
							$btn.button("loading");
							options.onaction(options.id);
						}
						else if (options.save_form) {
							var $form = $("form", "#" + options.id);
							if ($form.size() == 0) {
								$("#" + options.id).modal("hide");
							}
							else {
								$btn.button("loading");
								$form.on("submit", function () {
									return false;
								}).ajaxSubmit({
									success: function (data) {
										$btn.button("complete").addClass("btn-success disabled");
										setTimeout(function () {
											if (typeof options.onsubmitted !== "undefined") {
												options.onsubmitted(options.id, data);
											}
											$("#" + options.id).modal("hide");
										}, 200);
									},
									error: function (e) {
										$btn.button('reset');
										if (typeof options.onerror !== "undefined") {
											options.onerror(options.id, e.status);
										}
									}
								});
							}
						}
						else {
							$("#" + options.id).modal("hide");
						}

					}
					catch(exception) {}
					finally {
						return false;
					}
				}
			});
			if (typeof options.oncreated !== "undefined") {
				options.oncreated(options.id);
			}
		}});
	}

	return {
		create: create
	};

})(jQuery);


/* pageeditor.js */

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
		showAddEditPage("put", pageId);
	}

	function showAddMainpage() {
		showAddEditPage("put", "");
	}

	function showEditPage() {
		showAddEditPage("post");
	}

	function showAddEditPage(method, parentId) {
		var titleId = (method === "put") ? "add_page" : "edit_page";
		Modal.create({
			title: Locale.str("system", titleId),
			oncreated: function(modalId) {
				var url = "__api__/pages/";
				url += (method === "post") ? pageId : "new";
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
				});
			},
			onsubmitted: function(modalId, data) {
				var url = "";
				if (parentId !== "") {
					url = document.location.toString();
					url = url.slice(0, url.indexOf("#"));
				}
				else {
					url = $("base").attr("href");
				}
				url = url.replace(/\/[^\/]*$/, "") + "/" + encodeURIComponent(data.title) + "#editing";
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
		Modal.create({
			title: Locale.str("system", "edit_view"),
			modal_large: true,
			oncreated: function(modalId) {
				var viewId = getViewIdFromView(viewObj);
				var url = "__api__/pages/" + pageId + "/view/" + viewId;
				$("#" + modalId).modal("show");
					$.getJSON(url, function(data) {
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
				});
			},
			onsubmitted: function(modalId, data) {
				location.reload();
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
				$("#" + modalId).modal("show");
			},
			onsubmitted: function(modalId, data) {
				$(viewObj).remove();
			}
		});
	}


	function addSubview(templateid, path) {
		var url = "__api__/pages/" + pageId + "/views/?_method=put&template=" + templateid;
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


/* texteditor.js */

/* global jQuery:false */
/* global Validator:false */
/* global Locale:false */
/* global Mustache:false */
/* global SelectFile:false */

var TextEditor = (function($) {
	"use strict";

	var parentModalId = "";

	function init(textareaSelector, parentModal) {
		addToolbar(textareaSelector, parentModal.replace(/^#/, ""));
	}

	var newVar = {
		"bold": {"icon": "fa-bold", "method": function (text, os) { return executeActionSimple("b", text, os); }},
		//"underline": {"icon": "icon-underlined", "method": function (text) { return executeActionSimple("u", text, os) }},
		"italic": {"icon": "fa-italic", "method": function (text, os) { return executeActionSimple("i", text, os); }},
		"divider 1": "divider",
		"ol": {"icon": "fa-list-ol", "method": function (text, os) { return executeActionSimple("list", text, os, {addNewlines: true}); }},
		"ul": {"icon": "fa-list-ul", "method": function (text, os) { return executeActionSimple("bullets", text, os, {addNewlines: true}); }},
		"divider 2": "divider",
		"email": {"icon": "fa-envelope", "method": function (text, os) { return executeActionEmail(text, os); }},
		"url": {"icon": "fa-link", "method": function (text, os) { return executeActionUrl(text, os); }},
		"video": {"icon": "fa-film", "method": function (text, os) { return executeActionVideo(text, os); }},
		"divider 3": "divider",
		"img": {"icon": "fa-picture-o", "method": function (text, os) { return executeActionImage(text, os); }},
		"file": {"icon": "fa-file", "method": function (text, os) { return executeActionFile(text, os); }}
	};
	var buttons = newVar;

	function addToolbar(textareaSelector, parentModal) {
		var html = "<div class='texteditor_toolbar' data-selector='" + textareaSelector + "' " +
								"data-parent-modal='" + parentModal + "' style='padding-bottom: 10px;'>";
		html += "<div class='btn-group'>";
		$.each(buttons, function (index, object) {
			if (object === "divider") {
				html += "</div><div class='btn-group'>";
			}
			else {
				var icon = "<span class='fa " + object.icon + "'></span>";
				html += "<div class='btn btn-default' data-action='" + index + "'>" + icon + "</div>";
			}
		});
		html += "</div></div>"; //btn-group and texteditor_toolbar

		$(html).insertBefore(textareaSelector).find(".btn").on("click", function () {
			var action = $(this).attr("data-action");
			TextEditor.executeAction(textareaSelector, action);
		});

		$(textareaSelector).css("width", "100%");
	}

	function executeAction(textareaSelector, action) {
		parentModalId = $(".texteditor_toolbar", $(textareaSelector).parent()).attr("data-parent-modal");
		buttons[action].method(getText(textareaSelector), function(text) {
			setText(textareaSelector, text);
		});
	}

	function getText(textareaSelector) {
		return $(textareaSelector).textrange("get", "text");
	}

	function setText(textareaSelector, selectedText) {
		$(textareaSelector).textrange("replace", selectedText);
	}

	function showModal(title, templateId, data, onSuccess) {
		Modal.create({
			title: title,
			fade: false,
			oncreated: function(modalId) {
				var template = $("#" + templateId).html();
				data = $.extend({}, data, Locale.getViewsStrings(["system"]));
				data.urid = UIDGenerator.get();
				var html = Mustache.render(template, data);
				$(".modal-body", "#" + modalId).html(html);

				$("#" + parentModalId).removeClass("fade").one("hidden.bs.modal",function () {
					$("#" + modalId).one("hidden.bs.modal",function () {
						$("#" + parentModalId).modal("show");
					}).modal("show");
				}).one("shown.bs.modal",function () {
					$("#" + parentModalId + ", .modal-backdrop").addClass("fade");
				}).modal("hide");
			},
			onaction: function(modalId) {
				var values = {};
				$.each($("form", "#" + modalId).serializeArray(), function(i, field) {
					values[field.name] = field.value;
				});
				onSuccess(values);
				$("#" + modalId).modal("hide");
			}
		});
	}

	function executeActionSimple(tag, text, onSuccess, options) {
		if (options === undefined) {
			options = {};
		}
		if (options.addNewlines) {
			text = "\n" + text;
		}
		text = "[" + tag + "]" + text + "[/" + tag + "]";
		if (options.addNewlines) {
			text += "\n";
		}
		onSuccess(text);
	}

	function executeActionEmail(text, onSuccess) {
		var data = {};
		var isEmail = Validator.isEmail({value: text});
		data.email = isEmail ? text : "";
		data.visible_text = isEmail ? "" : text;
		showModal(Locale.str('system', 'texteditor_modal_email'), 'template-texteditor-email', data, function (values) {
			var ubb = (values.visible_text === "") ? "[email]" + values.email + "[/email]" : "[email=" + values.email+ "]" + values.visible_text + "[/email]";
			onSuccess(ubb);
		});
	}

	function executeActionUrl(text, onSuccess) {
		var data = {};
		var isUrl = Validator.isUrl({value: text});
		data.url = isUrl ? text : "";
		data.visible_text = isUrl ? "" : text;
		showModal(Locale.str('system', 'texteditor_modal_url'), 'template-texteditor-url', data, function (values) {
			var ubb = (values.visible_text === "") ? "[url]" + values.url + "[/url]" : "[url=" + values.url + "]" + values.visible_text + "[/url]";
			onSuccess(ubb);
		});
	}

	function executeActionVideo(text, onSuccess) {
		var data = {};
		data.url = (Validator.isUrl({value: text})) ? text : "";
		showModal(Locale.str('system', 'texteditor_modal_video'), 'template-texteditor-video', data, function (values) {
			onSuccess("[video]" + values.video + "[/video]");
		});
	}


	function executeActionImage(text, onSuccess) {
		Locale.ensureLoaded('files', {loaded: function () {
			var url = "views/files/coworkers/select_file.mustache?static_only=true";
			$.get(url, {cache: true}, function (template) {
				var html = Mustache.to_html(template, Locale.getViewsStrings(["system", "files"]));
				$("body").append("<div id='texteditor_selectfile'></div>");
				$("#texteditor_selectfile").html(html);
				SelectFile.show({multi: false, parentModalId: parentModalId,
					confirmed: function (ids) {
						onSuccess("[img]" + ids.join() + "[/img]");
					},
					hidden: function () {
						$("#texteditor_selectfile").remove();
					}
				});
			});
		}});
	}

	function executeActionFile(text, onSuccess) {
		Locale.ensureLoaded('files', {loaded: function () {
			var url = "views/files/coworkers/select_file.mustache?static_only=true";
			$.get(url, {cache: true}, function (template) {
				var html = Mustache.to_html(template, Locale.getViewsStrings(["system", "files"]));
				$("body").append("<div id='texteditor_selectfile'></div>");
				$("#texteditor_selectfile").html(html);
				SelectFile.show({multi: false, parentModalId: parentModalId,
					confirmed: function (ids) {
						var fileId = ids.join();
						var name = SelectFile.getCachedFilename(fileId);
						onSuccess("[url=__api__/files/" + fileId + "/download]" + name + "[/url]");
					},
					hidden: function () {
						$("#texteditor_selectfile").remove();
					}
				});
			});
		}});
	}

	return {
		init: init,
		executeAction: executeAction
	};

})(jQuery);


/* uridgenerator.js */

/*

 Generator for Unique ID's, which are usefull for URID's (Unique Render Identifiers),
 used in Mustache files.

	Based on http://dbj.org/dbj/?p=76

*/

var UIDGenerator = (function () {

	"use strict";

	function get() {
		var uid = setTimeout(function() { clearTimeout(uid); }, 0);
		return uid;
	}

	return { get: get };

})();


/* validator.js */

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


