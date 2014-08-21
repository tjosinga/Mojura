var TagListInput = (function($) {

	'use strict';

	function init(id) {

		id = ((typeof id === "undefined") || (id === "")) ? ".tag-list-wrapper" : "#" + id;
		var $wrappers = $(id);

		$wrappers.each(function() {
			var $wrapper = $(this);

			if ($wrapper.children(".tag-list-ui").size() > 0) return;

			var $sourceInput = $wrapper.children("input");
			var values = $sourceInput.hide().val().split(",");
			$wrapper.append("<div class='tag-list-ui'><input type='text' style='display: inline; border: 0' /></div>");
			var $ui = $wrapper.children(".tag-list-ui");
			var $input = $ui.children("input");
			for (var i in values) {
				addTag($sourceInput, $input, values[i]);
			}

			$input.keypress(function (e) {
				if ((e.keyCode === 13) || (e.keyCode === 44) || (!$input.is(":focus"))) {
					var newTag = $input.val();
					$input.val("");
					addTag($sourceInput, $input, newTag);
					$sourceInput.val($sourceInput.val() + ", " + newTag);
					return false;
				}
			});

			$input.keydown(function (e) {
				var value = $input.val();
				if ((e.keyCode === 8) && (value === "")) {
					var $lastTag = $input.siblings().last();
					if ($lastTag.hasClass("selected")) {
						$lastTag.children("div").click();
					} else {
						$lastTag.addClass("selected");
					}
				} else {
					$input.siblings(".selected").removeClass("selected");
				}
			});

			$input.focus(function (e) {
				$wrapper.addClass("selected");
			});

			$input.blur(function (e) {
				$input.trigger("keypress");
				$wrapper.removeClass("selected");
				$ui.children(".selected").removeClass("selected");
			});

			$wrapper.click(function (e) {
				$input.focus();
			});
		});
	}

	function addTag($sourceInput, $input, tag) {
		tag = tag.trim();
		if (tag === "") return;
		var $tag = $("<span></span>");
		$tag.addClass("tag-list-item").text(tag).attr("data-tag", tag);
		var $closeBtn = $("<div style='cursor: pointer; padding-left: 3px;' aria-hidden='true'>&times;</div>");
		$closeBtn.addClass("delete-btn");
		$closeBtn.click(function (e) {
			$tag.remove();
			tagListToInput($sourceInput, $input);
		});
		$tag.append($closeBtn);
		$input.before($tag);
	}

	function tagListToInput($sourceInput, $input) {
		var s = "";
		$input.siblings().each(function(index) {
			if (s !== "") s += ", ";
			s += $(this).attr("data-tag");
		});
		$sourceInput.val(s);
	}

	return {
		init: init
	};

})(jQuery);