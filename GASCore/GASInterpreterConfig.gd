class_name GASInterpreterConfig
extends RefCounted

enum FunctionMode {
	NONE,
	REGISTRY_ONLY,
	LIBRARY_ONLY,
	REGISTRY_AND_LIBRARY,
}

enum LibraryConflict {
	REGISTRY_WINS,
	LIBRARY_WINS,
	REPORT_CONFLICT,
}

var _frozen: bool = false

## Which function sources the interpreter consults at evaluation time.
## Read at evaluation time.
var function_mode: FunctionMode = FunctionMode.REGISTRY_AND_LIBRARY:
	set(value):
		if _frozen:
			_reject_frozen_write()
			return
		function_mode = value

## Whether the interpreter loads libraries during construction.
## Read at construction time.
var auto_load_libraries: bool = true:
	set(value):
		if _frozen:
			_reject_frozen_write()
			return
		auto_load_libraries = value

## Directories scanned for function libraries.
## Read at construction time and by [method reload_libraries].
## Assign the full contents before construction. Do not mutate in place afterward.
var library_paths: Array[String] = []:
	set(value):
		if _frozen:
			_reject_frozen_write()
			return
		library_paths = value

## Whether library scanning descends into subdirectories.
## Read at construction time and by [method reload_libraries].
var library_search_recursive: bool = true:
	set(value):
		if _frozen:
			_reject_frozen_write()
			return
		library_search_recursive = value

## How the loader resolves a name that is both explicitly registered and loaded from a library.
## [enum LibraryConflict] values are [constant REGISTRY_WINS], [constant LIBRARY_WINS], and [constant REPORT_CONFLICT].
var library_conflict: LibraryConflict = LibraryConflict.REGISTRY_WINS:
	set(value):
		if _frozen:
			_reject_frozen_write()
			return
		library_conflict = value

## Whether unresolved function names fall back to [member external_call_handler].
## Read at evaluation time.
var enable_external_fallback: bool = false:
	set(value):
		if _frozen:
			_reject_frozen_write()
			return
		enable_external_fallback = value

## Handler called for unresolved function names when [member enable_external_fallback] is [code]true[/code].
## Signature: [code]func(name: String, args: Array) -> Variant[/code].
## Read at evaluation time. Set before construction.
var external_call_handler: Callable = Callable():
	set(value):
		if _frozen:
			_reject_frozen_write()
			return
		external_call_handler = value

## Value returned for an undefined symbol when [member missing_symbol_is_error] is [code]false[/code].
## Read at evaluation time.
var default_missing_symbol: Variant = 0:
	set(value):
		if _frozen:
			_reject_frozen_write()
			return
		default_missing_symbol = value

## Whether referencing an undefined symbol produces an evaluation error.
## Read at evaluation time.
var missing_symbol_is_error: bool = false:
	set(value):
		if _frozen:
			_reject_frozen_write()
			return
		missing_symbol_is_error = value

## Maximum number of cached parsed ASTs.
## Copied at construction time. Later edits have no effect.
var ast_cache_limit: int = 256:
	set(value):
		if _frozen:
			_reject_frozen_write()
			return
		ast_cache_limit = value

## Maximum number of cached loaded scripts.
## Copied at construction time. Later edits have no effect.
var file_cache_limit: int = 64:
	set(value):
		if _frozen:
			_reject_frozen_write()
			return
		file_cache_limit = value

## Shared random source for dice expressions and libraries that declare an [code]rng[/code] property.
## The reference is fixed after construction; its internal state (for example the seed) stays mutable.
## Seed it before construction for deterministic rolls.
var rng: RandomNumberGenerator = RandomNumberGenerator.new():
	set(value):
		if _frozen:
			_reject_frozen_write()
			return
		rng = value

## Optional profiler written to when non-null.
## Read at construction time. Set before construction.
var profiler: GASProfiler = null:
	set(value):
		if _frozen:
			_reject_frozen_write()
			return
		profiler = value

## Locks all fields. Called by [GASInterpreter] during construction.
## After this, top-level reassignment of any field pushes an error.
func freeze() -> void:
	_frozen = true

func _reject_frozen_write() -> void:
	push_error("GASInterpreterConfig is frozen after being passed to GASInterpreter")
