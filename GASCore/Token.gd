class_name Token
extends RefCounted

const TokenType = AST.TokenType

var type: int
var lexeme: String
var literal: Variant
var line: int
var column: int

func _init(p_type: int, p_lexeme: String, p_literal: Variant, p_line: int, p_column: int = 0) -> void:
	type = p_type
	lexeme = p_lexeme
	literal = p_literal
	line = p_line
	column = p_column

func output() -> String:
	return "Token(%s, %s, %s)" % [TokenType.keys()[type], lexeme, str(literal)]
