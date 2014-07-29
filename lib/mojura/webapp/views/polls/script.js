var PollsView = (function($, Mustache) {
	"use strict";

	var pollData = {};

	function vote(pollid, index) {
		var url = "__api__/polls/" + pollid + "/votes?_method=post&index=" + index + "&include_votes=true";
		$(".poll-" + pollid + " .data-container").html("<div class='loading'></div>");
		$.getJSON(url, function(data) {
			pollData[pollid] = data;
			showResults(pollid);
		});
	}

	function showResults(pollid) {
		withPollData(pollid, function(data) {
			for (var i = 0; i < data.options.length; i++) {
				data.options[i].votes.rounded_percentage = Math.round(data.options[i].votes.percentage);
				data.options[i].votes.percentage = Math.round(data.options[i].votes.percentage * 10) / 10;
			}
			data.urid = UIDGenerator.get();
			var template = $("#template-polls-results").html();
			var html = Mustache.render(template, data);
			$(".poll-" + pollid + " .data-container").html(html);
		});
	}

	function withPollData(pollid, onLoaded) {
		if (typeof pollData[pollid] !== "undefined") {
			onLoaded(pollData[pollid]);
		}
		else {
			$.getJSON("__api__/polls/" + pollid + "?include_votes=true", function(data) {
				pollData[pollid] = data;
				onLoaded(data);
			});
		}
	}

	function showAdd() {
		showAddEdit("new");
	}

	function showEdit(pollid) {
		showAddEdit(pollid);
	}

	function showAddEdit(pollid) {
		var isNew = (typeof pollid === "undefined");
		var action = isNew ? "action_add" : "action_edit";
		Modal.create({
			id: "pollsAddEditModal",
			modal_large: true,
			title: Locale.str("polls", action),
			oncreated: function(modalId) {
				$("#" + modalId).modal("show");
				var url = "__api__/polls/" + pollid;
				$.getJSON(url, function(data) {
					var template = $("#template-polls-addedit").html();
					data.method = isNew ? "put" : "post";
					data.pollid = pollid;
					data.newline = "\n";
					data.urid = UIDGenerator.get();
					data = $.merge(data, Locale.getViewsStrings(["system", "polls"]));
					var html = Mustache.render(template, data);
					$(".modal-body", "#" + modalId).html(html);
				});
			},
			onsubmitted: function(modalId, data) {
				location.reload();
			}
		});
	}

	function showDelete(pollid) {
		Modal.create({
			id: "pollsDeleteModal",
			btn_class: "btn-danger",
			btn_action: Locale.str("system", "delete"),
			title: Locale.str("polls", "action_delete"),
			oncreated: function(modalId) {
				$("#" + modalId).modal("show");
				var template = $("#template-polls-delete").html();
				var data = Locale.getViewsStrings(["system", "polls"]);
				data.pollid = pollid;
				data.urid = UIDGenerator.get();
				var html = Mustache.render(template, data);
				$(".modal-body", "#" + modalId).html(html);
			},
			onsubmitted: function(modalId, data) {
				location.reload();
			}
		});
	}

	return {
		vote: vote,
		showResults: showResults,
		showAdd: showAdd,
		showEdit: showEdit,
		showDelete: showDelete
	};

})(jQuery, Mustache);