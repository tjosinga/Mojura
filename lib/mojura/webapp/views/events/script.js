var EventsView = (function($, Mustache) {

	"use strict";

	function init() {
	}

	function getSectionMasks(sectionType) {
		sectionType = sectionType.toLowerCase();
		if (sectionType === "year") {
			return { section: "YYYY", title: "YYYY" };
		} else if (sectionType === "month") {
			return { section: "YYYY-MM", title: "MMMM YYYY" };
		} else if (sectionType === "week") {
			return { section: "YYYY-WW", title: "[" + Locale.str("system", "week") + "] W, YYYY" };
		} else {
			return { section: "YYYY-MM-DD", title: "LL" };
		}
	}

	function loadEvents(eventsContainerId) {
		var url = "__api__/events/";
		$.getJSON(url, function(data) {
			var sectionType = "week";
			var template = $("#template-events").html();
			data.sections = dataItemsToSections(data.items, getSectionMasks(sectionType));
			data.show_date = (sectionType !== "days");
			data.items = null;
			var html = Mustache.render(template, data);
			$(eventsContainerId).html(html);

			$(".pretty-moment", eventsContainerId).each(function() {
				var type = $(this).attr("data-type");
				var dateStr = $(this).text();
				if (type === "locale") {
					var format = $(this).attr("data-format");
					dateStr = moment(dateStr).format(format);
				}
				$(this).text(dateStr);
			});
		});
	}

	function dataItemsToSections(items, masks) {
		var sections = {};
		$(items).each (function (index) {
			var event = items[index];
			var mDate = moment(event.start);
			var section = mDate.format(masks.section);
			if (typeof sections[section] === "undefined") {
				sections[section] = {title: mDate.format(masks.title), events: []};
			}
			sections[section].events.push(event);
		});
		var result = [];
		$.each(sections, function(index, sectionEvents) {
			result.push(sectionEvents);
		});
		return result;
	}

	function addEvent(eventsContainerId) {
		addEditEvent(eventsContainerId, "put", "new");
	}

	function editEvent(eventsContainerId, eventId) {
		addEditEvent(eventsContainerId, "post", eventId);
	}

	function addEditEvent(eventsContainerId, method, eventId) {
		var isNew = (method === "put");
		var action = isNew ? "action_add" : "action_edit";
		Modal.create({
			id: "eventsAddEditModal",
			title: Locale.str("events", action),
			oncreated: function(modalId) {
				$("#" + modalId).modal("show");
				var url = "__api__/events/" + eventId;
				$.getJSON(url, function(data) {
					var template = $("#template-events-addedit").html();
					data.method = method;
					data.eventId = eventId;
					data = $.merge(data, Locale.getViewsStrings(["system", "events"]));
					var html = Mustache.render(template, data);
					$(".modal-body", "#" + modalId).html(html);
				});
			},
			onsubmitted: function(modalId, data) {
				location.reload();
				loadEvents(eventsContainerId);
			}
		});
	}

	function deleteEvent() {

	}

	return {
		init: init,
		loadEvents: loadEvents,
		addEvent: addEvent,
		editEvent: editEvent,
		deleteEvent: deleteEvent
	};

})(jQuery, Mustache);