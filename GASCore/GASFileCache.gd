class_name GASFileCache
extends RefCounted

var _entries: Dictionary[String, GASScript] = {}
var _policy: LruEvictionPolicy
var _limit: int = 64

func _init(limit: int, policy: LruEvictionPolicy = null) -> void:
	_limit = limit
	_policy = policy if policy != null else LruEvictionPolicy.new()

func fetch(path: String, modified_time: int) -> GASScript:
	if not _entries.has(path):
		return null
	var script: GASScript = _entries[path]
	if script.modified_time != modified_time:
		_entries.erase(path)
		_policy.note_evict(path)
		return null
	_policy.note_hit(path)
	return script

func store(path: String, script: GASScript) -> void:
	_entries[path] = script
	_policy.note_store(path)
	_enforce_limit()

func invalidate(path: String) -> void:
	_entries.erase(path)
	_policy.note_evict(path)

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
