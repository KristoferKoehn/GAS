class_name GASEnvironment
extends RefCounted

var _variables: Dictionary[String, Variant] = {}
var _registry: GASFunctionRegistry
var _config: GASInterpreterConfig

func _init(registry: GASFunctionRegistry, config: GASInterpreterConfig) -> void:
	_registry = registry
	_config = config

func get_variable(name: String) -> Variant:
	if _variables.has(name):
		return _variables[name]
	if _config.missing_symbol_is_error:
		return null
	return _config.default_missing_symbol

func set_variable(name: String, value: Variant) -> void:
	_variables[name] = value

func has_variable(name: String) -> bool:
	return _variables.has(name)

func clear_variables() -> void:
	_variables.clear()

func resolve_registered(name: String) -> Callable:
	return _registry.resolve(name, _config.function_mode)

func can_call_external() -> bool:
	return _config.enable_external_fallback and _config.external_call_handler.is_valid()

func call_external(name: String, args: Array) -> Variant:
	return _config.external_call_handler.call(name, args)

func get_symbol_snapshot() -> Dictionary[String, Variant]:
	var copy: Dictionary[String, Variant] = {}
	for key: String in _variables:
		copy[key] = _variables[key]
	return copy

func get_symbol_count() -> int:
	return _variables.size()
