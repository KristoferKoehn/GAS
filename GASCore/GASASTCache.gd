class_name GASAstCache
extends RefCounted

var _entries: Dictionary[String, Expr] = {}
var _policy: LruEvictionPolicy
var _limit: int = 256

func _init(limit: int, policy: LruEvictionPolicy = null) -> void:
	_limit = limit
	_policy = policy if policy != null else LruEvictionPolicy.new()

func get_ast(source: String) -> Expr:
	if _entries.has(source):
		_policy.note_hit(source)
		return _entries[source]
	return null

func store(source: String, ast: Expr) -> void:
	_entries[source] = ast
	_policy.note_store(source)
	_enforce_limit()

func clear() -> void:
	_entries.clear()
	_policy.clear()

func size() -> int:
	return _entries.size()

func _enforce_limit() -> void:
	while _entries.size() > _limit:
		var oldest: Variant = _policy.oldest()
		if oldest == null or not _entries.has(oldest as String):
			break
		var oldest_key: String = oldest as String
		_entries.erase(oldest_key)
		_policy.note_evict(oldest_key)
