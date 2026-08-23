class_name Lexer
extends RefCounted

const TokenType = AST.TokenType

var source: String
var tokens: Array[Token] = []
var errors: Array[GASError] = []
var current_pos: int = 0
var line: int = 1
var column: int = 1
var _compiled: Array[Dictionary] = []

var keywords: Dictionary = {
	"not": TokenType.NOT,
	"and": TokenType.AND,
	"or": TokenType.OR,
	"true": TokenType.NUMBER,
	"false": TokenType.NUMBER,
}

var patterns: Array = [
	{"regex": "\\s+", "type": null, "skip": true},
	{"regex": "#[^\\n]*", "type": null, "skip": true},
	{"regex": "//[^\\n]*", "type": null, "skip": true},
	{"regex": ";", "type": TokenType.SEMICOLON},
	{"regex": "\\d+d\\d+", "type": TokenType.DICE, "handler": "handle_dice"},
	{"regex": "\\d+\\.\\d+", "type": TokenType.NUMBER, "handler": "handle_number"},
	{"regex": "\\d+", "type": TokenType.NUMBER, "handler": "handle_number"},
	{"regex": '"[^"]*"', "type": TokenType.STRING, "handler": "handle_string"},
	{"regex": "\\$[a-zA-Z_][a-zA-Z0-9_]*", "type": TokenType.SYMBOL, "handler": "handle_symbol"},
	{"regex": "[a-zA-Z_][a-zA-Z0-9_]*", "type": null, "handler": "handle_identifier"},
	{"regex": "==", "type": TokenType.EQUAL},
	{"regex": "!=", "type": TokenType.NOT_EQUAL},
	{"regex": "<=", "type": TokenType.LESS_EQUAL},
	{"regex": ">=", "type": TokenType.GREATER_EQUAL},
	{"regex": "&&", "type": TokenType.AND},
	{"regex": "\\|\\|", "type": TokenType.OR},
	{"regex": "=", "type": TokenType.ASSIGN},
	{"regex": "\\+", "type": TokenType.PLUS},
	{"regex": "-", "type": TokenType.MINUS},
	{"regex": "\\*", "type": TokenType.MULTIPLY},
	{"regex": "/", "type": TokenType.DIVIDE},
	{"regex": "%", "type": TokenType.MODULO},
	{"regex": "\\^", "type": TokenType.POWER},
	{"regex": "<", "type": TokenType.LESS},
	{"regex": ">", "type": TokenType.GREATER},
	{"regex": "!", "type": TokenType.NOT},
	{"regex": "\\(", "type": TokenType.LPAREN},
	{"regex": "\\)", "type": TokenType.RPAREN},
	{"regex": "\\[", "type": TokenType.LBRACKET},
	{"regex": "\\]", "type": TokenType.RBRACKET},
	{"regex": ",", "type": TokenType.COMMA},
	{"regex": ".", "type": TokenType.UNKNOWN},
]

func _init(p_source: String) -> void:
	source = p_source
	_compile_patterns()
	scan_tokens()

func _compile_patterns() -> void:
	for pattern: Dictionary in patterns:
		var regex: RegEx = RegEx.new()
		regex.compile(pattern.get("regex") as String)
		var handler: Callable = Callable()
		if pattern.has("handler"):
			handler = Callable(self, pattern.get("handler") as String)
		_compiled.append({
			"regex": regex,
			"type": pattern.get("type"),
			"skip": pattern.get("skip", false),
			"handler": handler,
		})

func scan_tokens() -> void:
	while current_pos < source.length():
		var matched: bool = false

		for entry: Dictionary in _compiled:
			var match: RegExMatch = (entry.get("regex") as RegEx).search(source, current_pos)

			if match != null and match.get_start() == current_pos:
				var lexeme: String = match.get_string()
				var start_line: int = line
				var start_column: int = column
				var type_value: Variant = entry.get("type")

				if bool(entry.get("skip", false)):
					_advance_lexeme(lexeme)
					matched = true
					break

				var handler: Callable = entry.get("handler") as Callable
				if handler.is_valid():
					var literal: Variant = handler.call(lexeme)
					var token_type: int = TokenType.UNKNOWN
					var token_literal: Variant = null

					if typeof(literal) == TYPE_DICTIONARY:
						var dict: Dictionary = literal as Dictionary
						token_type = int(dict.get("type", TokenType.UNKNOWN))
						token_literal = dict.get("literal", null)
					else:
						token_type = int(type_value)
						token_literal = literal

					tokens.append(Token.new(token_type, lexeme, token_literal, start_line, start_column))
				else:
					tokens.append(Token.new(int(type_value), lexeme, null, start_line, start_column))

				_advance_lexeme(lexeme)
				matched = true
				break

		if not matched:
			var unexpected: String = source.substr(current_pos, 1)
			errors.append(GASError.new(GASError.Code.LEXICAL, "Unexpected character '%s'" % unexpected, line, column))
			_advance_lexeme(unexpected)

	tokens.append(Token.new(TokenType.EOF, "", null, line, column))

func _advance_lexeme(lexeme: String) -> void:
	current_pos += lexeme.length()
	for i: int in range(lexeme.length()):
		var ch: String = lexeme[i]
		if ch == "\n":
			line += 1
			column = 1
		else:
			column += 1

func handle_number(lexeme: String) -> Variant:
	return float(lexeme)

func handle_string(lexeme: String) -> Variant:
	return lexeme.substr(1, lexeme.length() - 2)

func handle_symbol(lexeme: String) -> Variant:
	return lexeme.substr(1)

func handle_dice(lexeme: String) -> Variant:
	var parts: PackedStringArray = lexeme.split("d")
	return [int(parts[0]), int(parts[1])]

func handle_identifier(lexeme: String) -> Variant:
	if keywords.has(lexeme):
		var type_value: int = int(keywords[lexeme])
		if lexeme == "true":
			return {"type": type_value, "literal": true}
		elif lexeme == "false":
			return {"type": type_value, "literal": false}
		return {"type": type_value, "literal": null}
	return {"type": TokenType.IDENTIFIER, "literal": lexeme}
