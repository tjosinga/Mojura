var TextEditor = (function($) {

	function init(textareaSelector) {
		addToolbar(textareaSelector);
	}

	var newVar = {
		"bold": {"icon": "icon-bold", "method": function (text, os) { return executeActionSimple("b", text, os) }},
		//"underline": {"icon": "icon-underlined", "method": function (text) { return executeActionSimple("u", text, os) }},
		"italic": {"icon": "icon-italic", "method": function (text, os) { return executeActionSimple("i", text, os) }},
		"divider 1": "divider",
		"ol": {"icon": "icon-list-ol", "method": function (text, os) { return executeActionSimple("list", text, os, {addNewlines: true}) }},
		"ul": {"icon": "icon-list-ul", "method": function (text, os) { return executeActionSimple("bullets", text, os, {addNewlines: true}) }},
		"divider 2": "divider",
		"email": {"icon": "icon-envelope", "method": function (text, os) { return executeActionEmail(text, os) }},
		"url": {"icon": "icon-link", "method": function (text, os) { return executeActionUrl(text, os) }},
		"video": {"icon": "icon-film", "method": function (text, os) { return executeActionVideo(text, os) }},
		"divider 3": "divider",
		"img": {"icon": "icon-picture", "method": function (text, os) { return executeActionImage(text, os) }},
		"file": {"icon": "icon-file", "method": function (text, os) { return executeActionFile(text, os) }},
	};
	var buttons = newVar

	function addToolbar(textareaSelector) {
		loadModals();

		html = "<div class='texteditor_toolbar' data-selector='" + textareaSelector + "' style='padding-bottom: 10px;'>"
		html += "<div class='btn-group'>"
		$.each(buttons, function (index, object) {
			if (object == "divider")
				html += "</div><div class='btn-group'>";
			else {
				icon = "<i class='" + object["icon"] + "'></i>";
				html += "<div class='btn' data-action='" + index + "'>" + icon + "</div>";
			}
		});
		html += "</div></div>"; //btn-group and texteditor_toolbar

		$(html).insertBefore(textareaSelector).find(".btn").on("click", function () {
			textareaSelector = $(this).parents(".texteditor_toolbar").attr("data-selector");
			action = $(this).attr("data-action");
			TextEditor.executeAction(textareaSelector, action);
		});

		$(textareaSelector).css("width", "100%");
	}

	function loadModals() {
		if ($("#texteditor_modals").length == 0) {
			url = "mojura/views/texteditor_modals.mustache?static_only=true";
			$.get(url, {cache: false}, function (template) {
				html = Mustache.to_html(template, Locale.rawStrings(["system"]));
				$("body").append("<div id='texteditor_modals'>" + html + "</div>");
			});
		}
	}

	function executeAction(textareaSelector, action) {
		buttons[action]["method"](getText(textareaSelector), function(text) {
			setText(textareaSelector, text);
		});
	}

	function getText(textareaSelector) {
		return $(textareaSelector).textrange("get", "text");
	}

	function setText(textareaSelector, selectedText) {
		$(textareaSelector).textrange("replace", selectedText);
	}

	function showModal(popupClass, onSuccess) {
		$("#modalEditView").removeClass("fade").one("hidden",function () {
			$("#texteditor_modals ." + popupClass).one("hidden",function () {
				$("#modalEditView").modal("show");
			}).one("shown",function () {
					$("#texteditor_modals ." + popupClass + " .btn-primary").one("click", function () {
						onSuccess();
					});
				}).modal("show");
		}).one("shown",function () {
				$("#modalEditView, .modal-backdrop").addClass("fade");
			}).modal("hide");
	}

	function showModal(popupClass, onSuccess) {
		$("#modalEditView").removeClass("fade").one("hidden",function () {
			$("#texteditor_modals ." + popupClass).one("hidden",function () {
				$("#modalEditView").modal("show");
			}).one("shown",function () {
					$("#texteditor_modals ." + popupClass + " .btn-primary").one("click", function () {
						onSuccess();
					});
				}).modal("show");
		}).one("shown",function () {
				$("#modalEditView, .modal-backdrop").addClass("fade");
			}).modal("hide");
	}

	function executeActionSimple(tag, text, onSuccess, options) {
		if (options == undefined) options = {};
		if (options.addNewlines) text = "\n" + text;
		text = "[" + tag + "]" + text + "[/" + tag + "]";
		if (options.addNewlines) text += "\n";
		onSuccess(text);
	}

	function executeActionEmail(text, onSuccess) {
		email = "";
		visibleText = "";
		if (Validator.isEmail({value: text}))
			email = text;
		else
			visibleText = text;
		$(".texteditor-email-popup-modal input[name=email]").val(email);
		$(".texteditor-email-popup-modal input[name=visible_text]").val(visibleText);

		showModal("texteditor-email-popup-modal", function () {
			email = $(".texteditor-email-popup-modal input[name=email]").val();
			visibleText = $(".texteditor-email-popup-modal input[name=visible_text]").val();
			if (visibleText == "")
				ubb = email;
			else
				ubb = "[email=" + email + "]" + visibleText + "[/email]";
			onSuccess(ubb);
		});
	}

	function executeActionUrl(text, onSuccess) {
		url = "";
		visibleText = "";
		if (Validator.isUrl({value: text}))
			url = text;
		else
			visibleText = text;
		$(".texteditor-url-popup-modal input[name=url]").val(url);
		$(".texteditor-url-popup-modal input[name=visible_text]").val(visibleText);

		showModal("texteditor-url-popup-modal", function () {
			url = $(".texteditor-url-popup-modal input[name=url]").val();
			visibleText = $(".texteditor-url-popup-modal input[name=visible_text]").val();
			if (visibleText == "")
				ubb = "[url]" + url + "[/url]";
			else
				ubb = "[url=" + url + "]" + visibleText + "[/url]";
			onSuccess(ubb);
		});
	}

	function executeActionVideo(text, onSuccess) {
		url = (Validator.isUrl({value: text})) ? text : "";
		$(".texteditor-video-popup-modal input[name=url]").val(url);
		showModal("texteditor-video-popup-modal", function () {
			url = $(".texteditor-video-popup-modal input[name=url]").val();
			onSuccess("[video]" + url + "[/video]");
		});
	}


	function executeActionImage(text, onSuccess) {
		Locale.ensureLoaded('files', {loaded: function () {
			url = "views/files/coworkers/select_file.mustache?static_only=true";
			$.get(url, {cache: true}, function (template) {
				html = Mustache.to_html(template, Locale.rawStrings(["system", "files"]));
				$("body").append("<div id='texteditor_selectfile'></div>");
				$("#texteditor_selectfile").html(html);
				SelectFile.show({multi: false, parentModalId: "modalEditView",
					confirmed: function (ids) {
						fileId = ids.join();
						onSuccess("[img]" + fileId + "[/img]");
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
			url = "views/files/coworkers/select_file.mustache?static_only=true";
			$.get(url, {cache: true}, function (template) {
				html = Mustache.to_html(template, Locale.rawStrings(["system", "files"]));
				$("body").append("<div id='texteditor_selectfile'></div>");
				$("#texteditor_selectfile").html(html);
				SelectFile.show({multi: false, parentModalId: "modalEditView",
					confirmed: function (ids) {
						fileId = ids.join();
						name = SelectFile.getCachedFilename(fileId);
						onSuccess("[url=" + fileId + "]" + name + "[/url]");
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
	}

})(jQuery);