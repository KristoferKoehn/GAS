class_name AST


# Token types
enum TokenType {
	# Literals
	NUMBER,
	STRING,
	SYMBOL,      # $variable
	DICE,        # 2d6
	
	# Operators
	PLUS,
	MINUS,
	MULTIPLY,
	DIVIDE,
	MODULO,
	POWER,
	
	# Comparison
	EQUAL,
	NOT_EQUAL,
	LESS,
	LESS_EQUAL,
	GREATER,
	GREATER_EQUAL,
	
	# Logical
	AND,
	OR,
	NOT,

	#funcion names
	IDENTIFIER,
	
	# Grouping
	LPAREN,
	RPAREN,
	LBRACKET,
	RBRACKET,
	
	# Assignment
	ASSIGN,
	
	# Functions
	COMMA,
	
	SEMICOLON,

	# Special
	EOF,
	UNKNOWN
}
