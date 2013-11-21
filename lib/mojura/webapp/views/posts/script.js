var PostsView = (function($) {

	"use strict";

	function init(viewid) {
		load(viewid, 1);
	}

	function load(viewid, page) {
		var url = "__api__/posts?include_replies=true";
		if (page > 0) {
			url += "&page=" + page;
		}
		$(viewid).append("<div class='loading'></div>");
		$.getJSON(url, function(data) {
			for (var i = 0; i < data.items.length; i++) {
				data.items[i].is_post = true;
				data.items[i].pretty_timestamp = moment(data.items[i].timestamp).fromNow();
				data.items[i].reply_count = data.items[i].replies.length;
				data.items[i].has_replies = (data.items[i].reply_count > 0);
				data.items[i].likes_str = likesToString(data.items[i].likes);
				for (var j = 0; j < data.items[i].replies.length; j++) {
					data.items[i].replies[j].is_post = false;
					data.items[i].replies[j].likes_str = likesToString(data.items[i].replies[j].likes);
				}
			}
			data.viewid = viewid;
			data.has_more = (data.pageinfo.current < data.pageinfo.pagecount);
			data.next_page = data.pageinfo.current + 1;

			$.extend(Locale.rawStrings(["posts"]));

			var template = $("#template_posts_posts").html();
			var partials = {
				message: $("#template_posts_message").html(),
				addform: $("#template_posts_add_edit").html()
			};

			var html = Mustache.to_html(template, data, partials);
			$(".posts_load_more, .loading", viewid).remove();
			$(viewid).append(html);
		});
	}

	function likesToString(likes) {
		var result = "";
		for (var key in likes) {
			if (result !== "") {
				result += ", ";
			}
			result += likes[key];
		}
		if (result !== "") {
			result = "<i class=\"fa fa-thumbs-up\"></i> " + result;
		}
		return result;
	}

	function toggleLike(type, postid, replyid) {
		var url = "__api__/posts/" + postid;
		var id = postid;
		if (typeof replyid !== "undefined") {
			url += "/reply/" + replyid;
			id = replyid;
		}
		url += "/likes/?";
		url += (type === "like") ? "_method=put" : "_method=delete";
		$.getJSON(url, function(data) {
			$(".likes_" + id).html(likesToString(data));
			$(".like_btn_" + id).toggleClass("hidden");
			$(".unlike_btn_" + id).toggleClass("hidden");
		});
	}

	function like(postid, replyid) {
		toggleLike("like", postid, replyid);
	}

	function unlike(postid, replyid) {
		toggleLike("unlike", postid, replyid);
	}

	function post(message, isNew, postid) {
		var url = "__api__/";
		if (typeof postid === "undefined") {
			url += "posts";
		} else {
			url += "posts/" + postid + "/replies";
		}
		if (isNew) {
			url += "?_method=put";
		}

		$.post(url, "message=" + encodeURIComponent(message), function(data){
			$(".posts").html("<div class='loading'></div>");
			load(".posts", 0);
		});
	}

	return {
		init: init,
		load: load,
		like: like,
		unlike: unlike,
		post: post
	};

})(jQuery);
