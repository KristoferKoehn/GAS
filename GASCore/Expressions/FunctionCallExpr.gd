class_name FunctionCallExpr extends Expr

var name: String
var args: Array  # Array of Expr

func _init(p_name: String, p_args: Array):
	name = p_name
	args = p_args