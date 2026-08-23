extends SceneTree

## bench_soak.gd -- one-minute corpus soak benchmark.
##
## Each turn picks a random corpus file, enqueues it, enqueues a random
## number of weighted corpus statements, then flushes. Runs DURATION_SEC of
## wall clock time and reports average statements per frame at TARGET_FPS.

const CORPUS_PATH: String = "res://benchmarks/corpus.json"
const DURATION_SEC: float = 60.0
const TARGET_FPS: float = 60.0
const RNG_SEED: int = 12345
const TIMING_REPORTER: GDScript = preload("res://benchmarks/PhaseTimingReporter.gd")

func _init() -> void:
	var corpus: GasCorpus = CorpusLoader.load_corpus(CORPUS_PATH)
	if corpus.files.is_empty() and corpus.statements.is_empty():
		push_error("bench_soak: corpus is empty: %s" % CORPUS_PATH)
		quit(1)
		return

	var profiler: GASProfiler = GASProfiler.new()
	var config: GASInterpreterConfig = GASInterpreterConfig.new()
	config.function_mode = GASInterpreterConfig.FunctionMode.REGISTRY_AND_LIBRARY
	config.library_paths = ["res://function_libraries"]
	config.profiler = profiler
	config.file_cache_limit = 24
	config.ast_cache_limit = 48
	config.rng.seed = RNG_SEED

	var interpreter: GASInterpreter = GASInterpreter.new(config)
	if not interpreter.get_init_result().ok:
		push_error("bench_soak: interpreter init failed")
		quit(1)
		return

	_seed_symbols(interpreter)
	var file_counts: Dictionary[String, int] = _count_files(corpus)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = RNG_SEED

	profiler.reset()
	print("soak benchmark: %.0f s at %.0f fps" % [DURATION_SEC, TARGET_FPS])
	var start_usec: int = Time.get_ticks_usec()
	var duration_usec: int = int(DURATION_SEC * 1_000_000.0)

	var total_statements: int = 0
	var total_turns: int = 0
	var total_errors: int = 0
	var total_warnings: int = 0

	while Time.get_ticks_usec() - start_usec < duration_usec:
		var turn: Dictionary = _run_turn(interpreter, corpus, file_counts, rng)
		total_statements += int(turn.get("statements", 0))
		total_errors += int(turn.get("errors", 0))
		total_warnings += int(turn.get("warnings", 0))
		total_turns += 1

	var wall_usec: int = Time.get_ticks_usec() - start_usec
	var elapsed_sec: float = float(wall_usec) / 1_000_000.0
	if elapsed_sec <= 0.0:
		elapsed_sec = 0.000001

	var statements_per_second: float = float(total_statements) / elapsed_sec
	var statements_per_frame: float = statements_per_second / TARGET_FPS

	var ast_hit_pct: float = _hit_percent(profiler.ast_cache_hits, profiler.ast_cache_misses)
	var ast_miss_pct: float = _miss_percent(profiler.ast_cache_hits, profiler.ast_cache_misses)
	var file_hit_pct: float = _hit_percent(profiler.file_cache_hits, profiler.file_cache_misses)
	var file_miss_pct: float = _miss_percent(profiler.file_cache_hits, profiler.file_cache_misses)

	print("soak results")
	print("  elapsed_sec: %.2f" % elapsed_sec)
	print("  turns: %d" % total_turns)
	print("  total_statements: %d" % total_statements)
	print("  errors: %d  warnings: %d" % [total_errors, total_warnings])
	print("  statements_per_second: %.1f" % statements_per_second)
	print("  statements_per_frame (%.0f fps): %.1f" % [TARGET_FPS, statements_per_frame])
	print("  ast_cache: hits=%d misses=%d  %s hit / %s miss" % [
		profiler.ast_cache_hits,
		profiler.ast_cache_misses,
		_fmt_pct(ast_hit_pct),
		_fmt_pct(ast_miss_pct),
	])
	print("  file_cache: hits=%d misses=%d  %s hit / %s miss" % [
		profiler.file_cache_hits,
		profiler.file_cache_misses,
		_fmt_pct(file_hit_pct),
		_fmt_pct(file_miss_pct),
	])

	print("")
	TIMING_REPORTER.print_report(profiler, wall_usec, total_turns)
	TIMING_REPORTER.export_text("user://soak_timings.txt", profiler, wall_usec, total_turns)
	TIMING_REPORTER.export_json("user://soak_timings.json", profiler, wall_usec, total_turns)

	quit(0)

func _run_turn(
	interpreter: GASInterpreter,
	corpus: GasCorpus,
	file_counts: Dictionary[String, int],
	rng: RandomNumberGenerator
) -> Dictionary:
	interpreter.clear_queue()
	var statements: int = 0

	if not corpus.files.is_empty():
		var file: CorpusFile = _pick_file(rng, corpus)
		if interpreter.enqueue_file(file.path, file.priority_base):
			statements += int(file_counts.get(file.path, 0))

	if not corpus.statements.is_empty():
		var max_amount: int = corpus.target_statement_count
		if max_amount <= 0:
			max_amount = corpus.statements.size()
		max_amount = maxi(1, max_amount)
		var amount: int = rng.randi_range(1, max_amount)
		for i: int in range(amount):
			var statement: CorpusStatement = _pick_statement(rng, corpus)
			if interpreter.enqueue(statement.source, statement.priority):
				statements += 1

	var result: GASResult = interpreter.flush()
	return {
		"statements": statements,
		"errors": result.errors.size(),
		"warnings": result.warnings.size(),
	}

func _pick_file(rng: RandomNumberGenerator, corpus: GasCorpus) -> CorpusFile:
	var total: float = 0.0
	for f: CorpusFile in corpus.files:
		total += f.weight
	var roll: float = rng.randf() * total
	var cumulative: float = 0.0
	for f: CorpusFile in corpus.files:
		cumulative += f.weight
		if roll <= cumulative:
			return f
	return corpus.files[corpus.files.size() - 1]

func _pick_statement(rng: RandomNumberGenerator, corpus: GasCorpus) -> CorpusStatement:
	var total: float = 0.0
	for s: CorpusStatement in corpus.statements:
		total += s.weight
	var roll: float = rng.randf() * total
	var cumulative: float = 0.0
	for s: CorpusStatement in corpus.statements:
		cumulative += s.weight
		if roll <= cumulative:
			return s
	return corpus.statements[corpus.statements.size() - 1]

func _count_files(corpus: GasCorpus) -> Dictionary[String, int]:
	var counter: GASStatementCounter = GASStatementCounter.new()
	var counts: Dictionary[String, int] = {}
	for f: CorpusFile in corpus.files:
		counts[f.path] = counter.count_file(f.path)
	return counts

func _seed_symbols(interpreter: GASInterpreter) -> void:
	interpreter.set_variable("a", 2.0)
	interpreter.set_variable("b", 3.0)
	interpreter.set_variable("c", 4.0)
	interpreter.set_variable("physical", 10.0)
	interpreter.set_variable("fire", 5.0)
	interpreter.set_variable("ice", 3.0)
	interpreter.set_variable("resistance", 2.0)
	interpreter.set_variable("strength", 14.0)
	interpreter.set_variable("hp", 20.0)
	interpreter.set_variable("max_hp", 20.0)
	interpreter.set_variable("mana", 12.0)
	interpreter.set_variable("max_mana", 12.0)
	interpreter.set_variable("armor", 6.0)
	interpreter.set_variable("level", 4.0)
	interpreter.set_variable("crit_chance", 0.25)
	interpreter.set_variable("crit_multiplier", 1.5)
	interpreter.set_variable("dodge", 0.15)
	interpreter.set_variable("healing", 8.0)
	interpreter.set_variable("poison", 3.0)
	interpreter.set_variable("burn", 2.0)
	interpreter.set_variable("v0", 0.0)

func _hit_percent(hits: int, misses: int) -> float:
	var total: int = hits + misses
	if total <= 0:
		return -1.0
	return float(hits) / float(total) * 100.0

func _miss_percent(hits: int, misses: int) -> float:
	var total: int = hits + misses
	if total <= 0:
		return -1.0
	return float(misses) / float(total) * 100.0

func _fmt_pct(pct: float) -> String:
	if pct < 0.0:
		return "n/a"
	return "%.1f%%" % pct
