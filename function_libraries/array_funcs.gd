extends RefCounted

## Test GAS function library: array helpers.
##
## Each key in `metadata` is the name callable from a GAS script.
## The value is a method reference (Callable) defined in this file.

var metadata: Dictionary[String, Callable] = {
	"sum": _sum,
	"average": _average,
	"count": _count,
}


func _sum(values: Array) -> float:
	var total: float = 0.0
	for value: Variant in values:
		total += float(value)
	return total


func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	return _sum(values) / float(values.size())


func _count(values: Array) -> int:
	return values.size()
