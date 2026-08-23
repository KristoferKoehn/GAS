class_name GASProfilerSnapshot
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
