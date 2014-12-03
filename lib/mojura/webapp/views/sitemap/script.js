var SitemapView = (function($) {

	"use strict";

	var $sitemaps = {}

	function register(sid) {
		$sitemaps[sid] = $("#" + sid);
		return this;
	}

	function initialize(sid, pageid) {
		var options = {
			handle: "span.fa-reorder",
			nested: true,
			onStartDrag: function() {
				$sitemaps[sid].addClass("select-none");
			},
			onDrop: function($item, container, _super, event) {
				onDrop(sid, $item, _super);
			}
		};
		$sitemaps[sid].sortable(options);

		console.log("initialize");
		$(".collapse-handle").click(function () {
			$(this).toggleClass("fa-caret-down").toggleClass("fa-caret-right")
			$(this).parent().parent().children("ul").toggleClass("hide");
		});

		checkCollapseHandles(sid);

		if (typeof pageid !== "undefined") {
			var $li = $("li[data-id=" + pageid + "]", $sitemaps[sid]);
			$li.children(".list-item").addClass("current-page");
			$li.parents(".sitemap").removeClass("hide");
		}
		return this;
	}

	function unregister(sid) {
		delete $sitemaps[sid];
	}

	function getNewParentId($item) {
		return $item.parent().attr("data-parentid");
	}

	function getNewOrderId($item) {
		var result = parseInt($item.prev().attr("data-orderid"), 10);
		if (isNaN(result)) {
			result = 0;
		}
		if (result < parseInt($item.attr("data-orderid"), 10)) {
			result += 1;
		}
		return result;
	}

	function setNewOrderIds(nodes) {
		if (typeof nodes !== "undefined") {
			for (var x in nodes) {
				var node = nodes[x];
				$("li[data-id=" + node.id + "]").attr("data-orderid", node.orderid).find(".orderid").html(node.orderid);
				if (typeof node.children !== "undefined") {
					setNewOrderIds(node.children);
				}
			}
		}
	}

	function checkCollapseHandles(sid) {
		$("span.collapse-handle", $sitemaps[sid]).each(function(index) {
			var $ul = $(this).parent().parent().children("ul");
			var hasChildren = ($ul.children("li").size() > 0);
			$(this).toggleClass("hide", !hasChildren);
			var childrenVisible = true;
			if (!hasChildren) {
				$ul.children("ul").removeClass("hide");
			} else {
				childrenVisible = !$ul.hasClass("hide");
			}
			$(this).toggleClass("fa-caret-down", childrenVisible).toggleClass("fa-caret-right", !childrenVisible);
		});
	}

	function onDrop(sid, $item, _super){
		_super($item);
		var parentId = getNewParentId($item);
		var orderId = getNewOrderId($item);
		var id = $item.attr("data-id");
		$item.attr("data-orderid", orderId).children("ul").attr("data-parentid", parentId);
		$item.addClass("saving");
		$item.children("div").children(".fa-reorder").removeClass("fa-reorder").addClass("fa-refresh fa-spin");

		var url = "__api__/pages/" + id;
		var postVars = {};
		postVars._method = "put";
		postVars.orderid = orderId;
		postVars.parentid = parentId;
		$.post(url, postVars, function(data, textStatus) {
			$.getJSON("__api__/pages?use_locale=false", function (data) {
				setNewOrderIds(data);
				checkCollapseHandles($item);
				$item.removeClass("saving");
				$item.find(".fa-refresh").removeClass("fa-refresh fa-spin").addClass("fa-reorder");
			});
		}, "json");
		$sitemaps[sid].removeClass("select-none");
	}

	return {
		register: register,
		initialize: initialize,
		unregister: unregister
	};

})(jQuery);