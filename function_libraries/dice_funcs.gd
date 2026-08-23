extends RefCounted

## Test GAS function library: dice rolls.
##
## Each key in `metadata` is the name callable from a GAS script.
## The value is a method reference (Callable) defined in this file.

var metadata: Dictionary[String, Callable] = {
	"roll": _roll,
	"d20": _d20,
	"d6": _d6,
	"advantage": _advantage,
	"disadvantage": _disadvantage,
}

var rng: RandomNumberGenerator


func _rand(min_value: int, max_value: int) -> int:
	if rng != null:
		return rng.randi_range(min_value, max_value)
	return randi_range(min_value, max_value)


func _roll(count: int, sides: int) -> int:
	var total: int = 0
	for i: int in range(count):
		total += _rand(1, sides)
	return total


func _d20() -> int:
	return _rand(1, 20)


func _d6() -> int:
	return _rand(1, 6)


func _advantage() -> int:
	return maxi(_d20(), _d20())


func _disadvantage() -> int:
	return mini(_d20(), _d20())
