function APIGotoHash(hash) {
	if ((hash == undefined) || (hash == "")) return;
	items = hash.split("_");

	module = items[1];

	$("a[href='#tab_" + module + "']").tab("show");
	if (items.length > 2)
		$("a[href='" + hash + "']").tab("show");
}