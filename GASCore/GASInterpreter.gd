class_name GASInterpreter
extends RefCounted

signal evaluation_failed(result: GASResult)

var _config: GASInterpreterConfig
var _registry: GASFunctionRegistry
var _library_loader: GASFunctionLibraryLoader
var _environment: GASEnvironment
var _ast_cache: GASAstCache
var _file_cache: GASFileCache
var _pipeline: GASPipeline
var _script_loader: GASScriptLoader
var _queue: GASPriorityQueue
var _init_result: GASResult
var _pending_errors: Array[GASError] = []
var _pending_warnings: Array[GASError] = []
var _profiler: GASProfiler = null

func _init(config: GASInterpreterConfig = null) -> void:
	if config == null:
		config = GASInterpreterConfig.new()
	_config = config
	_config.freeze()
	_profiler = _config.profiler

	_registry = GASFunctionRegistry.new()
	_library_loader = GASFunctionLibraryLoader.new(_registry, _config)
	_environment = GASEnvironment.new(_registry, _config)
	_ast_cache = GASAstCache.new(_config.ast_cache_limit, LruEvictionPolicy.new())
	_file_cache = GASFileCache.new(_config.file_cache_limit, LruEvictionPolicy.new())
	_pipeline = GASPipeline.new(_environment, _ast_cache, _config)
	_script_loader = GASScriptLoader.new(_file_cache, _pipeline, _config)
	_queue = GASPriorityQueue.new()

	var init_errors: Array[GASError] = []
	var init_warnings: Array[GASError] = []
	_init_result = GASResult.new(true, null, init_errors, init_warnings, {})

	if _config.auto_load_libraries and _library_mode_active():
		var load_result: GASResult = _library_loader.reload()
		if not load_result.ok:
			_init_result = load_result

func _run(source: String) -> GASResult:
	return _pipeline.run(source)

func _run_file(path: String) -> GASResult:
	var load_result: GASResult = _script_loader.load(path)
	if not load_result.ok:
		return load_result

	var script: GASScript = load_result.value as GASScript
	for block: GASSourceBlock in script.blocks:
		_enqueue_parsed(block.source, block.priority)

	return flush()

func enqueue(source: String, priority: int = 0) -> bool:
	return _enqueue_parsed(source, priority)

func enqueue_blocks(source: String, base_priority: int = 0) -> bool:
	var all_ok: bool = true
	for block: Dictionary in GASBlockSplitter.split(source):
		var priority: int = int(block.get("priority", 0)) + base_priority
		var content: String = block.get("content", "") as String
		if not _enqueue_parsed(content, priority):
			all_ok = false
	return all_ok

func _enqueue_parsed(source: String, priority: int) -> bool:
	var start: int = 0
	if _profiler != null:
		start = Time.get_ticks_usec()
	var ast: Expr = _pipeline.parse(source)
	if ast == null:
		for e: GASError in _pipeline.get_parse_errors():
			_pending_errors.append(e)
		return false
	_queue.enqueue(GASQueuedExpression.new(priority, ast, source))
	if _profiler != null:
		_profiler.enqueue_count += 1
		_profiler.enqueue_usec += Time.get_ticks_usec() - start
		_profiler.max_queue_depth = maxi(_profiler.max_queue_depth, _queue.size())
	return true

func enqueue_file(path: String, base_priority: int = 0) -> bool:
	var load_result: GASResult = _script_loader.load(path)
	if not load_result.ok:
		for e: GASError in load_result.errors:
			_pending_errors.append(e)
		for w: GASError in load_result.warnings:
			_pending_warnings.append(w)
		return false

	var script: GASScript = load_result.value as GASScript
	var all_ok: bool = true
	for block: GASSourceBlock in script.blocks:
		if not _enqueue_parsed(block.source, block.priority + base_priority):
			all_ok = false
	return all_ok

func flush() -> GASResult:
	var start: int = 0
	if _profiler != null:
		start = Time.get_ticks_usec()

	var errors: Array[GASError] = []
	var warnings: Array[GASError] = []
	for e: GASError in _pending_errors:
		errors.append(e)
	for w: GASError in _pending_warnings:
		warnings.append(w)
	_pending_errors.clear()
	_pending_warnings.clear()

	var value: Variant = null
	while not _queue.is_empty():
		var item: GASQueuedExpression = _queue.dequeue_next()
		var result: GASResult = _pipeline.evaluate(item.expression)

		if result.ok:
			value = result.value

		for e: GASError in result.errors:
			errors.append(e)
		for w: GASError in result.warnings:
			warnings.append(w)

	var snapshot: Dictionary[String, Variant] = _environment.get_symbol_snapshot()
	var final_result: GASResult = GASResult.new(errors.is_empty(), value, errors, warnings, snapshot)
	if _profiler != null:
		_profiler.flush_count += 1
		_profiler.flush_usec += Time.get_ticks_usec() - start
		_profiler.error_count += errors.size()
		_profiler.warning_count += warnings.size()
		_profiler.symbol_count = _environment.get_symbol_count()
		_profiler.ast_cache_size = _ast_cache.size()
		_profiler.file_cache_size = _file_cache.size()
	if not final_result.ok:
		evaluation_failed.emit(final_result)
	return final_result

func set_variable(name: String, value: Variant) -> void:
	_environment.set_variable(name, value)

func get_variable(name: String) -> Variant:
	return _environment.get_variable(name)

func has_variable(name: String) -> bool:
	return _environment.has_variable(name)

func clear_variables() -> void:
	_environment.clear_variables()

func clear_queue() -> void:
	_queue.clear()
	_pending_errors.clear()
	_pending_warnings.clear()

func clear_functions() -> void:
	_registry.clear_explicit()

func register_function(name: String, function: Callable) -> void:
	_registry.register(name, function)

func register_functions(entries: Dictionary[String, Callable]) -> void:
	_registry.register_many(entries)

func has_function(name: String) -> bool:
	return _registry.resolve(name, _config.function_mode).is_valid()

func reload_libraries() -> GASResult:
	return _library_loader.reload()

func get_profiler() -> GASProfiler:
	return _profiler

func get_symbol_count() -> int:
	return _environment.get_symbol_count()

func clear_cache() -> void:
	_ast_cache.clear()
	_file_cache.clear()

func get_init_result() -> GASResult:
	return _init_result

func _library_mode_active() -> bool:
	return _config.function_mode == GASInterpreterConfig.FunctionMode.LIBRARY_ONLY \
		or _config.function_mode == GASInterpreterConfig.FunctionMode.REGISTRY_AND_LIBRARY
