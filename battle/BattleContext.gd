class_name BattleContext
extends RefCounted

var _attacker: Entity
var _defender: Entity
var _config: BattleConfiguration
var _interpreter: GASInterpreter

func _init(attacker: Entity, defender: Entity, config: BattleConfiguration, interpreter: GASInterpreter) -> void:
	_attacker = attacker
	_defender = defender
	_config = config
	_interpreter = interpreter

func run() -> BattleResult:
	_interpreter.clear_variables()
	_interpreter.clear_queue()
	_interpreter.clear_functions()
	_seed_variables()
	_register_functions()
	_enqueue_calculator()
	_enqueue_statements()
	return BattleResult.new(_interpreter.flush())

func _seed_variables() -> void:
	for stat_key: String in _config.attacker_stats:
		_interpreter.set_variable(_config.attacker_stats[stat_key], _attacker.get_stat(stat_key))
	for stat_key: String in _config.defender_stats:
		_interpreter.set_variable(_config.defender_stats[stat_key], _defender.get_stat(stat_key))

func _register_functions() -> void:
	var attacker: Entity = _attacker
	var defender: Entity = _defender
	var entries: Dictionary[String, Callable] = {}

	for function_name: String in _config.functions:
		var role: int = _config.functions[function_name]
		if role == BattleConfiguration.Role.ATTACKER:
			entries[function_name] = func(key: String) -> Variant: return attacker.get_stat(key)
		elif role == BattleConfiguration.Role.DEFENDER:
			entries[function_name] = func(key: String) -> Variant: return defender.get_stat(key)

	_interpreter.register_functions(entries)

func _enqueue_calculator() -> bool:
	if _config.calculator_path.strip_edges().is_empty():
		return true
	return _interpreter.enqueue_file(_config.calculator_path, _config.calculator_base_priority)

func _enqueue_statements() -> bool:
	var entities: Array[Entity] = [_attacker, _defender]
	for entity: Entity in entities:
		for statement: String in entity.statements:
			if not _interpreter.enqueue_blocks(statement, _config.statement_base_priority):
				return false
	return true
