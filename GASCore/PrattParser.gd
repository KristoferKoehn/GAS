class_name PrattParser
extends RefCounted

const TokenType = AST.TokenType

var tokens: Array[Token]
var current: int = 0
var errors: Array[GASError] = []

enum Precedence {
	NONE,
	ASSIGNMENT,
	LOGICAL,
	COMPARISON,
	TERM,
	FACTOR,
	POWER,
	UNARY,
	CALL,
	PRIMARY,
}

const BINARY_INFIX: Dictionary = {
	TokenType.OR: {"precedence": Precedence.LOGICAL, "right_assoc": false},
	TokenType.AND: {"precedence": Precedence.LOGICAL, "right_assoc": false},
	TokenType.EQUAL: {"precedence": Precedence.COMPARISON, "right_assoc": false},
	TokenType.NOT_EQUAL: {"precedence": Precedence.COMPARISON, "right_assoc": false},
	TokenType.LESS: {"precedence": Precedence.COMPARISON, "right_assoc": false},
	TokenType.LESS_EQUAL: {"precedence": Precedence.COMPARISON, "right_assoc": false},
	TokenType.GREATER: {"precedence": Precedence.COMPARISON, "right_assoc": false},
	TokenType.GREATER_EQUAL: {"precedence": Precedence.COMPARISON, "right_assoc": false},
	TokenType.PLUS: {"precedence": Precedence.TERM, "right_assoc": false},
	TokenType.MINUS: {"precedence": Precedence.TERM, "right_assoc": false},
	TokenType.MULTIPLY: {"precedence": Precedence.FACTOR, "right_assoc": false},
	TokenType.DIVIDE: {"precedence": Precedence.FACTOR, "right_assoc": false},
	TokenType.MODULO: {"precedence": Precedence.FACTOR, "right_assoc": false},
	TokenType.POWER: {"precedence": Precedence.POWER, "right_assoc": true},
}

var prefix_parselets: Dictionary = {}
var infix_parselets: Dictionary = {}

func _init(p_tokens: Array[Token]) -> void:
	tokens = p_tokens
	register_parselets()

func register_parselets() -> void:
	prefix_parselets[TokenType.NUMBER] = func(_parser: PrattParser, token: Token) -> Expr:
		return LiteralExpr.new(token.literal)
	prefix_parselets[TokenType.STRING] = func(_parser: PrattParser, token: Token) -> Expr:
		return LiteralExpr.new(token.literal)
	prefix_parselets[TokenType.SYMBOL] = func(_parser: PrattParser, token: Token) -> Expr:
		return SymbolExpr.new(token.literal as String)
	prefix_parselets[TokenType.DICE] = func(_parser: PrattParser, token: Token) -> Expr:
		var parts: Array = token.literal as Array
		return DiceExpr.new(int(parts[0]), int(parts[1]))
	prefix_parselets[TokenType.LPAREN] = func(parser: PrattParser, _token: Token) -> Expr:
		var inner: Expr = parser.parse_expression()
		parser.consume(TokenType.RPAREN, "Expect ')' after expression.")
		return GroupingExpr.new(inner)
	prefix_parselets[TokenType.MINUS] = func(parser: PrattParser, token: Token) -> Expr:
		var inner: Expr = parser.parse_expression(Precedence.UNARY)
		return UnaryExpr.new(token, inner)
	prefix_parselets[TokenType.NOT] = func(parser: PrattParser, token: Token) -> Expr:
		var inner: Expr = parser.parse_expression(Precedence.UNARY)
		return UnaryExpr.new(token, inner)
	prefix_parselets[TokenType.IDENTIFIER] = func(parser: PrattParser, token: Token) -> Expr:
		if parser.check(TokenType.LPAREN):
			return parser.parse_function_call(token)
		return SymbolExpr.new(token.literal as String)
	prefix_parselets[TokenType.LBRACKET] = func(parser: PrattParser, _token: Token) -> Expr:
		var elements: Array = []
		if not parser.check(TokenType.RBRACKET):
			elements.append(parser.parse_expression())
			while parser.check(TokenType.COMMA):
				parser.advance()
				elements.append(parser.parse_expression())
		parser.consume(TokenType.RBRACKET, "Expect ']' after array elements.")
		return ArrayExpr.new(elements)

	for type_key: Variant in BINARY_INFIX:
		var entry: Dictionary = BINARY_INFIX[type_key]
		var prec: int = int(entry["precedence"])
		var right_assoc: bool = bool(entry["right_assoc"])
		infix_parselets[int(type_key)] = {
			"precedence": prec,
			"right_assoc": right_assoc,
			"parse": Callable(self, "_parse_binary").bind(prec, right_assoc),
		}

	infix_parselets[TokenType.ASSIGN] = {
		"precedence": Precedence.ASSIGNMENT,
		"right_assoc": true,
		"parse": Callable(self, "_parse_assignment"),
	}

	infix_parselets[TokenType.NOT] = {
		"precedence": Precedence.ASSIGNMENT,
		"right_assoc": false,
		"parse": Callable(),
	}

func parse() -> Expr:
	var statements: Array[Expr] = []

	while not is_at_end():
		var stmt: Expr = parse_expression()
		if stmt != null:
			statements.append(stmt)

		if check(TokenType.SEMICOLON):
			advance()

		if is_at_end():
			break

	if statements.size() == 1:
		return statements[0]
	if statements.is_empty():
		return null
	return BlockExpr.new(statements)

func parse_expression(precedence: int = Precedence.ASSIGNMENT) -> Expr:
	var token: Token = advance()
	var prefix_value: Variant = prefix_parselets.get(token.type)

	if prefix_value == null:
		error("Expected expression. : %s " % token.lexeme, token.line)
		return null

	var prefix: Callable = prefix_value as Callable
	var left: Expr = prefix.call(self, token) as Expr

	while precedence <= get_precedence(peek().type):
		token = advance()
		var entry_value: Variant = infix_parselets.get(token.type)
		if entry_value == null:
			break
		var entry: Dictionary = entry_value as Dictionary
		var _parse: Callable = entry.get("parse") as Callable
		if not _parse.is_valid():
			error("invalid parselet type %s " % TokenType.keys()[token.type], 0)
			break
		left = _parse.call(self, left, token) as Expr

	return left

func _parse_binary(parser: PrattParser, left: Expr, token: Token, precedence: int, right_assoc: bool) -> Expr:
	var next: int = precedence if right_assoc else precedence + 1
	var right: Expr = parser.parse_expression(next)
	return BinaryExpr.new(left, token, right)

func _parse_assignment(parser: PrattParser, left: Expr, token: Token) -> Expr:
	var symbol: SymbolExpr = left as SymbolExpr
	if symbol == null:
		error("Invalid assignment target.", token.line)
		return null
	var value: Expr = parser.parse_expression(Precedence.ASSIGNMENT)
	return AssignmentExpr.new(Token.new(TokenType.SYMBOL, symbol.name, symbol.name, token.line), value)

func parse_function_call(name_token: Token) -> FunctionCallExpr:
	consume(TokenType.LPAREN, "Expect '(' after function name.")

	var args: Array = []
	if not check(TokenType.RPAREN):
		args.append(parse_expression())
		while check(TokenType.COMMA):
			advance()
			args.append(parse_expression())

	consume(TokenType.RPAREN, "Expect ')' after arguments.")
	return FunctionCallExpr.new(name_token.literal as String, args)

func get_precedence(type: int) -> int:
	var entry_value: Variant = infix_parselets.get(type)
	if entry_value == null:
		return Precedence.NONE
	return int((entry_value as Dictionary).get("precedence", Precedence.NONE))

func consume(type: int, message: String) -> Token:
	if check(type):
		return advance()
	error(message, peek().line)
	return null

func check(type: int) -> bool:
	if is_at_end():
		return false
	return peek().type == type

func advance() -> Token:
	if not is_at_end():
		current += 1
	return previous()

func peek() -> Token:
	return tokens[current]

func previous() -> Token:
	return tokens[current - 1]

func is_at_end() -> bool:
	return peek().type == TokenType.EOF

func error(message: String, line: int) -> void:
	errors.append(GASError.new(GASError.Code.PARSE, message, line))
