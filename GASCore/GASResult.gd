class_name GASResult
extends RefCounted

var ok: bool = false
var value: Variant = null
var errors: Array[GASError] = []
var warnings: Array[GASError] = []
var symbol_table: Dictionary[String, Variant] = {}

func _init(
	p_ok: bool,
	p_value: Variant,
	p_errors: Array[GASError] = [],
	p_warnings: Array[GASError] = [],
	p_symbol_table: Dictionary[String, Variant] = {}
) -> void:
	ok = p_ok
	value = p_value
	errors = p_errors
	warnings = p_warnings
	symbol_table = p_symbol_table

func first_error() -> GASError:
	if errors.is_empty():
		return null
	return errors[0]
