class_name GASScriptLoader
extends RefCounted

var _file_cache: GASFileCache
var _pipeline: GASPipeline
var _config: GASInterpreterConfig
var _profiler: GASProfiler = null

func _init(file_cache: GASFileCache, pipeline: GASPipeline, config: GASInterpreterConfig) -> void:
	_file_cache = file_cache
	_pipeline = pipeline
	_config = config
	_profiler = config.profiler

func load(path: String) -> GASResult:
	var errors: Array[GASError] = []
	var warnings: Array[GASError] = []

	var modified_time: int = FileAccess.get_modified_time(path)
	var cached: GASScript = _file_cache.fetch(path, modified_time)
	if cached != null:
		if _profiler != null:
			_profiler.file_cache_hits += 1
		return GASResult.new(true, cached, errors, warnings, {})

	if _profiler != null:
		_profiler.file_cache_misses += 1

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append(GASError.new(GASError.Code.IO, "Could not open file: %s" % path))
		return GASResult.new(false, null, errors, warnings, {})

	var content: String = file.get_as_text()
	file.close()

	var source_blocks: Array[GASSourceBlock] = []
	var parse_errors: Array[GASError] = []

	var blocks: Array = GASBlockSplitter.split(content)
	for block: Dictionary in blocks:
		var priority: int = int(block.get("priority", 0))
		var block_content: String = block.get("content", "") as String

		var ast: Expr = _pipeline.parse(block_content)
		var block_errors: Array[GASError] = _pipeline.get_parse_errors()

		if not block_errors.is_empty():
			for e: GASError in block_errors:
				parse_errors.append(e)
			continue

		if ast == null:
			parse_errors.append(GASError.new(GASError.Code.PARSE, "Failed to parse block with priority %d" % priority))
			continue

		source_blocks.append(GASSourceBlock.new(priority, block_content))

	if not parse_errors.is_empty():
		return GASResult.new(false, null, parse_errors, warnings, {})

	var script: GASScript = GASScript.new(path, modified_time, source_blocks)
	_file_cache.store(path, script)

	return GASResult.new(true, script, errors, warnings, {})
