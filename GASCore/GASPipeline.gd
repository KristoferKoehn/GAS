class_name GASPipeline
extends RefCounted

var _environment: GASEnvironment
var _ast_cache: GASAstCache
var _config: GASInterpreterConfig
var _profiler: GASProfiler = null

var _last_lexer: Lexer = null
var _last_parser: PrattParser = null

func _init(environment: GASEnvironment, ast_cache: GASAstCache, config: GASInterpreterConfig) -> void:
	_environment = environment
	_ast_cache = ast_cache
	_config = config
	_profiler = config.profiler

func parse(source: String) -> Expr:
	var start: int = 0
	if _profiler != null:
		start = Time.get_ticks_usec()

	var cached: Expr = _ast_cache.get_ast(source)
	if cached != null:
		if _profiler != null:
			_profiler.ast_cache_hits += 1
			_profiler.parse_count += 1
			_profiler.parse_usec += Time.get_ticks_usec() - start
		_last_lexer = null
		_last_parser = null
		return cached

	if _profiler != null:
		_profiler.ast_cache_misses += 1

	_last_lexer = Lexer.new(source)
	_last_parser = PrattParser.new(_last_lexer.tokens)
	var ast: Expr = _last_parser.parse()

	if _profiler != null:
		_profiler.parse_count += 1
		_profiler.parse_usec += Time.get_ticks_usec() - start

	if ast != null and _last_lexer.errors.is_empty() and _last_parser.errors.is_empty():
		_ast_cache.store(source, ast)

	return ast

func get_parse_errors() -> Array[GASError]:
	var result: Array[GASError] = []
	if _last_lexer != null:
		for e: GASError in _last_lexer.errors:
			result.append(e)
	if _last_parser != null:
		for e: GASError in _last_parser.errors:
			result.append(e)
	return result

func evaluate(ast: Expr) -> GASResult:
	var start: int = 0
	if _profiler != null:
		start = Time.get_ticks_usec()
	var evaluator: Evaluator = Evaluator.new(_environment, _config)
	var result: GASResult = evaluator.evaluate(ast)
	if _profiler != null:
		_profiler.evaluate_count += 1
		_profiler.evaluate_usec += Time.get_ticks_usec() - start
	return result

func run(source: String) -> GASResult:
	var ast: Expr = parse(source)
	var parse_errors: Array[GASError] = get_parse_errors()

	if not parse_errors.is_empty():
		var snapshot: Dictionary[String, Variant] = _environment.get_symbol_snapshot()
		return GASResult.new(false, null, parse_errors, [], snapshot)

	return evaluate(ast)
