extends Control

@onready var label: Label = $Label

func _ready() -> void:
	var config: GASInterpreterConfig = GASInterpreterConfig.new()
	config.function_mode = GASInterpreterConfig.FunctionMode.REGISTRY_AND_LIBRARY
	config.library_paths = ["res://function_libraries"]

	var interpreter: GASInterpreter = GASInterpreter.new(config)
	if not interpreter.get_init_result().ok:
		label.text = "GAS Language\nError: %s" % _format_errors(interpreter.get_init_result().errors)
		return

	var attacker: Entity = Entity.new("goblin", {
		"strength": 14.0,
		"wisdom": 8.0,
		"intelligence": 6.0,
	}, [
		"[10] $physical = $strength + 2d6 #longsword",
		"[10] $fire = $wisdom * $intelligence #firebolt",
		"[10] $ice = $intelligence + 2d4 #ice lance",
	])

	var defender: Entity = Entity.new("guard", {
		"resistance": 4.0,
		"fire_resistance": 0.10,
	}, [
		"[20] $physical = $physical * 0.85 #chainmail",
		"[20] $fire = $fire * (1 - $fire_resistance) #amulet of flame warding",
	])

	var battle_config: BattleConfiguration = BattleConfiguration.new()
	battle_config.calculator_path = "res://GASScripts/calculator.gas"
	battle_config.attacker_stats = {
		"strength": "strength",
		"wisdom": "wisdom",
		"intelligence": "intelligence",
	}
	battle_config.defender_stats = {
		"resistance": "resistance",
		"fire_resistance": "fire_resistance",
	}
	battle_config.functions = {
		"attack_stat": BattleConfiguration.Role.ATTACKER,
		"defense_stat": BattleConfiguration.Role.DEFENDER,
	}

	var context: BattleContext = BattleContext.new(attacker, defender, battle_config, interpreter)
	var battle_result: BattleResult = context.run()

	if battle_result.get_ok():
		label.text = "GAS Language\nFinal damage: %s\n\n%s" % [
			str(battle_result.get_symbols().get("final_damage", 0)),
			_format_symbols(battle_result.get_symbols()),
		]
	else:
		label.text = "GAS Language\nError: %s" % _format_errors(battle_result.get_errors())


func _format_errors(errors: Array[GASError]) -> String:
	var text: String = ""
	for i: int in range(errors.size()):
		if i > 0:
			text += "; "
		text += errors[i].message
	return text


func _format_symbols(symbols: Dictionary[String, Variant]) -> String:
	var keys: Array = symbols.keys()
	keys.sort()
	var text: String = ""
	for key: Variant in keys:
		text += "%s = %s\n" % [key, str(symbols[key])]
	return text.strip_edges()
