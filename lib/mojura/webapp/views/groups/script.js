var GroupsView = (function($) {

	"use strict";
	var membersModalId;
	var membersMayUpdate;

	function addGroup() {
		editGroup("new");
	}

	function editGroup(groupId) {
		var isNew = (groupId === "new");
		var titleId = isNew ? "add_group" : "edit_group";
		Modal.create( {
			title: Locale.str("groups", titleId),
			oncreated: function(modalId, onLoaded) {
				$.getJSON("__api__/groups/" + groupId, function(json) {
					var template = $("#template-groups-add-edit").html();
					json.method = isNew ? "post" : "put";
					json.urid = UIDGenerator.get();
					var html = Mustache.render(template, json);
					$(".modal-body", "#" + modalId).html(html);
					onLoaded();
				});
				return true;
			}
		});
	}

	function showMembers(groupId, mayUpdate) {
		Modal.create( {
			title: Locale.str("groups", "show_members"),
			modal_large: true,
			btn_action: Locale.str("system", "close"),
			btn_cancel: false,
			save_form: false,
			oncreated: function(modalId) {
				membersModalId = modalId;
				membersMayUpdate = mayUpdate;
				refreshMembers(groupId);
			}
		});
	}

	function addMember(groupId, button) {
		var userId = $(button).closest('.input-group').find('input').attr('data-id');
		if (typeof userId === "undefined") {
			return;
		}
		$(button).find("i").removeClass("fa-plus").addClass("fa-spinner fa-spin");
		var url = "__api__/users/" + userId + "/groups?groupid=" + groupId + "&_method=post";
		$.getJSON(url, function(json) {
			refreshMembers(groupId);
		});
	}

	function refreshMembers(groupId) {
		$.getJSON("__api__/groups/" + groupId + "/members", function(json) {
			var modalId = membersModalId;
			var template = $("#template-groups-members").html();
			var partials = {
				"avatars": $("#template-users-avatars").html(),
				"avatar_partial": $("#template-avatar-partial").html()
			};
			json.groupid = groupId;
			json.has_avatar_partial = true;
			json.may_update = membersMayUpdate;
			json.urid = UIDGenerator.get();
			json.raw = JSON.stringify(json);
			json.users_page_url = "users";
			json.classes = "col-xs-4 col-sm-3";
			var html = Mustache.render(template, json, partials);
			$(".modal-body", "#" + modalId).html(html);
			// Add members

			// Remove members
			$(".remove-member-icon", "#" + modalId + " .avatar").click(function(event) {
				$(this).next(".remove-member-bar").mouseleave(function() {
					$(this).addClass("hidden");
				}).click(function(event) {
					var userId = $(this).attr("data-userid");
					var url = "__api__/users/" + userId + "/group/" + groupId + "?_method=delete";
					var $bar = $(this);
					$(".inactive", $bar).addClass("hidden");
					$(".active", $bar).removeClass("hidden");
					$.getJSON(url, function() {
						$bar.parent(".thumbnail").parent().remove();
					}).error(function() {
						$(".active", this).addClass("hidden");
						$(".inactive", this).removeClass("hidden");
					});
					return false; // stop event propagation
				}).removeClass("hidden");
				return false;
			});

			var onselected = function(input) {
				$(input).closest(".input-group").find(".btn-success").toggleClass("disabled", $(input).attr("data-id") === "");
			};
			AutoComplete.prepare("#" + modalId + " .add-member input", {category: "users", onselected: onselected});
		});


	}

	function editRights(groupId) {
		Modal.create( {
			title: Locale.str("groups", "edit_rights"),
			oncreated: function(modalId, onLoaded) {
//				$("#" + modalId).modal("show");
//				$.getJSON("__api__/groups/" + groupId + "/rights", function(json) {
//					var template = $("#template-groups-members").html();
//					var partials = {"avatars": $("#template-users-avatars").html() };
//					json.urid = UIDGenerator.get();
//					var html = Mustache.render(template, json, partials);
//					$(".modal-body", "#" + modalId).html(html);
//				});
			}
		});
	}

	function deleteGroup(groupId) {

	}

	return {
		addGroup: addGroup,
		editGroup: editGroup,
		showMembers: showMembers,
		addMember: addMember,
		editRights: editRights,
		deleteGroup: deleteGroup
	};

})(jQuery);