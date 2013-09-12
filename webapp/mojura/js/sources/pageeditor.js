var PageEditor = (function ($) {

	function togglePageAdmins() {
		$(".btn-edit-page").toggleClass("hide");
		$(".view-admin").toggleClass("hide").parent().toggleClass("editable");

		url = window.location.toString().replace(/#editing/, "");
		if ($(".btn-edit-page").is(":visible"))
			url += "#editing";

		history.pushState({}, document.title, url);
	};

	function showEditPage() {
		$("#modalEditPage").modal("show");
		old_title = $("input[name=title]", "#modalEditPage").val();
		$("form", "#modalEditPage").on("submit", function () {

			$(this).ajaxSubmit({success: function () {

				new_title = $("input[name=title]", "#modalEditPage").val();
				if (new_title != old_title) {
					pattern_old_title = encodeURIComponent(old_title).replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
					reg = new RegExp(pattern_old_title + "#", "g");
					url = document.location.toString().replace(reg, encodeURIComponent(new_title) + "#");
					history.pushState({}, document.title, url);
				}
				$("#modalEditPage").modal("hide");
				location.reload();
			}, error: function (request, errordata, errorObject) {
				alert(errorObject.toString());
			}});
		});
	};

	function showDeletePage() {
		pageid = $("input[name=pageid]", "#modalDeletePage").val();
		url = "__api__/pages/" + pageid;
		$("form", "#modalDeletePage").submit(function (form) {
			$.getJSON(url + "?_method=delete", function (data) {
				url = document.location.toString();
				document.location = url.slice(0, url.lastIndexOf("/"));
				$("#modalDeletePage").modal("hide");
			});
			return false;
		});
		$("#modalDeletePage").modal("show");
	};

	function showAddSubpage() {
		pageid = $("input[name=pageid]", "#modalDeletePage").val();
		html = $("#modalEditPage form").html();
		$("#modalAddSubpage form .elements").html(html);
		$("#modalAddSubpage form input[name=title]").val("");
		$("#modalAddSubpage").modal("show");
		$("form", "#modalAddSubpage").on("submit", function () {
			$(this).ajaxSubmit({success: function () {
				title = $("input[name=title]", "#modalAddSubpage").val();
				url = document.location.toString();
				url = url.slice(0, url.indexOf("#"));
				url += "/" + encodeURIComponent(title) + "#editing";
				$("#modalAddSubpage").modal("hide");
				document.location = url;
			}, error: function (request, errordata, errorObject) {
				alert(errorObject.toString());
			}});
		});
	};


	function getViewIdFromView(viewObj) {
		result = "";
		$(viewObj).parents(".view").each(function (index, obj) {
			result = $(obj).index().toString() + "," + result
		});
		return result + $(viewObj).index();
	};

	function setEditViewData(data) {
		$("input[name=viewid]", "#modalEditView").val(data.viewid);
		$("textarea[name=content]", "#modalEditView").val(data.content.raw);
		$("select[name=view]", "#modalEditView").change(function () {
			view = $(this).val();
			if (view == "") {
				$(".view-settings", "#modalEditView").html("");
				return;
			}
			$(".view-settings", "#modalEditView").html("<span class='loading .glyphicon .glyphicon-cog'></span>");
			Locale.ensureLoaded(view, { loaded: function() {
				url = "views/" + view + "/coworkers/view_edit_settings.mustache?static_only=true";
				$.get(url, {cache: false},function (template) {
					strs = Locale.rawStrings(["system", view]);
					data.urid = UIDGenerator.get();
					for (id in strs)
						data.settings[id] = strs[id];
					html = Mustache.to_html(template, data.settings);
					$(".view-settings", "#modalEditView").html(html);
				}).error(function () {
					$(".view-settings", "#modalEditView").html("");
				});
			}});
		}).val(data.view).trigger("change");
		$("select[name=col_span]", "#modalEditView").val(data.col_span);
		$("select[name=col_offset]", "#modalEditView").val(data.col_offset);
		$("select[name=row_offset]", "#modalEditView").val(data.row_offset);
		$("input[name=setting_classes]", "#modalEditView").val(data.settings.classes);
		$("select[name=view] option", "#modalEditView").removeAttr("disabled");

		if (data.col_span < 12) {
			min_col_spans = [];
			for (i = 12; i > data.col_span; i--)
				min_col_spans.push(".min-col-span" + i);
			$(min_col_spans.join(",")).attr("disabled", "disabled");
		}
	};

	function showEditView(viewObj) {
		$(".loading", "#modalEditView").show();
		$("form", "#modalEditView").hide();
		viewid = getViewIdFromView(viewObj);
		pageid = $("input[name=pageid]", "#modalEditView").val();
		url = "__api__/pages/" + pageid + "/view/" + viewid;
		$.getJSON(url, function (data) {
			setEditViewData(data);
			$("#form_view_content .view_include_text input").prop("checked", (data.content.raw != ""));
			$("#form_view_content .view_include_text").toggle(data.view != "");
			$("#form_view_content .view_texteditor").toggle(data.content.raw != "");
			$(".loading", "#modalEditView").hide();
			$("form", "#modalEditView").show();
		});

		options = {
			success: function () {
				location.reload();
			}
		};
		$("form", "#modalEditView").attr("action", url).ajaxForm(options);
		$("#modalEditView").modal("show");
	};


	function showDeleteView(viewObj) {
		viewid = getViewIdFromView(viewObj);
		pageid = $("input[name=pageid]", "#modalDeleteView").val();
		url = "__api__/pages/" + pageid + "/view/" + viewid;
		$("form", "#modalDeleteView").attr("action", url).submit(function (form) {
			$.getJSON(url + "?_method=delete", function (data) {
				$(viewObj).remove();
				$("#submitDeleteView").button("reset");
				$("#modalDeleteView").modal("hide");
			});
			return false;
		});
		$("#modalDeleteView").modal("show");
	};

	function checkVisibilityTextEditor() {
		view = $("#form_view_content select").val();
		checked = $("#form_view_content .view_include_text input").prop("checked");
		$("#form_view_content .view_include_text").toggle(view != "");
//		$("#form_view_content .view_texteditor").toggle((view == "") || (checked));
	};

	function addSubview(pageid, templateid, path) {
		url = "__api__/pages/" + pageid + "/views/?_method=put&template=" + templateid;
		if ((path !== undefined) && (path != ""))
			url += "&parentid=" + path;
		$.getJSON(url, function (data) {
			location.reload();
		});
	};

	function submit(btn) {
		$(btn).button('loading');
		jModal = $(btn).closest(".modal");
		if (jModal.attr("id") == "modalEditView") {
			view = $("#form_view_content select[name=view]").val();
			checked = $("#form_view_content .view_include_text input").prop("checked");
			if ((view != "") && (!checked)) {
				$("#form_view_content .view_texteditor textarea").val("");
			}
		}
		jModal.one("hidden.bs.modal", function() {
			$('form', jModal).submit();
		});
		jModal.modal("hide");
	}



	return {
		togglePageAdmins: togglePageAdmins,
		showEditPage: showEditPage,
		showDeletePage: showDeletePage,
		showAddSubpage: showAddSubpage,
		showEditView: showEditView,
		showDeleteView: showDeleteView,
		checkVisibilityTextEditor: checkVisibilityTextEditor,
		addSubview: addSubview,
		submit: submit
	};


})(jQuery);