class_name GASSourceBlock
extends RefCounted

var priority: int = 0
var source: String = ""

func _init(p_priority: int = 0, p_source: String = "") -> void:
	priority = p_priority
	source = p_source
