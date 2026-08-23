class_name Entity
extends RefCounted

var entity_name: String
var stats: Dictionary[String, Variant]
var statements: Array[String] = []

func _init(p_name: String = "", p_stats: Dictionary[String, Variant] = {}, p_statements: Array[String] = []) -> void:
	entity_name = p_name
	stats = p_stats
	statements = p_statements

func get_stat(key: String, default_value: Variant = 0) -> Variant:
	return stats.get(key, default_value)

func has_stat(key: String) -> bool:
	return stats.has(key)
