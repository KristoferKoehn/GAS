class_name UnaryExpr extends Expr

var operator: Token
var right: Expr

func _init(p_operator: Token, p_right: Expr):
	operator = p_operator
	right = p_right