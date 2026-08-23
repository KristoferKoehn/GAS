class_name GASProfiler
extends RefCounted

var ast_cache_hits: int = 0
var ast_cache_misses: int = 0
var file_cache_hits: int = 0
var file_cache_misses: int = 0
var parse_count: int = 0
var parse_usec: int = 0
var evaluate_count: int = 0
var evaluate_usec: int = 0
var enqueue_count: int = 0
var enqueue_usec: int = 0
var flush_count: int = 0
var flush_usec: int = 0
var error_count: int = 0
var warning_count: int = 0
var max_queue_depth: int = 0
var symbol_count: int = 0
var ast_cache_size: int = 0
var file_cache_size: int = 0

func reset() -> void:
	ast_cache_hits = 0
	ast_cache_misses = 0
	file_cache_hits = 0
	file_cache_misses = 0
	parse_count = 0
	parse_usec = 0
	evaluate_count = 0
	evaluate_usec = 0
	enqueue_count = 0
	enqueue_usec = 0
	flush_count = 0
	flush_usec = 0
	error_count = 0
	warning_count = 0
	max_queue_depth = 0
	symbol_count = 0
	ast_cache_size = 0
	file_cache_size = 0

func snapshot() -> GASProfilerSnapshot:
	var snap: GASProfilerSnapshot = GASProfilerSnapshot.new()
	snap.ast_cache_hits = ast_cache_hits
	snap.ast_cache_misses = ast_cache_misses
	snap.file_cache_hits = file_cache_hits
	snap.file_cache_misses = file_cache_misses
	snap.parse_count = parse_count
	snap.parse_usec = parse_usec
	snap.evaluate_count = evaluate_count
	snap.evaluate_usec = evaluate_usec
	snap.enqueue_count = enqueue_count
	snap.enqueue_usec = enqueue_usec
	snap.flush_count = flush_count
	snap.flush_usec = flush_usec
	snap.error_count = error_count
	snap.warning_count = warning_count
	snap.max_queue_depth = max_queue_depth
	snap.symbol_count = symbol_count
	snap.ast_cache_size = ast_cache_size
	snap.file_cache_size = file_cache_size
	return snap
