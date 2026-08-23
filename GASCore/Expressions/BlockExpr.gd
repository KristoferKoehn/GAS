class_name BlockExpr extends Expr

var statements: Array  # Array of Expr
func _init(p_statements: Array):
	statements = p_statements