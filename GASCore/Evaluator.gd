class_name Evaluator
extends RefCounted

const TokenType = AST.TokenType

var _environment: GASEnvironment
var _config: GASInterpreterConfig
var errors: Array[GASError] = []

func _init(environment: GASEnvironment, config: GASInterpreterConfig) -> void:
	_environment = environment
	_config = config

func evaluate(expr: Expr) -> GASResult:
	errors.clear()
	var value: Variant = _evaluate_inner(expr)
	var error_copy: Array[GASError] = _copy_errors()
	var snapshot: Dictionary[String, Variant] = _environment.get_symbol_snapshot()
	return GASResult.new(errors.is_empty(), value, error_copy, [], snapshot)

func _copy_errors() -> Array[GASError]:
	var copy: Array[GASError] = []
	for e: GASError in errors:
		copy.append(e)
	return copy

func _evaluate_inner(expr: Expr) -> Variant:
	if expr == null:
		return 0

	if expr is BinaryExpr:
		return evaluate_binary(expr as BinaryExpr)
	elif expr is AssignmentExpr:
		return evaluate_assignment(expr as AssignmentExpr)
	elif expr is BlockExpr:
		return evaluate_block(expr as BlockExpr)
	elif expr is FunctionCallExpr:
		return evaluate_function_call(expr as FunctionCallExpr)
	elif expr is ArrayExpr:
		return evaluate_array(expr as ArrayExpr)
	elif expr is LiteralExpr:
		return evaluate_literal(expr as LiteralExpr)
	elif expr is SymbolExpr:
		return evaluate_symbol(expr as SymbolExpr)
	elif expr is DiceExpr:
		return evaluate_dice(expr as DiceExpr)
	elif expr is UnaryExpr:
		return evaluate_unary(expr as UnaryExpr)
	elif expr is GroupingExpr:
		var grouping: GroupingExpr = expr as GroupingExpr
		return _evaluate_inner(grouping.expression)

	return 0

func evaluate_function_call(expr: FunctionCallExpr) -> Variant:
	var fn: Callable = _environment.resolve_registered(expr.name)

	if fn.is_valid():
		var evaluated_args: Array = []
		for arg: Expr in expr.args:
			evaluated_args.append(_evaluate_inner(arg))
		return fn.callv(evaluated_args)

	if _environment.can_call_external():
		var evaluated_args: Array = []
		for arg: Expr in expr.args:
			evaluated_args.append(_evaluate_inner(arg))
		return _environment.call_external(expr.name, evaluated_args)

	errors.append(GASError.new(GASError.Code.FUNCTION_NOT_FOUND, "Undefined function '%s'" % expr.name))
	return 0

func evaluate_literal(expr: LiteralExpr) -> Variant:
	return expr.value

func evaluate_symbol(expr: SymbolExpr) -> Variant:
	if not _environment.has_variable(expr.name):
		if _config.missing_symbol_is_error:
			errors.append(GASError.new(GASError.Code.EVALUATION, "Undefined variable '$%s'" % expr.name))
			return null
		return _config.default_missing_symbol
	return _environment.get_variable(expr.name)

func evaluate_dice(expr: DiceExpr) -> Variant:
	if expr.sides <= 0:
		errors.append(GASError.new(GASError.Code.EVALUATION, "Dice sides must be positive"))
		return 0
	var total: int = 0
	for i: int in range(expr.count):
		total += _config.rng.randi_range(1, expr.sides)
	return total

func evaluate_binary(expr: BinaryExpr) -> Variant:
	var left: Variant = _evaluate_inner(expr.left)
	var right: Variant = _evaluate_inner(expr.right)

	match expr.operator.type:
		TokenType.PLUS:
			return left + right
		TokenType.MINUS:
			return left - right
		TokenType.MULTIPLY:
			return left * right
		TokenType.DIVIDE:
			if right == 0:
				errors.append(GASError.new(GASError.Code.DIVISION_BY_ZERO, "Division by zero"))
				return 0
			return left / right
		TokenType.MODULO:
			var right_int: int = int(right)
			if right_int == 0:
				errors.append(GASError.new(GASError.Code.DIVISION_BY_ZERO, "Modulo by zero"))
				return 0
			return int(left) % right_int
		TokenType.POWER:
			return pow(left, right)
		TokenType.EQUAL:
			return left == right
		TokenType.NOT_EQUAL:
			return left != right
		TokenType.LESS:
			return left < right
		TokenType.LESS_EQUAL:
			return left <= right
		TokenType.GREATER:
			return left > right
		TokenType.GREATER_EQUAL:
			return left >= right
		TokenType.AND:
			return left and right
		TokenType.OR:
			return left or right

	return 0

func evaluate_unary(expr: UnaryExpr) -> Variant:
	var right: Variant = _evaluate_inner(expr.right)

	match expr.operator.type:
		TokenType.MINUS:
			return -right
		TokenType.NOT:
			return not right

	return right

func evaluate_assignment(expr: AssignmentExpr) -> Variant:
	var value: Variant = _evaluate_inner(expr.value)
	_environment.set_variable(expr.name.literal as String, value)
	return value

func evaluate_array(expr: ArrayExpr) -> Array:
	var result: Array = []
	for element: Expr in expr.elements:
		result.append(_evaluate_inner(element))
	return result

func evaluate_block(expr: BlockExpr) -> Variant:
	var last_result: Variant = 0
	for stmt: Expr in expr.statements:
		last_result = _evaluate_inner(stmt)
	return last_result
