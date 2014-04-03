var AdvancedObjectRights = (function($) {

	"use strict";

	var modalId;

	function show(rights, userIds, groupIds, onsave) {
		Modal.create({
			title: Locale.str("system", "advanced_object_rights"),
			oncreated: function (id) {
				modalId = id;
				createForm(rights, userIds, groupIds);
			},
			onaction: function() {
				onsave(getRights(), getIds("users"), getIds("groups"));
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
		$("#" + modalId).modal("show");
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