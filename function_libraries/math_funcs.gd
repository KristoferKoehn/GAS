extends RefCounted

## Test GAS function library: scalar math.
##
## Each key in `metadata` is the name callable from a GAS script.
## The value is a method reference (Callable) defined in this file.

var metadata: Dictionary[String, Callable] = {
	"floor": _floor,
	"ceil": _ceil,
	"abs": _abs,
	"max": _max,
	"min": _min,
	"clamp": _clamp,
}


func _floor(value: Variant) -> int:
	return floori(value)


func _ceil(value: Variant) -> int:
	return ceili(value)


func _abs(value: Variant) -> Variant:
	if typeof(value) == TYPE_INT:
		return absi(value)
	return absf(value)


func _max(a: Variant, b: Variant) -> Variant:
	return a if a > b else b


func _min(a: Variant, b: Variant) -> Variant:
	return a if a < b else b


func _clamp(value: Variant, low: Variant, high: Variant) -> Variant:
	return max(min(value, high), low)
