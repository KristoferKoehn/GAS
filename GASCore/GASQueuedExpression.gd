class_name GASQueuedExpression
extends RefCounted

var priority: int = 0
var expression: Expr
var source: String = ""

func _init(p_priority: int, p_expression: Expr, p_source: String = "") -> void:
	priority = p_priority
	expression = p_expression
	source = p_source
