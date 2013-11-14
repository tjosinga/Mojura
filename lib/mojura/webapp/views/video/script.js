/* This anonymous script takes care of resizing all videos */
/* global jQuery:false */

(function ($) {
	"use strict";

	function init() {

		$(window).resize(function () {
			var allVideos = $("iframe[src^='http://www.youtube.com'], iframe[src^='http://player.vimeo.com'], iframe[src='http://www.zideo.nl']");
			allVideos.each(function () {
				var el = $(this);
				el.height(el.width() * 0.6);
			});
		});

		$(document).ready(function() {
			$(window).resize();
		});

	}

	init();

})(jQuery);

