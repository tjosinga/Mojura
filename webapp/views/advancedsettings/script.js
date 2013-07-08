var AdvancedSettings = (function($) {

	function getSettingInfo(id) {
		obj = $("#settings_row_" + id);
		return {
			resource: obj.attr("data-resource"),
			level: obj.attr("data-level"),
			key: obj.attr("data-key"),
			value: $(".advanced_setting_value", obj).html()
		}
	}

	function showAdd(resource) {
		obj = $("#settings_add_modal");
		$("input[name=resource]", obj).val(resource);
		$(".save-btn", obj).one("click", function() {
			obj = $("#settings_add_modal");
			data = {};
			$("form", obj).ajaxSubmit();
			$("form input, form select", obj).each(function() {
				data[$(this).attr("name")] = $(this).val();
			});
			data["id"] = data["resource"] + "_" + data["level"] + "_" + data["key"];
			data["is_protected"] = (data["level"] == "protected");
			data["is_public"] = (data["level"] == "public");
			data[("as_" + data["type"].toLowerCase())] = true;
			template = $("#template_settings_row").html();
			html = Mustache.to_html(template, data);
			$(".settings-table-" + resource).append(html);
			obj.modal("hide");
		});
		obj.modal("show");
	}

	function edit(id) {
		info = getSettingInfo(id);
		oldValue = info.value;
		newValue = $("input, select", "#settings_row_" + id).val();
		url = "__api__/settings/" + info.resource + "/" + info.key + "?_method=post";
		url += "&value=" + newValue;
		$.getJSON(url, function (data) {
			$(".advanced_setting_value", obj).html(newValue);
			hideEdit(id);
		});
	}

	function showEdit(id) {
		obj = $("#settings_row_" + id);
		$(".advanced_setting_value, .settings_edit_btn, .settings_delete_btn", obj).hide();
		$(".advanced_setting_input, .advanced_setting_input, .settings_save_btn, .settings_cancel_btn", obj).show();
		$("input, select", "#settings_row_" + id).val($(".advanced_setting_value", obj).html());
	}

	function hideEdit(id) {
		$(".advanced_setting_input, .advanced_setting_input, .settings_save_btn, .settings_cancel_btn", "#settings_row_" + id).hide();
		$(".advanced_setting_value, .settings_edit_btn, .settings_delete_btn", "#settings_row_" + id).show();
	}

	function showDelete(id) {
		obj = $("#settings_delete_modal");
		$(".delete-btn", obj).on("click", function() {
			info = getSettingInfo(id);
			url = "__api__/settings/" + info.resource + "/" + info.key + "?_method=delete";
			$.getJSON(url, function (data) {
				$("#settings_row_" + id).remove();
				$("#settings_delete_modal").modal("hide");
			});
		});
		obj.modal("show");
	}

	return {
		showAdd: showAdd,
		showEdit: showEdit,
		edit: edit,
		hideEdit: hideEdit,
		showDelete: showDelete
	};

})(jQuery);