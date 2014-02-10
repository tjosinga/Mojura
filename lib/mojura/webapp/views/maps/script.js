var MapsView = (function($) {

	'use strict';

	var maps = {};

	function initMap(mapId, options) {
		options.initLat = options.initLat || 0;
		options.initLng = options.initLng || 0;
		options.initZoom = options.initZoom || 0;

		maps[mapId] = {};
		maps[mapId].markers = [];

		maps[mapId].map = L.map(mapId).setView([options.initLat, options.initLng], options.initZoom);
		options.tileUrl = options.tileUrl || 'http://{s}.tile.osm.org/{z}/{x}/{y}.png';
		options.tileAttribution = options.tileAttribution || '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a>';
		L.tileLayer(options.tileUrl, {
			attribution: options.tileAttribution
		}).addTo(maps[mapId].map);
	}

	function loadLocations(mapId, category, zoomIn) {
		var url = "__api__/locations";
		if (category !== "") {
			url += "?category=" + encodeURIComponent(category);
		}
		$.getJSON(url, function(locations) {
			if (typeof locations !== "undefined") {
				for (var i in locations) {
					var loc = locations[i];
					addLocation(mapId, loc.latitude, loc.longitude, loc.title, loc.description.html);
				}
				if (zoomIn) {
					autoZoom(mapId);
				}
			}
		});
	}

	function addLocation(mapId, lat, lng, title, description) {
		if (maps[mapId] === undefined) {
			window.console.log("MapsView.addLocation: Unknown mapId");
			return;
		}
		var marker = L.marker([lat, lng]).addTo(maps[mapId].map);
		marker.bindPopup("<h5>" + title + "</h5><br />" + description);
		maps[mapId].markers.push(marker);
	}

	function autoZoom(mapId) {
		if (maps[mapId] === undefined) {
			window.console.log("MapsView.addLocation: Unknown mapId");
			return;
		}
		var group = new L.featureGroup(maps[mapId].markers);
		maps[mapId].map.fitBounds(group.getBounds()).pad(0.5);
	}

	return {
		initMap: initMap,
		loadLocations: loadLocations,
		addLocation: addLocation
	};

})(jQuery);