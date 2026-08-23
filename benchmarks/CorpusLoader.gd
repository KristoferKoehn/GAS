class_name CorpusLoader
extends RefCounted

static func load_corpus(path: String) -> GasCorpus:
	var corpus: GasCorpus = GasCorpus.new()

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open corpus: %s" % path)
		return corpus
	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Corpus root is not a dictionary: %s" % path)
		return corpus

	var root: Dictionary = parsed as Dictionary
	corpus.cache_miss_ratio = float(root.get("cache_miss_ratio", 0.0))
	corpus.target_statement_count = int(root.get("target_statement_count", 0))

	var raw_files: Variant = root.get("files", [])
	if typeof(raw_files) == TYPE_ARRAY:
		var file_weight_sum: float = 0.0
		for entry: Variant in (raw_files as Array):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var entry_dict: Dictionary = entry as Dictionary
			var corpus_file: CorpusFile = CorpusFile.new()
			corpus_file.path = entry_dict.get("path", "") as String
			corpus_file.priority_base = int(entry_dict.get("priority_base", 0))
			corpus_file.weight = float(entry_dict.get("weight", 1.0))
			file_weight_sum += corpus_file.weight
			corpus.files.append(corpus_file)
		if file_weight_sum > 0.0:
			for corpus_file: CorpusFile in corpus.files:
				corpus_file.weight /= file_weight_sum

	var raw_statements: Variant = root.get("statements", [])
	if typeof(raw_statements) == TYPE_ARRAY:
		var statement_weight_sum: float = 0.0
		for entry: Variant in (raw_statements as Array):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var entry_dict: Dictionary = entry as Dictionary
			var statement: CorpusStatement = CorpusStatement.new()
			statement.source = entry_dict.get("source", "") as String
			statement.priority = int(entry_dict.get("priority", 0))
			statement.category = entry_dict.get("category", "") as String
			statement.weight = float(entry_dict.get("weight", 1.0))
			statement_weight_sum += statement.weight
			corpus.statements.append(statement)
		if statement_weight_sum > 0.0:
			for statement: CorpusStatement in corpus.statements:
				statement.weight /= statement_weight_sum

	var raw_weights: Variant = root.get("scenario_weights", {})
	if typeof(raw_weights) == TYPE_DICTIONARY:
		var weights_dict: Dictionary = raw_weights as Dictionary
		var weight_sum: float = 0.0
		for key: Variant in weights_dict:
			var key_str: String = key as String
			var value: float = float(weights_dict[key])
			corpus.scenario_weights[key_str] = value
			weight_sum += value
		if weight_sum > 0.0:
			var keys: Array = corpus.scenario_weights.keys()
			for key: Variant in keys:
				var key_str: String = key as String
				corpus.scenario_weights[key_str] = corpus.scenario_weights[key_str] / weight_sum

	return corpus
