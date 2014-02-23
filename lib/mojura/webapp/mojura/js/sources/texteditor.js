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
				data.uid = UIDGenerator.get();
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