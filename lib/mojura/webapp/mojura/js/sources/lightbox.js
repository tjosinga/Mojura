var LightBox = (function($) {

	"use strict";

	var groups = {};
	var groupIndexes = {};
	var currentGroup;
	var $current;
	var $dialog;
	var $content;
	var template;

	function add(group, url, options) {
		groups[group] = groups[group] || [];
		groupIndexes[group] = groupIndexes[group] || 0;
		options = options || {};
		options.url = url;
		if (url.match(/(http:|https:)?\/\/(www\.)?(youtube.com|youtu.be)\/(watch)?(\?v=)?(\S+)?/)) {
			options.type = "iframe";
			options.url = options.url.replace("watch?v=", "v/");
		} else if (url.match(/vimeo/)) {
			var parts = options.url.match(/(https?:\/\/)?(www.)?(player.)?vimeo.com\/([a-z]*\/)*([0-9]{6,11})[?]?.*/);
			var videoId = parts.pop();
			options.type = "iframe";
			options.url = "https://player.vimeo.com/video/" + videoId;
		} else if (typeof options.type === "undefined") {
			options.type = "image";
		}
		options.name = "";
		options.description = "";
		groups[group].push(options);
	}

	function show(group, index) {
		if (typeof groups[group] === "undefined") {
			return;
		}
		currentGroup = group;
		template = template || $("#template-lightbox").html();
		if (typeof index === "number") {
			groupIndexes[currentGroup] = index;
		} else {
			groupIndexes[currentGroup] = getIndexByUrl(index);
		}

		var html = Mustache.to_html(template, { group: currentGroup });
		$("body").append(html);
		$current = $("#lightbox-" + currentGroup);
		$content = $(".lightbox-content", $current);
		$dialog = $(".lightbox-dialog", $current);

		var onKeyUp = function(e) {
			if (e.keyCode === 27) {
				$current.modal("hide");
			} else if (e.keyCode === 37) {
				previous();
			} else if (e.keyCode === 39) {
				next();
			}
		};

		$current.on("shown.bs.modal", function() {
			$(document).on("keyup", onKeyUp);
		});

		$current.on("hide.bs.modal", function() {
			$(document).off("keyup", onKeyUp);
		});

		$current.on("hidden.bs.modal", function() {
			$current.remove();
		});

		$(".lightbox-left, .lightbox-right", $current).toggleClass("hidden", groups[currentGroup].length < 2);

		showMedia();

		$current.modal("show");
	}

	function showMedia() {
		var i = groupIndexes[currentGroup] || 0;
		var item = groups[currentGroup][i];
		var $aspectRatio = $(".aspect-ratio", $current);
		$(".lightbox-content > *, .lightbox-content .aspect-ratio > *", $current).addClass("hidden");

 		if (item.type === "image") {
			var $image = $(".lightbox-image", $current);
			if ($image.src !== item.url) {
				$image.attr("src", item.url);
			}
			$image.removeClass("hidden");
			$aspectRatio.addClass("hidden");
		} else {
			if (item.type === "video") {
				var $video = $(".lightbox-video", $current);
				$("source", $video).attr("src", item.url);
				$video.removeClass("hidden");
			} else if (item.type === "iframe") {
				var $iframe = $(".lightbox-iframe", $current);
				if ($iframe.attr("src") !== item.url) {
					$iframe.attr("src", item.url).load(function() {
						$(this).removeClass("hidden");
					});
				} else {
					$iframe.removeClass("hidden");
				}
			}
			$aspectRatio.removeClass("hidden");
		}

	}

	function step(steps) {
		var count = groups[currentGroup].length;
		groupIndexes[currentGroup] = (groupIndexes[currentGroup] + count + steps) % count;
		showMedia(currentGroup);
	}

	function previous() {
		step(-1);
	}

	function next() {
		step(1);
	}

	function getIndexByUrl(url) {
		for (var i in groups[currentGroup]) {
			if (typeof groups[currentGroup][i] !== "undefined") {
				var item = groups[currentGroup][i];
				if (item.url === url) {
					return Number(i);
				}
			}
		}
		return 0;
	}

	function clear(group) {
		groups[group] = [];
		groupIndexes[group] = 0;
	}

	return {
		add: add,
		show: show,
		previous: previous,
		next: next,
		clear: clear
	};

})(jQuery);