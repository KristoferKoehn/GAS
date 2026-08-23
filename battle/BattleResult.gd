class_name BattleResult
extends RefCounted

var gas_result: GASResult

func _init(p_gas_result: GASResult = null) -> void:
	gas_result = p_gas_result

func get_ok() -> bool:
	return gas_result != null and gas_result.ok

func get_symbols() -> Dictionary[String, Variant]:
	if gas_result == null:
		return {}
	return gas_result.symbol_table

func get_errors() -> Array[GASError]:
	if gas_result == null:
		return []
	return gas_result.errors

func get_warnings() -> Array[GASError]:
	if gas_result == null:
		return []
	return gas_result.warnings
