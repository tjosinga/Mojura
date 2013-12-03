var NewsView = (function($) {
	"use strict";

	function addNewsItem() {

	}

	function editNewsItem(newsid) {
		Modal.create({id: "newsAddEdit", title: ""}, function(modalId) {
			alert("created");
		});
	}

	function deleteNewsItem(newsid) {

	}

	return {
		addNewsItem: addNewsItem,
		editNewsItem: editNewsItem,
		deleteNewsItem: deleteNewsItem
	}


})(jQuery);