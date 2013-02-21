var PageEditor = (function($) {

	function togglePageAdmins()	{
		$(".btn-edit-page").toggle();
		$(".view-admin").toggle().parent().toggleClass("editable");

		url = window.location.toString().replace(/#editing/, "");
		if ($(".btn-edit-page").is(":visible"))
			url += "#editing";

		history.pushState({}, document.title, url);
	};

	function showEditPage() {
		$("#modalEditPage").modal("show");
		old_title = $("input[name=title]", "#modalEditPage").val();
		$("form", "#modalEditPage").on("submit", function() {

			$(this).ajaxSubmit({success: function() {

				new_title = $("input[name=title]", "#modalEditPage").val();
				if (new_title != old_title) {
	    		pattern_old_title = encodeURIComponent(old_title).replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
	    		reg = new RegExp(pattern_old_title + "\#", "g");
	    		url = document.location.toString().replace(reg, encodeURIComponent(new_title) + "#");
					history.pushState({}, document.title, url);
				}
				$("#modalEditPage").modal("hide");
				location.reload();
			}, error: function(request, errordata, errorObject) {
				alert(errorObject.toString());
			}});

		});

	};

	function getViewIdFromView(viewObj) {
		result = "";
		$(viewObj).parents(".view").each(function(index, obj){
			result = $(obj).index().toString() + "," + result
		});
		return result + $(viewObj).index();
	};

	function setEditViewData(data) {
		$("input[name=viewid]", "#modalEditView").val(data.viewid);
		$("textarea[name=content]", "#modalEditView").val(data.content.raw).sceditor({
      plugin: "ubbcode",
      style: "ext/sceditor/themes/default.min.css",
      emoticonsRoot: "ext/sceditor/"
    });
		$("select[name=view]", "#modalEditView").change(function () {
			view = $(this).val();
			if (view == "") {
				$(".view_settings", "#modalEditView").html("");
				return;
			}
			$(".view_settings", "#modalEditView").html("<div class='loading'></div>");
			$.getJSON("views/" + view + "/strings.nl.json", function(strings) {
				$.get("views/" + view + "/view_page_edit_settings.mustache?static_only=true", {cache: false}, function(template) {
					for (key in strings) { data.settings["app_str_" + view + "_" + key] = strings[key] }
					html = Mustache.to_html(template, data.settings);
					$(".view_settings", "#modalEditView").html(html);
				}).error(function () {
					$(".view_settings", "#modalEditView").html("");
				});
			}).error(function () {
				alert("Couldn't load strings for " + view);
			});
		}).val(data.view).trigger("change");
		$("select[name=col_span]", "#modalEditView").val(data.col_span);
		$("select[name=col_offset]", "#modalEditView").val(data.col_offset);
		$("select[name=row_offset]", "#modalEditView").val(data.row_offset);
		$("input[name=setting_classes]", "#modalEditView").val(data.settings.classes);
		$("select[name=view] option", "#modalEditView").removeAttr("disabled");

		if (data.col_span < 12)
		{
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

		$.getJSON(url, function(data) {
			setEditViewData(data);
			$(".loading", "#modalEditView").hide();
			$("form", "#modalEditView").show();
		});

		options = {
		  success:    function() {
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
			$.getJSON(url + "?_method=delete", function(data) {
				$(viewObj).remove();
				$("#submitDeleteView").button("reset");
				$("#modalDeleteView").modal("hide");
			});
			return false;
		});
		$("#modalDeleteView").modal("show");
	};

	function addSubview(pageid, templateid, path) {
		url = "__api__/pages/" + pageid + "/views/?_method=put&template=" + templateid;
		if ((path !== undefined) && (path != ""))
			url += "&parentid=" + path;
		$.getJSON(url, function(data) {
			location.reload();
		});
	};


	return {
		togglePageAdmins: togglePageAdmins,
		showEditPage: showEditPage,
		showEditView: showEditView,
		showDeleteView: showDeleteView,
		addSubview: addSubview
	};


})(jQuery);