class_name GASFunctionLibraryLoader
extends RefCounted

var _registry: GASFunctionRegistry
var _config: GASInterpreterConfig
var _instances : Array[RefCounted]

func _init(registry: GASFunctionRegistry, config: GASInterpreterConfig) -> void:
	_registry = registry
	_config = config

func reload() -> GASResult:
	_registry.clear_library()
	_instances.clear()

	var errors: Array[GASError] = []
	var warnings: Array[GASError] = []

	if not _library_mode_active():
		return GASResult.new(true, null, errors, warnings, {})

	if _config.library_paths.is_empty():
		errors.append(GASError.new(GASError.Code.IO, "library mode is active but library_paths is empty"))
		return GASResult.new(false, null, errors, warnings, {})

	for path: String in _config.library_paths:
		_scan_dir(path, errors, warnings)

	return GASResult.new(errors.is_empty(), null, errors, warnings, {})

func _library_mode_active() -> bool:
	return _config.function_mode == GASInterpreterConfig.FunctionMode.LIBRARY_ONLY \
		or _config.function_mode == GASInterpreterConfig.FunctionMode.REGISTRY_AND_LIBRARY

func _scan_dir(dir_path: String, errors: Array[GASError], warnings: Array[GASError]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		errors.append(GASError.new(GASError.Code.IO, "Could not open function folder: %s" % dir_path))
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if _config.library_search_recursive:
				_scan_dir(dir_path.path_join(file_name), errors, warnings)
		elif file_name.ends_with(".gd"):
			_load_script(dir_path.path_join(file_name), errors, warnings)
		file_name = dir.get_next()
	dir.list_dir_end()

func _load_script(script_path: String, errors: Array[GASError], warnings: Array[GASError]) -> void:
	var script: Script = load(script_path) as Script
	if script == null:
		errors.append(GASError.new(GASError.Code.IO, "Could not load function library: %s" % script_path))
		return

	var instance: RefCounted = script.new() as RefCounted
	if instance == null:
		errors.append(GASError.new(GASError.Code.IO, "Could not instantiate function library: %s" % script_path))
		return
	_instances.append(instance)

	if "rng" in instance:
		instance.set("rng", _config.rng)

	var metadata_value: Variant = instance.get("metadata")
	if metadata_value == null or typeof(metadata_value) != TYPE_DICTIONARY:
		errors.append(GASError.new(GASError.Code.INVALID_ARGUMENT, "Function library has no metadata Dictionary: %s" % script_path))
		return

	var metadata: Dictionary = metadata_value as Dictionary
	var entries: Dictionary[String, Callable] = {}

	for key: Variant in metadata:
		if typeof(key) != TYPE_STRING:
			errors.append(GASError.new(GASError.Code.INVALID_ARGUMENT, "metadata key is not a String in %s" % script_path))
			continue
		var key_str: String = key as String
		var value: Variant = metadata[key_str]
		if typeof(value) != TYPE_CALLABLE:
			errors.append(GASError.new(GASError.Code.INVALID_ARGUMENT, "metadata entry '%s' is not a Callable in %s" % [key_str, script_path]))
			continue
		entries[key_str] = value as Callable

	var conflicts: Array[String] = _registry.add_library_entries(entries, _config.library_conflict)
	for conflict_name: String in conflicts:
		warnings.append(GASError.new(GASError.Code.INVALID_ARGUMENT, "Function '%s' from %s conflicts with an explicit registration" % [conflict_name, script_path]))
