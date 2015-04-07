/* global jQuery:false */
/* global Mustache:false */


var FilesView = (function ($) {
	"use strict";

	var uploading = false;

	var currentFolderId = "root";
	var previousFolderId = "root";

	function setCurrentFolderId(id, silent) {
		if (currentFolderId !== id) {
			previousFolderId = currentFolderId;
			currentFolderId = id;
			if (!silent) {
				refresh();
			}
		}
	}

	function getSettings() {
		var jSettings = $(".files-settings", "#files_folders_container");
		var settings = jSettings.data();
		return settings;
	}

	function refresh() {
		//should only refresh the files/folders list!!! Just a workaround.
		var settings = getSettings();
		$("#files_folders_container").html("<div class='loading'></div>");
		var id = currentFolderId;
		id = ((id !== "") && (typeof id !== "undefined")) ? id : "root";
		var url = "__api__/files/folder/" + id;

		$.getJSON(url, function (data) {
			var template = $("#template_files_folders_container").html();
			$.extend(data, settings);
			data.may_maintain = (data.rights.allowed.update);
			data.is_base_folder = (!data.id) || (data.id === settings.base_folderid);
			data.has_subfolders = (data.subfolders.length > 0);
			data.has_files = (data.files.length > 0);
			for (var i = 0; i < data.files.length; i++) {
				//noinspection JSUnresolvedVariable
				data.files[i].is_image = (typeof data.files[i].mime_type !== "undefined") && (data.files[i].mime_type !== null) && (data.files[i].mime_type.slice(0, 5) === "image");
				//noinspection JSUnresolvedVariable
				data.files[i].is_archive = (typeof data.files[i].mime_type !== "undefined") && (data.files[i].mime_type !== null) && (data.files[i].mime_type === "application/zip");
			}
			var html = Mustache.to_html(template, data);
			if (history.pushState) {
				var new_location = window.location.toString();
				new_location = new_location.replace(/\?folderid=\w+/, "");
				if ((data.id !== undefined) && (data.id !== null)) {
					new_location += "?folderid=" + data.id;
				}
				history.pushState({}, document.title, new_location);
			}
			$("#files_folders_container").html(html);
		});
	}

	function addFile() {
		addEditFile("post", currentFolderId);
	}

	function editFile(fileid) {
		addEditFile("put", fileid);
	}

	function addEditFile(method, id) {
		var titleId = (method === "post") ? "action_add_file" : "action_edit_file";
		Modal.create({
			title: Locale.str("files", titleId),
			id: 'fileAddEditModal',
			oncreated: function(modalId, onLoaded) {
				var url = "__api__/files/";
				url += (method === "put") ? id : "new";
				$("#" + modalId).modal("show");
				$.getJSON(url, function(data) {
					var template = $("#template-files-add-edit-file").html();
					data = $.extend({}, data, Locale.getViewsStrings(["system", "files"]));
					if (method === "post") {
						data.folderid = id;
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
				refresh();
			}
		});
	}

	function deleteFile(fileid) {
		Modal.create({
			title: Locale.str("files", "action_delete_file"),
			btn_action: Locale.str("system", "delete"),
			btn_class: 'btn-danger',
			oncreated: function(modalId) {
				var template = $("#template-files-delete-file").html();
				var data = Locale.getViewsStrings(["system", "files"]);
				data.id = fileid;
				data.urid = UIDGenerator.get();
				var html = Mustache.render(template, data);
				$(".modal-body", "#" + modalId).html(html);
			},
			onsubmitted: function(modalId, data) {
				refresh();
			}
		});
	}

	function extractFile(fileid) {
		Modal.create({
			title: Locale.str("files", "action_extract_file"),
			btn_action: Locale.str("files", "action_extract"),
			oncreated: function(modalId) {
				var template = $("#template-files-extract-file").html();
				var data = Locale.getViewsStrings(["system", "files"]);
				data.id = fileid;
				data.urid = UIDGenerator.get();
				var html = Mustache.render(template, data);
				$(".modal-body", "#" + modalId).html(html);
			},
			onsubmitted: function(modalId, data) {
				refresh();
			}
		});
	}

	function addFolder() {
		addEditFolder("post", currentFolderId);
	}

	function editFolder(folderid) {
		addEditFolder("put", folderid);
	}

	function addEditFolder(method, id) {
		var titleId = (method === "post") ? "action_add_folder" : "action_edit_folder";
		Modal.create({
			title: Locale.str("files", titleId),
			oncreated: function(modalId, onLoaded) {
				var url = "__api__/files/folder/";
				url += (method === "put") ? id : "new";
				$("#" + modalId).modal("show");
				$.getJSON(url, function(data) {
					var template = $("#template-files-add-edit-folder").html();
					data = $.extend({}, data, Locale.getViewsStrings(["system", "files"]));
					if (method === "post") {
						data.parentid = id;
						data.url = "__api__/files/folders";
					} else {
						data.url = "__api__/files/folder/" + id;
					}
					data.method = method;
					data.urid = UIDGenerator.get();
					data.simple_rights_visible = ((data.rights.right & 4) > 0);
					var partials = {"rights-controls": $("#template-rights-controls").html() };
					var html = Mustache.render(template, data, partials);
					$(".modal-body", "#" + modalId).html(html);
					onLoaded();
				});
				return true;
			},
			onsubmitted: function(modalId, data) {
				refresh();
			}
		});
	}

	function deleteFolder(folderid) {
		Modal.create({
			title: Locale.str("files", "action_delete_folder"),
			btn_action: Locale.str("system", "delete"),
			btn_class: 'btn-danger',
			oncreated: function(modalId) {
				var template = $("#template-files-delete-folder").html();
				var data = Locale.getViewsStrings(["system", "files"]);
				data.id = folderid;
				data.urid = UIDGenerator.get();
				var html = Mustache.render(template, data);
				$(".modal-body", "#" + modalId).html(html);
			},
			onsubmitted: function(modalId, data) {
				refresh();
			}
		});
	}


	return {
		setCurrentFolderId: setCurrentFolderId,
		refresh: refresh,
		addFile: addFile,
		editFile: editFile,
		deleteFile: deleteFile,
		extractFile: extractFile,
		addFolder: addFolder,
		editFolder: editFolder,
		deleteFolder: deleteFolder
	};

})(jQuery);