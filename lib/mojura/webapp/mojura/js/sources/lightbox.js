var LightBox = (function($) {

	"use strict";

	var groups = {};
	var groupIndexes = {};
	var currentGroup;
	var $current;
	var template;

	function add(group, url, options) {
		groups[group] = groups[group] || [];
		groupIndexes[group] = groupIndexes[group] || 0;
		options = options || {};
		options.url = url;
		options.type = "image";
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
		groupIndexes[currentGroup] = index || 0;

		var html = Mustache.to_html(template, { group: currentGroup });
		$("body").append(html);
		$current = $("#lightbox-" + currentGroup);

		var $content = $(".lightbox-content", $current);
		var $dialog = $(".lightbox-dialog", $current);

		var centerContent = function() {
			if ($(window).height() <= $dialog.height()) {
				$content.height($(window).height());
			} else {
				$content.height("auto");
			}
		};

		var onKeyUp = function(e) {
			if (e.keyCode === 27) {
				$current.modal("hide");
			} else if (e.keyCode === 37) {
				previous();
			} else if (e.keyCode === 39) {
				next();
			}

		};

		$current.on("show.bs.modal", function() {
			$(window).on("resize", centerContent);
			$(document).on("keyup", onKeyUp);
			centerContent();
		});

		$current.on("hide.bs.modal", function() {
			$(window).off("resize", centerContent);
			$(document).off("keyup", onKeyUp);
		});

		$(".lightbox-left, .lightbox-right", $current).toggleClass("hidden", groups[currentGroup].length < 2);

		showMedia();

		$current.modal("show");
	}

	function showMedia() {
		var i = groupIndexes[currentGroup] || 0;
		var item = groups[currentGroup][i];
		$(".lightbox-content > *", $current).addClass("hidden");
		if (item.type === "image") {
			$(".lightbox-image", $current).attr("src", item.url).removeClass("hidden");
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

	return {
		add: add,
		show: show,
		previous: previous,
		next: next
	};

})(jQuery);