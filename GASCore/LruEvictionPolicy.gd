class_name LruEvictionPolicy
extends RefCounted

var _order: Dictionary[String, int] = {}

func note_hit(key: String) -> void:
	_refresh(key)

func note_store(key: String) -> void:
	_refresh(key)

func note_evict(key: String) -> void:
	_order.erase(key)

func clear() -> void:
	_order.clear()

func oldest() -> Variant:
	if _order.is_empty():
		return null
	return _order.keys()[0]

func _refresh(key: String) -> void:
	if _order.has(key):
		_order.erase(key)
	_order[key] = 0
