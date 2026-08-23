class_name GASError
extends RefCounted

enum Code {
	LEXICAL,
	PARSE,
	EVALUATION,
	IO,
	FUNCTION_NOT_FOUND,
	DIVISION_BY_ZERO,
	INVALID_ARGUMENT,
}

var code: Code = Code.EVALUATION
var message: String = ""
var line: int = 0
var column: int = 0
var source: String = ""

func _init(p_code: Code, p_message: String, p_line: int = 0, p_column: int = 0) -> void:
	code = p_code
	message = p_message
	line = p_line
	column = p_column

func _to_string() -> String:
	return "GASError(%s: %s at %d:%d)" % [Code.keys()[code], message, line, column]
