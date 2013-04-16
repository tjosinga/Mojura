/* The video manager takes care of resizing all videos */

var VideoManager = (function ($) {

	function init() {

		$(window).resize(function () {
			allVideos = $("iframe[src^='http://www.youtube.com'], iframe[src^='http://player.vimeo.com'], iframe[src='http://www.zideo.nl']");
			allVideos.each(function () {
				el = $(this);
				el.height(el.width() * 0.6);
			});
		});

		$(document).ready(function() {
			$(window).resize();
		});

	}

	init();

})(jQuery);

