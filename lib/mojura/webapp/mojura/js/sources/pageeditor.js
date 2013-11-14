/* global jQuery:false */
/* global Mustache:false */
/* global Locale:false */
/* global UIDGenerator:false */

var PageEditor = (function ($) {
	"use strict";

	function togglePageAdmins() {
		$(".btn-edit-page").toggleClass("hide");
		$(".view-admin").toggleClass("hide").parent().toggleClass("editable");

		var url = window.location.toString().replace(/#editing/, "");
		if ($(".btn-edit-page").is(":visible")) {
			url += "#editing";
		}

		history.pushState({}, document.title, url);
	}

	function showEditPage() {
		$("#modalEditPage").modal("show");
		var old_title = $("input[name=title]", "#modalEditPage").val();
		$("form", "#modalEditPage").on("submit", function () {

			$(this).ajaxSubmit({success: function () {

				var new_title = $("input[name=title]", "#modalEditPage").val();
				if (new_title !== old_title) {
					var pattern_old_title = encodeURIComponent(old_title).replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
					var reg = new RegExp(pattern_old_title + "#", "g");
					var url = document.location.toString().replace(reg, encodeURIComponent(new_title) + "#");
					history.pushState({}, document.title, url);
				}
				$("#modalEditPage").modal("hide");
				location.reload();
			}, error: function (request, errordata, errorObject) {
				window.alert(errorObject.toString());
			}});
		});
	}

	function showDeletePage() {
		var pageid = $("input[name=pageid]", "#modalDeletePage").val();
		var url = "__api__/pages/" + pageid;
		$("form", "#modalDeletePage").submit(function (form) {
			$.getJSON(url + "?_method=delete", function (data) {
				var url = document.location.toString();
				document.location = url.slice(0, url.lastIndexOf("/"));
				$("#modalDeletePage").modal("hide");
			});
			return false;
		});
		$("#modalDeletePage").modal("show");
	}

	function showAddSubpage() {
		var pageid = $("input[name=pageid]", "#modalDeletePage").val();
		var html = $("#modalEditPage form").html();
		$("#modalAddSubpage form .elements").html(html);
		$("#modalAddSubpage form input[name=title]").val("");
		$("#modalAddSubpage").modal("show");
		$("form", "#modalAddSubpage").on("submit", function () {
			$(this).ajaxSubmit({success: function () {
				var title = $("input[name=title]", "#modalAddSubpage").val();
				var url = document.location.toString();
				url = url.slice(0, url.indexOf("#"));
				url += "/" + encodeURIComponent(title) + "#editing";
				$("#modalAddSubpage").modal("hide");
				document.location = url;
			}, error: function (request, errordata, errorObject) {
				window.alert(errorObject.toString());
			}});
		});
	}


	function getViewIdFromView(viewObj) {
		var result = "";
		$(viewObj).parents(".view").each(function (index, obj) {
			result = $(obj).index().toString() + "," + result;
		});
		return result + $(viewObj).index();
	}

	function setEditViewData(data) {
		$("input[name=viewid]", "#modalEditView").val(data.viewid);
		$("textarea[name=content]", "#modalEditView").val(data.content.raw);
		$("select[name=view]", "#modalEditView").change(function () {
			var view = $(this).val();
			if (view === "") {
				$(".view-settings", "#modalEditView").html("");
				return;
			}
			$(".view-settings", "#modalEditView").html("<div class='loading'></div>");
			Locale.ensureLoaded(view, { loaded: function() {
				var url = "views/" + view + "/coworkers/view_edit_settings.mustache?static_only=true";
				$.get(url, {cache: false},function (template) {
					var strs = Locale.rawStrings(["system", view]);
					data.urid = UIDGenerator.get();
					for (var id in strs) {
						if (strs.hasOwnProperty(id)) {
							data.settings[id] = strs[id];
						}
					}
					var html = Mustache.to_html(template, data.settings);
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
			var min_col_spans = [];
			//noinspection JSUnresolvedVariable
			for (var i = 12; i > data.col_span; i--) {
				min_col_spans.push(".min-col-span" + i);
			}
			$(min_col_spans.join(",")).attr("disabled", "disabled");
		}
	}

	function showEditView(viewObj) {
		$(".loading", "#modalEditView").show();
		$("form", "#modalEditView").hide();
		var viewid = getViewIdFromView(viewObj);
		var pageid = $("input[name=pageid]", "#modalEditView").val();
		var url = "__api__/pages/" + pageid + "/view/" + viewid;
		$.getJSON(url, function (data) {
			setEditViewData(data);
			$("#form_view_content .view_include_text input").prop("checked", (data.content.raw !== ""));
			$("#form_view_content .view_include_text").toggle(data.view !== "");
			$("#form_view_content .view_texteditor").toggle(data.content.raw !== "");
			$(".loading", "#modalEditView").hide();
			$("form", "#modalEditView").show();
		});

		var options = {
			success: function () {
				location.reload();
			}
		};
		$("form", "#modalEditView").attr("action", url).ajaxForm(options);
		$("#modalEditView").modal("show");
	}


	function showDeleteView(viewObj) {
		var viewid = getViewIdFromView(viewObj);
		var pageid = $("input[name=pageid]", "#modalDeleteView").val();
		var url = "__api__/pages/" + pageid + "/view/" + viewid;
		$("form", "#modalDeleteView").attr("action", url).submit(function (form) {
			$.getJSON(url + "?_method=delete", function (data) {
				$(viewObj).remove();
				$("#submitDeleteView").button("reset");
				$("#modalDeleteView").modal("hide");
			});
			return false;
		});
		$("#modalDeleteView").modal("show");
	}

	function checkVisibilityTextEditor() {
		var view = $("#form_view_content select").val();
		var checked = $("#form_view_content .view_include_text input").prop("checked");
		$("#form_view_content .view_include_text").toggle(view !== "");
//		$("#form_view_content .view_texteditor").toggle((view == "") || (checked));
	}

	function addSubview(pageid, templateid, path) {
		var url = "__api__/pages/" + pageid + "/views/?_method=put&template=" + templateid;
		if ((path !== undefined) && (path !== "")) {
			url += "&parentid=" + path;
		}
		$.getJSON(url, function (data) {
			location.reload();
		});
	}

	function submit(btn) {
		$(btn).button('loading');
		var jModal = $(btn).closest(".modal");
		if (jModal.attr("id") === "modalEditView") {
			var view = $("#form_view_content select[name=view]").val();
			var checked = $("#form_view_content .view_include_text input").prop("checked");
			if ((view !== "") && (!checked)) {
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