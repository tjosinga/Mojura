var FilesView;
FilesView = (function ($) {

	var uploading = false;

	var currentFolderId = "root";
	var previousFolderId = "root";

	function setCurrentFolderId(id, silent) {
		if (this.currentFolderId != id) {
			this.previousFolderId = this.currentFolderId;
			this.currentFolderId = id;
			if (!silent) this.refresh();
		}
	}

	function refresh() {
		//should only refresh the files/folders list!!! Just a workaround.
		$("#files_folders_container").html("<div class='loading'></div>");
		id = this.currentFolderId;
		if ((id == "") || (id === undefined)) id = "root";
		url = "__api__/files/folders/" + id;

		$.getJSON(url, function (data) {
			template = $("#template_files_folders_container").html();
			data.may_maintain = (data.rights.allowed.update);
			data.is_base_folder = (id == "root");
			data.has_subfolders = (data.subfolders.length > 0);
			data.has_files = (data.files.length > 0);
			for (i = 0; i < data.files.length; i++) {
				data.files[i].is_image = (data.files[i].mime_type !== undefined) && (data.files[i].mime_type.slice(0, 5) == "image");
				data.files[i].is_archive = (data.files[i].mime_type !== undefined) && (data.files[i].mime_type == "application/zip")
			}
			html = Mustache.to_html(template, data);
			if (history.pushState) {
				new_location = window.location.toString();
				new_location = new_location.replace(/\?folderid=\w+/, "");
				if ((data.id !== undefined) && (data.id !== null))
					new_location += "?folderid=" + data.id;
				history.pushState({}, document.title, new_location);
			}
			$("#files_folders_container").html(html);
		});
	}

	function loadForm(modalId, templateId, url, method) {
		id = this.currentFolderId;
		if ((id == "") || (id === undefined)) id = "root";
		$(".btn-primary, .btn-danger", modalId).button("reset");
		$(".modal-body", modalId).html("<div class='loading'></div>");
		$.getJSON(url, function (data) {
			if (data.id === null) data.id = "";
			template = $(templateId).html();
			html = Mustache.to_html(template, data);
			$(".modal-body", modalId).html(html);
			options = {
				success: function () {
					$(modalId).modal("hide");
					FilesView.refresh();
				}
			};
			$("form", modalId).ajaxForm(options);
			$("input[name=_method]", modalId).val(method);
			$("input[name=folderid], input[name=parentid]", modalId).val(id);
		});
	}


	return {
		setCurrentFolderId: setCurrentFolderId,
		refresh: refresh,
		loadForm: loadForm
	};

})(jQuery);