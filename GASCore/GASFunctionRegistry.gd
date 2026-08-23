class_name GASFunctionRegistry
extends RefCounted

var _explicit: Dictionary[String, Callable] = {}
var _library: Dictionary[String, Callable] = {}

func register(name: String, function: Callable) -> void:
	_explicit[name] = function

func register_many(entries: Dictionary[String, Callable]) -> void:
	for name: String in entries:
		_explicit[name] = entries[name]

func unregister_explicit(name: String) -> void:
	_explicit.erase(name)

func add_library_entry(name: String, function: Callable, conflict: GASInterpreterConfig.LibraryConflict) -> bool:
	if _explicit.has(name):
		match conflict:
			GASInterpreterConfig.LibraryConflict.REGISTRY_WINS:
				return false
			GASInterpreterConfig.LibraryConflict.REPORT_CONFLICT:
				return false
			GASInterpreterConfig.LibraryConflict.LIBRARY_WINS:
				_explicit.erase(name)
	_library[name] = function
	return true

func add_library_entries(entries: Dictionary[String, Callable], conflict: GASInterpreterConfig.LibraryConflict) -> Array[String]:
	var conflicts: Array[String] = []
	for name: String in entries:
		if not add_library_entry(name, entries[name], conflict):
			conflicts.append(name)
	return conflicts

func resolve(name: String, mode: GASInterpreterConfig.FunctionMode) -> Callable:
	match mode:
		GASInterpreterConfig.FunctionMode.REGISTRY_ONLY:
			return _explicit.get(name, Callable()) as Callable
		GASInterpreterConfig.FunctionMode.LIBRARY_ONLY:
			return _library.get(name, Callable()) as Callable
		GASInterpreterConfig.FunctionMode.REGISTRY_AND_LIBRARY:
			if _explicit.has(name):
				return _explicit[name]
			return _library.get(name, Callable()) as Callable
		_:
			return Callable()

func clear_library() -> void:
	_library.clear()

func clear_explicit() -> void:
	_explicit.clear()

func clear() -> void:
	_explicit.clear()
	_library.clear()
