/*

 Generator for Unique ID's, which are usefull for URID's (Unique Render Identifiers),
 used in Mustache files.

	Based on http://dbj.org/dbj/?p=76

*/

var UIDGenerator = (function () {

	"use strict";

	function get() {
		var uid = setTimeout(function() { clearTimeout(uid); }, 0);
		return uid;
	}

	return { get: get };

})();