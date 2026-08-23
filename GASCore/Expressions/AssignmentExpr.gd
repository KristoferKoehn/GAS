class_name AssignmentExpr extends Expr

var name: Token
var value: Expr

func _init(p_name: Token, p_value: Expr):
	name = p_name
	value = p_value