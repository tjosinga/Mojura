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
			oncreated: function (id, onLoaded) {
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
					onLoaded();
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


/* alert.js */

var Alert = (function() {

	"use strict";

	var template;

	function create(options) {
		options.type = (typeof options.type !== "undefined") ? options.type : "danger";
		options.dismissable = (typeof options.dismissable !== "undefined") ? options.dismissable : true;
		if (typeof options.title === "undefined") {
			options.title = Locale.str("system", "alert_title_" + options.type)
		}
		if (typeof template === "undefined") {
			template = $("#template-alert").html();
		}
		return Mustache.render(template, options);
	}

	return {
		create: create
	}

})();


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


/* lightbox.js */

var LightBox = (function($) {

	"use strict";

	var groups = {};
	var groupIndexes = {};
	var currentGroup;
	var $current;
	var $dialog;
	var $content;
	var template;

	function add(group, url, options) {
		groups[group] = groups[group] || [];
		groupIndexes[group] = groupIndexes[group] || 0;
		options = options || {};
		options.url = url;
		options.type = "image";
		options.name = "";
		options.description = "";
		groups[group].push(options);
	}

	function show(group, index) {
		if (typeof groups[group] === "undefined") {
			return;
		}
		currentGroup = group;
		template = template || $("#template-lightbox").html();
		if (typeof index === "number") {
			groupIndexes[currentGroup] = index;
		} else {
			groupIndexes[currentGroup] = getIndexByUrl(index);
		}

		var html = Mustache.to_html(template, { group: currentGroup });
		$("body").append(html);
		$current = $("#lightbox-" + currentGroup);
		$content = $(".lightbox-content", $current);
		$dialog = $(".lightbox-dialog", $current);

		var onKeyUp = function(e) {
			if (e.keyCode === 27) {
				$current.modal("hide");
			} else if (e.keyCode === 37) {
				previous();
			} else if (e.keyCode === 39) {
				next();
			}
		};

		$current.on("shown.bs.modal", function() {
			$(window).on("resize", centerContent);
			$(document).on("keyup", onKeyUp);
		});

		$current.on("hide.bs.modal", function() {
			$(window).off("resize", centerContent);
			$(document).off("keyup", onKeyUp);
		});

		$current.on("hidden.bs.modal", function() {
			$current.remove();
		});

		$(".lightbox-left, .lightbox-right", $current).toggleClass("hidden", groups[currentGroup].length < 2);

		showMedia();

		$current.modal("show");
	}

	function centerContent() {
		$content.height("auto");
		if ($(window).height() <= $dialog.height()) {
			$content.height($(window).height());
		}
	}

	function showMedia() {
		var i = groupIndexes[currentGroup] || 0;
		var item = groups[currentGroup][i];
		$(".lightbox-content > *", $current).addClass("hidden");
		if (item.type === "image") {
			$(".lightbox-image", $current).load(centerContent).attr("src", item.url).removeClass("hidden");
		}
	}

	function step(steps) {
		var count = groups[currentGroup].length;
		groupIndexes[currentGroup] = (groupIndexes[currentGroup] + count + steps) % count;
		showMedia(currentGroup);
	}

	function previous() {
		step(-1);
	}

	function next() {
		step(1);
	}

	function getIndexByUrl(url) {
		for (var i in groups[currentGroup]) {
			if (typeof groups[currentGroup][i] !== "undefined") {
				var item = groups[currentGroup][i];
				if (item.url === url) {
					return Number(i);
				}
			}
		}
		return 0;
	}

	function clear(group) {
		groups[group] = [];
		groupIndexes[group] = 0;
	}

	return {
		add: add,
		show: show,
		previous: previous,
		next: next,
		clear: clear
	};

})(jQuery);


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
			error: function () {
				if ((typeof options !== 'undefined') && (typeof options.loaded !== 'undefined') && (options.breakOnFail !== true)) {
					options.loaded();
				}
			},
			fail: function () {
				window.console.log("Error fetching " + url);
				if (typeof options.error !== 'undefined') {
					options.error();
				}
				if ((typeof options !== 'undefined') && (typeof options.loaded !== 'undefined') && (options.breakOnFail !== true)) {
					options.loaded();
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
	var $modal;
	var options;
	var $form;
	var $btn;

	function create(opts) {
		options = opts;
		Locale.ensureLoaded("system", { loaded: function() {
			var template = $("#template-modal").html();
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

			$modal = $("#" + options.id);
			$modal.on("hidden.bs.modal", function (elem) {
				if ($modal.hasClass("fade")) {
					$modal.remove();
				}
			}); //Self-destructs, only if it contains the class fade (otherwise hides in favour of a sub modal)

			if ((!options.oncreated) || (!options.oncreated(options.id, onLoaded))) {
				onLoaded();
			}
		}});
	}

	function onLoaded() {
		$btn = $("." + options.btn_class, $modal);
		$form = $("form", $modal);
		var submitFormOnClick = (options.save_form) && ($form.size() > 0);

		if (submitFormOnClick) {
			$form.on("submit", onSubmit);
		}

		$btn.click(function () {
			if (submitFormOnClick) {
				onSubmit();
			} else if (typeof options.onaction !== "undefined") {
				$btn.button("loading");
				try {
					options.onaction(options.id);
				} catch (exception) {
					//TODO: Better error handling
				}
			} else {
				$("#" + options.id).modal("hide");
			}
		});
		$modal.modal("show");
	}

	function onSubmit() {
		$form = $("form", $modal);
		if (!Validator.validateForm($form[0])) {
			return false;
		}
		$btn.button("loading");
		$form.ajaxSubmit({
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
		return false;
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
				document.location = url.replace(/%20/g, "+");
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

	function prepareNodeForSitemap(node) {
		if (typeof node.children !== "undefined") {
			node.has_children = (node.children.length > 0);
			for (var x in node.children) {
				prepareNodeForSitemap(node.children[x]);
			}
		} else {
			node.children = false
		}
		node.is_base = false;
	}

	function showSitemap() {
		Modal.create({
			title: Locale.str("system", "sitemap_view"),
			btn_action: Locale.str("system", "close"),
			btn_cancel: false,
			modal_large: true,
			save_form: false,
			oncreated: function(modalId, onLoaded) {
				var url = "__api__/pages/?use_locale=false";
				$("#" + modalId).modal("show");
				$.getJSON(url, function(children) {
					var template = $("#template-sitemap-view").html();
					var data = Locale.getViewsStrings(["system"]);
					data.children = children;
					data.pageid = pageId;
					data.urid = UIDGenerator.get();
					prepareNodeForSitemap(data);
					data.is_base = true;
					var html = Mustache.render(template, data, {"sitemap": template});
					$(".modal-body", "#" + modalId).html(html);
					SitemapView.register("sitemap-" + data.urid).initialize("sitemap-" + data.urid, pageId);
					onLoaded();
				});
				return true;
			},
			onaction: function(modalId) {
				var url = "__api__/pages?user_locale=false&path_pageid=" + pageId;
					$.getJSON(url, function(data) {
						var redirect = "";
						for (var x in data) {
							redirect += encodeURIComponent(data[x].title) + '/';
						}
						document.location = redirect.slice(0, -1).replace(/%20/g, "+") + "#editing";
				});

				$("#" + modalId).modal("hide");
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
		addSubview: addSubview,
		showSitemap: showSitemap
	};

})(jQuery);


/* pageeditor.min.js */

var PageEditor=(function(g){var d="";var n=[];function o(s,t){d=s;n=t;var r="";g(".page-content-parts").sortable({handle:".editable .sortable-handle",itemSelector:".editable",vertical:true,nested:true,placeholder:"<i class='fa fa-chain text-danger'></i>",containerSelector:".page-content-parts, .view-subviews",onDragStart:function(v,u,w){r=i(v[0])},onDrag:function(v,u,w){v.css(u);w(v,u)},onDrop:function(v,u,x){x(v,u);var w=i(v[0]);if(w!==r){window.alert("moved")}}})}function b(){g(".btn-edit-page").toggleClass("hidden");g(".view-admin").toggleClass("hidden").parent().toggleClass("editable");var r=window.location.toString().replace(/#+editing/,"");if(g(".btn-edit-page").is(":visible")){r+="#editing"}history.pushState({},document.title,r)}function a(){m("post",d)}function p(){m("post","")}function j(){m("put")}function m(t,s){var r=(t==="post")?"add_page":"edit_page";Modal.create({title:Locale.str("system",r),oncreated:function(u,w){var v="__api__/pages/";v+=(t==="put")?d:"new";g("#"+u).modal("show");g.getJSON(v,function(A){var z=g("#template-pageview-addedit-page").html();A=g.extend({},A,Locale.getViewsStrings(["system"]));if(typeof s!=="undefined"){A.parentid=s}A.method=t;A.urid=UIDGenerator.get();A.simple_rights_visible=((A.rights.rights&4)>0);var y={"rights-controls":g("#template-rights-controls").html()};var x=Mustache.render(z,A,y);g(".modal-body","#"+u).html(x);w()});return true},onsubmitted:function(u,x){var v="";if(typeof x.breadcrumbs!=="undefined"){for(var w=0;w<x.breadcrumbs.length;w++){v+=encodeURI(x.breadcrumbs[w].title)+"/"}}v+=encodeURI(x.title)+"#editing";document.location=v.replace(/%20/g,"+")}})}function l(){Modal.create({title:Locale.str("system","delete_page"),btn_action:Locale.str("system","delete"),btn_class:"btn-danger",oncreated:function(r){var t=g("#template-pageview-delete-page").html();var u=Locale.getViewsStrings(["system"]);u.pageid=d;u.urid=UIDGenerator.get();var s=Mustache.render(t,u);g(".modal-body","#"+r).html(s);g("#"+r).modal("show")},onsubmitted:function(r,t){var s=document.location.toString();document.location=s.slice(0,s.lastIndexOf("/"))}})}function i(s){var r="";g(s).parents(".view").each(function(t,u){r=g(u).index().toString()+","+r});return r+g(s).index()}function k(s){var u="";var t={};var r="";Modal.create({title:Locale.str("system","edit_view"),modal_large:true,oncreated:function(v,x){r=i(s);var w="__api__/pages/"+d+"/view/"+r;g("#"+v).modal("show");g.getJSON(w,function(B){u=B.view;t=g.extend({},B.settings);var A=g("#template-pageview-edit-view").html();B=g.extend({},B,Locale.getViewsStrings(["system"]));B.urid=UIDGenerator.get();B.pageid=d;B.views=n;B.available_col_spans=[];for(var z=1;z<=12;z++){B.available_col_spans.push(z)}B.available_col_offsets=[];for(z=0;z<=12;z++){B.available_col_offsets.push(z)}var y=Mustache.render(A,B);g(".modal-body","#"+v).html(y);e("#"+v,B);x()});return true},onsubmitted:function(v,w){if((u!==w.view)||(JSON.stringify(t)!==JSON.stringify(w.settings))){location.reload()}else{g(s).children(".view-text").html(w.content.html)}}})}function e(s,u){g("select[name=view]",s).change(function(){var v=g(this).val();if(v===""){g(".view-settings",s).html("");g(".view_texteditor textarea",s).removeClass("small");return}g(".view_texteditor textarea",s).addClass("small");g(".view-settings",s).html("<div class='loading'></div>");Locale.ensureLoaded(v,{loaded:function(){var w="views/"+v+"/coworkers/view_edit_settings.mustache?static_only=true";g.get(w,{cache:false},function(y){var z=Locale.getViewsStrings(["system",v]);u.urid=UIDGenerator.get();u.pageid=d;if(typeof u.settings==="undefined"){u.settings={}}u.settings.modalId=s.replace(/^#/,"");for(var A in z){if(z.hasOwnProperty(A)){u.settings[A]=z[A]}}var x=Mustache.to_html(y,u.settings);g(".view-settings",s).html(x)}).error(function(){g(".view-settings",s).html("")})}})}).val(u.view).trigger("change");g("select[name=col_span]",s).val(u.col_span);g("select[name=col_offset]",s).val(u.col_offset);g("select[name=row_offset]",s).val(u.row_offset);g("select[name=view] option",s).removeAttr("disabled");if(u.col_span<12){var r=[];for(var t=12;t>u.col_span;t--){r.push(".min-col-span"+t)}g(r.join(",")).attr("disabled","disabled")}TextEditor.init("#content_"+u.urid,s)}function q(r){Modal.create({title:Locale.str("system","delete_view"),btn_action:Locale.str("system","delete"),btn_class:"btn-danger",oncreated:function(s){var u=g("#template-pageview-delete-view").html();var v=Locale.getViewsStrings(["system"]);v.pageid=d;v.viewid=i(r);v.urid=UIDGenerator.get();var t=Mustache.render(u,v);g(".modal-body","#"+s).html(t)},onsubmitted:function(s,t){g(r).remove()}})}function h(s){if(typeof s.children!=="undefined"){s.has_children=(s.children.length>0);for(var r in s.children){h(s.children[r])}}else{s.children=false}s.is_base=false}function c(){Modal.create({title:Locale.str("system","sitemap_view"),btn_action:Locale.str("system","close"),btn_cancel:false,modal_large:true,save_form:false,oncreated:function(r,t){var s="__api__/pages/?use_locale=false";g("#"+r).modal("show");g.getJSON(s,function(v){var w=g("#template-sitemap-view").html();var x=Locale.getViewsStrings(["system"]);x.children=v;x.pageid=d;x.urid=UIDGenerator.get();h(x);x.is_base=true;var u=Mustache.render(w,x,{sitemap:w});g(".modal-body","#"+r).html(u);SitemapView.register("sitemap-"+x.urid).initialize("sitemap-"+x.urid,d);t()});return true},onaction:function(r){var s="__api__/pages?user_locale=false&path_pageid="+d;g.getJSON(s,function(u){var v="";for(var t in u){v+=encodeURIComponent(u[t].title)+"/"}document.location=v.slice(0,-1).replace(/%20/g,"+")+"#editing"});g("#"+r).modal("hide")}})}function f(r,t){var s="__api__/pages/"+d+"/views/?_method=post&template="+r;if((t!==undefined)&&(t!=="")){s+="&parentid="+t}g.getJSON(s,function(u){location.reload()})}return{init:o,togglePageAdmins:b,showAddSubpage:a,showAddMainpage:p,showEditPage:j,showDeletePage:l,showEditView:k,showDeleteView:q,addSubview:f,showSitemap:c}})(jQuery);


/* taglistinput.js */

var TagListInput = (function($) {

	'use strict';

	function init(id) {

		id = ((typeof id === "undefined") || (id === "")) ? ".tag-list-wrapper" : "#" + id;
		var $wrappers = $(id);

		$wrappers.each(function() {
			var $wrapper = $(this);

			if ($wrapper.children(".tag-list-ui").size() > 0) return;

			var $sourceInput = $wrapper.children("input");
			var values = $sourceInput.hide().val().split(",");
			$wrapper.append("<div class='tag-list-ui'><input type='text' style='display: inline; border: 0' /></div>");
			var $ui = $wrapper.children(".tag-list-ui");
			var $input = $ui.children("input");
			for (var i in values) {
				addTag($sourceInput, $input, values[i]);
			}

			$input.keypress(function (e) {
				if ((e.keyCode === 13) || (e.keyCode === 44) || (!$input.is(":focus"))) {
					var newTag = $input.val();
					$input.val("");
					addTag($sourceInput, $input, newTag);
					$sourceInput.val($sourceInput.val() + ", " + newTag);
					return false;
				}
			});

			$input.keydown(function (e) {
				var value = $input.val();
				if ((e.keyCode === 8) && (value === "")) {
					var $lastTag = $input.siblings().last();
					if ($lastTag.hasClass("selected")) {
						$lastTag.children("div").click();
					} else {
						$lastTag.addClass("selected");
					}
				} else {
					$input.siblings(".selected").removeClass("selected");
				}
			});

			$input.focus(function (e) {
				$wrapper.addClass("selected");
			});

			$input.blur(function (e) {
				$input.trigger("keypress");
				$wrapper.removeClass("selected");
				$ui.children(".selected").removeClass("selected");
			});

			$wrapper.click(function (e) {
				$input.focus();
			});
		});
	}

	function addTag($sourceInput, $input, tag) {
		tag = tag.trim();
		if (tag === "") return;
		var $tag = $("<span></span>");
		$tag.addClass("tag-list-item").text(tag).attr("data-tag", tag);
		var $closeBtn = $("<div style='cursor: pointer; padding-left: 3px;' aria-hidden='true'>&times;</div>");
		$closeBtn.addClass("delete-btn");
		$closeBtn.click(function (e) {
			$tag.remove();
			tagListToInput($sourceInput, $input);
		});
		$tag.append($closeBtn);
		$input.before($tag);
	}

	function tagListToInput($sourceInput, $input) {
		var s = "";
		$input.siblings().each(function(index) {
			if (s !== "") s += ", ";
			s += $(this).attr("data-tag");
		});
		$sourceInput.val(s);
	}

	return {
		init: init
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
		var filter = /^([a-zA-Z0-9_\.\-])+@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
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


