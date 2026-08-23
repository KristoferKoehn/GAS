class_name GASScript
extends RefCounted

var path: String = ""
var modified_time: int = 0
var blocks: Array[GASSourceBlock] = []

func _init(p_path: String = "", p_modified_time: int = 0, p_blocks: Array[GASSourceBlock] = []) -> void:
	path = p_path
	modified_time = p_modified_time
	blocks = p_blocks
