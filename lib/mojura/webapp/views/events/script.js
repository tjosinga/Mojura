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
			data.urid = UIDGenerator.get();
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
		addEditEvent(eventsContainerId, "post", "new");
	}

	function editEvent(eventsContainerId, eventId) {
		addEditEvent(eventsContainerId, "put", eventId);
	}

	function addEditEvent(eventsContainerId, method, eventId) {
		var isNew = (method === "post");
		var action = isNew ? "action_add" : "action_edit";
		Modal.create({
			id: "eventsAddEditModal",
			title: Locale.str("events", action),
			oncreated: function(modalId, onLoaded) {
				$("#" + modalId).modal("show");
				var url = "__api__/events/" + eventId;
				$.getJSON(url, function(data, textStatus, response) {
					var template = $("#template-events-addedit").html();
					data = $.merge(data, Locale.getViewsStrings(["system", "events"]));
					data.method = method;
					data.eventId = eventId;
					data.urid = UIDGenerator.get();
					var partials = {
						"rights-controls": $("#template-rights-controls").html(),
						"locales-selection": $("#template-locales-selection").html()
					};
					data.simple_rights_visible = ((data.rights.rights & 4) > 0);
					var supportedLanguages = response.getResponseHeader("Mojura-Supported-Languages");
					data.supported_locales =  (typeof supportedLanguages === "string") ? supportedLanguages.split(", ") : [];
					data.is_multilingual = (data.supported_locales.length > 1);

					var html = Mustache.render(template, data, partials);
					$(".modal-body", "#" + modalId).html(html);
					onLoaded();
				});
				return true;
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