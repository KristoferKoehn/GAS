class_name BinaryExpr extends Expr

var left: Expr
var operator: Token
var right: Expr

func _init(p_left: Expr, p_operator: Token, p_right: Expr):
	left = p_left
	operator = p_operator
	right = p_right