class_name GASBlockSplitter
extends RefCounted

static func split(text: String) -> Array:
	var blocks: Array = []
	var regex: RegEx = RegEx.new()
	regex.compile(r"\[(\d+)\]([\s\S]*?)(?=\[\d+\]|$)")
	var matches: Array[RegExMatch] = regex.search_all(text)

	for match: RegExMatch in matches:
		var priority: int = int(match.get_string(1))
		var content: String = match.get_string(2)
		blocks.append({"priority": priority, "content": content})

	if blocks.is_empty():
		var trimmed: String = text.strip_edges()
		if not trimmed.is_empty():
			blocks.append({"priority": 0, "content": trimmed})

	return blocks
