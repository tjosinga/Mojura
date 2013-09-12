/*

 Generator for Unique ID's, which are usefull for URID's (Unique Render Identifiers),
 used in Mustache files.

	Based on http://dbj.org/dbj/?p=76

 */

var UIDGenerator = (function ($) {

	function get() {
		return uid = setTimeout(function() { clearTimeout(uid) } );
	}

	return { get: get }

})(jQuery);