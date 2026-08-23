# GAS Language: Public API Walkthrough

This document walks through the public interface of the GAS expression system and shows how to drive it from GDScript. It covers the `GASCore/` language, the optional `battle/` and `entities/` layers, and the example `function_libraries/`. Benchmarks and tests are out of scope.

## Architecture in one paragraph

Source text flows through `Lexer` to `Token`s, then `PrattParser` to an `Expr` AST, then `Evaluator` to a value. `GASInterpreter` is the facade you use. It parses expressions through `GASPipeline`, caches ASTs, queues them by priority, and evaluates them against one shared `GASEnvironment`. Function calls resolve through `GASFunctionRegistry` (explicit and library entries), then an optional external fallback handler.

The public classes you interact with directly are:

- `GASInterpreter`
- `GASInterpreterConfig`
- `GASResult`
- `GASError`
- `GASProfiler` / `GASProfilerSnapshot`
- `Entity`, `BattleConfiguration`, `BattleContext`, `BattleResult` (battle layer)

Everything else in `GASCore/` is an implementation detail.

## What to copy

Copy these folders into your project:

- `GASCore/`: the language itself. Required.
- `battle/`: `BattleConfiguration`, `BattleContext`, `BattleResult`. Required only for battle orchestration.
- `entities/`: the `Entity` data class. Required for battle, optional for raw GAS use.
- `function_libraries/`: example libraries for dice, math, and arrays. Copy them or write your own.

## Execution model: enqueue, then flush

The interpreter separates parsing from evaluation.

1. Call `enqueue`, `enqueue_blocks`, or `enqueue_file`. Each parses its source now and stores the AST in a priority queue. A parse failure returns `false` and records the error.
2. Call `flush`. It evaluates every queued expression in priority order and returns one `GASResult`.

Lower priority numbers run first. Entries with equal priority run in the order they were enqueued.

```gdscript
var interpreter: GASInterpreter = GASInterpreter.new(_make_config())

interpreter.enqueue("$total = 0", 100)
interpreter.enqueue("$total = $total + 1", 50)
interpreter.enqueue("$total = $total * 10", 200)

var result: GASResult = interpreter.flush()
print(result.value)       # 10: +1 at 50, =0 at 100, *10 at 200
print(result.symbol_table) # { "total": 10.0 }
```

`flush` also collects parse errors from any failed `enqueue` call. Check `result.ok` before using `result.value`.

## Step 1: configure the interpreter

Create a `GASInterpreterConfig`, set fields, then pass it to `GASInterpreter`.

```gdscript
var config: GASInterpreterConfig = GASInterpreterConfig.new()
config.function_mode = GASInterpreterConfig.FunctionMode.REGISTRY_AND_LIBRARY
config.library_paths = ["res://function_libraries"]
config.rng.seed = 12345

var interpreter: GASInterpreter = GASInterpreter.new(config)
if not interpreter.get_init_result().ok:
    for error: GASError in interpreter.get_init_result().errors:
        push_error(error.message)
    return
```

The config is frozen the moment it is passed to `GASInterpreter`. Set every field, seed the RNG, and populate `library_paths` before construction. Later reassignment of a config field pushes an error and is ignored.

### `GASInterpreterConfig` fields

| Field | Type | Default | Read |
|---|---|---|---|
| `function_mode` | `FunctionMode` | `REGISTRY_AND_LIBRARY` | evaluation time |
| `auto_load_libraries` | `bool` | `true` | construction time |
| `library_paths` | `Array[String]` | `[]` | construction and `reload_libraries` |
| `library_search_recursive` | `bool` | `true` | construction and `reload_libraries` |
| `library_conflict` | `LibraryConflict` | `REGISTRY_WINS` | library load |
| `enable_external_fallback` | `bool` | `false` | evaluation time |
| `external_call_handler` | `Callable` | `Callable()` | evaluation time |
| `default_missing_symbol` | `Variant` | `0` | evaluation time |
| `missing_symbol_is_error` | `bool` | `false` | evaluation time |
| `ast_cache_limit` | `int` | `256` | copied at construction |
| `file_cache_limit` | `int` | `64` | copied at construction |
| `rng` | `RandomNumberGenerator` | new instance | reference fixed at construction |
| `profiler` | `GASProfiler` | `null` | construction time |

### `FunctionMode` values

- `NONE`: no registered or library functions resolve. Only the external fallback, if enabled, can handle calls.
- `REGISTRY_ONLY`: only functions added with `register_function` resolve.
- `LIBRARY_ONLY`: only functions loaded from `library_paths` resolve.
- `REGISTRY_AND_LIBRARY`: explicit registrations win, then library entries.

### `LibraryConflict` values

When a library exports a name that is already explicitly registered:

- `REGISTRY_WINS`: the library entry is skipped.
- `LIBRARY_WINS`: the explicit entry is removed and the library entry is used.
- `REPORT_CONFLICT`: the library entry is skipped and a warning is recorded.

### Seeding dice

`config.rng` is the shared random source for dice expressions and for any library that declares an `rng` property. Set its seed before construction for deterministic rolls.

```gdscript
config.rng.seed = 42
```

## Step 2: variables

Variables are stored in one shared environment. Set them before enqueueing expressions that read them.

```gdscript
interpreter.set_variable("strength", 14.0)
interpreter.set_variable("resistance", 4.0)

interpreter.enqueue("$damage = $strength - $resistance")
var result: GASResult = interpreter.flush()
print(result.value) # 10.0
```

Related methods:

- `set_variable(name: String, value: Variant) -> void`
- `get_variable(name: String) -> Variant`
- `has_variable(name: String) -> bool`
- `clear_variables() -> void`
- `get_symbol_count() -> int`

A missing variable resolves to `default_missing_symbol` (default `0`) when `missing_symbol_is_error` is `false`. Set `missing_symbol_is_error` to `true` to get an evaluation error instead; `get_variable` then returns `null` for a missing name.

```gdscript
config.missing_symbol_is_error = true
config.default_missing_symbol = 1
```

The `$` prefix is the conventional way to reference a variable. A bare identifier that is not followed by `(` is also treated as a symbol, so `strength` and `$strength` name the same variable.

## Step 3: functions

Register functions from GDScript.

```gdscript
interpreter.register_function("double", func(value: float) -> float: return value * 2.0)

interpreter.register_functions({
    "triple": func(value: float) -> float: return value * 3.0,
    "negate": func(value: float) -> float: return -value,
})

interpreter.enqueue("$result = double(21) + triple(1)")
```

Related methods:

- `register_function(name: String, function: Callable) -> void`
- `register_functions(entries: Dictionary[String, Callable]) -> void`
- `has_function(name: String) -> bool`
- `clear_functions() -> void`

`clear_functions` clears explicit registrations only. Library entries stay until `reload_libraries`.

`has_function` honors the configured `function_mode`.

### External fallback

When a call name is unresolved, the interpreter can route it to a GDScript handler.

```gdscript
config.enable_external_fallback = true
config.external_call_handler = _handle_external
```

The handler signature is `func(name: String, args: Array) -> Variant`.

```gdscript
func _handle_external(name: String, args: Array) -> Variant:
    if name == "triple" and args.size() == 1:
        return float(args[0]) * 3.0
    return 0
```

Set the handler before construction. It runs only when neither the explicit registry nor the library registry resolves the name, regardless of `function_mode`.

## Step 4: function libraries

A library is a `.gd` script extending `RefCounted` with a `metadata` dictionary mapping names to `Callable`s.

```gdscript
# res://function_libraries/my_lib.gd
extends RefCounted

var metadata: Dictionary[String, Callable] = {
    "triple": _triple,
    "half": _half,
}

var rng: RandomNumberGenerator


func _triple(value: float) -> float:
    return value * 3.0


func _half(value: float) -> float:
    return value / 2.0
```

Point `library_paths` at the directory. Scanning is recursive by default.

```gdscript
config.function_mode = GASInterpreterConfig.FunctionMode.REGISTRY_AND_LIBRARY
config.library_paths = ["res://function_libraries"]
config.library_search_recursive = true
```

If a library declares `var rng: RandomNumberGenerator`, the loader injects the interpreter's configured RNG into it. Dice libraries then share the same deterministic state as GAS dice expressions.

Call `reload_libraries()` to rescan after editing a library file. It returns a `GASResult`.

```gdscript
var reload: GASResult = interpreter.reload_libraries()
if not reload.ok:
    for error: GASError in reload.errors:
        push_error(error.message)
```

## Step 5: `.gas` files and priority blocks

A `.gas` file holds statements grouped into `[N]` blocks, where `N` is the priority.

```
[10]
$attack = $strength + 2d6

[30]
$final = max(0, $attack - $resistance)
```

Load and run a file:

```gdscript
interpreter.set_variable("strength", 14.0)
interpreter.set_variable("resistance", 4.0)

interpreter.enqueue_file("res://GASScripts/calculator.gas")
var result: GASResult = interpreter.flush()
print(result.symbol_table.get("final", 0))
```

`enqueue_file(path, base_priority)` adds `base_priority` to every block priority in the file. `enqueue_blocks(source, base_priority)` does the same for inline text.

```gdscript
interpreter.enqueue_blocks("""
[20] $x = 2
[10] $x = 1
""", 5)
# block 10 becomes 15, block 20 becomes 25
```

Text without any `[N]` marker is treated as a single block with priority `0`.

Loaded files are cached by path and modification time. Editing a file invalidates its cache entry on the next load. The cache holds at most `file_cache_limit` scripts.

## Step 6: results and errors

`flush` returns a `GASResult`.

```gdscript
class_name GASResult
extends RefCounted

var ok: bool
var value: Variant
var errors: Array[GASError]
var warnings: Array[GASError]
var symbol_table: Dictionary[String, Variant]

func first_error() -> GASError
```

- `ok` is `false` when any error occurred during parse or evaluation.
- `value` is the value of the last evaluated queued expression.
- `symbol_table` is a snapshot copy of all variables after the flush.
- `warnings` carry non-fatal problems, such as a library conflict under `REPORT_CONFLICT`.

`GASError` carries a code, message, line, and column.

```gdscript
if not result.ok:
    for error: GASError in result.errors:
        push_error("%s (line %d)" % [error.message, error.line])
```

Error codes: `LEXICAL`, `PARSE`, `EVALUATION`, `IO`, `FUNCTION_NOT_FOUND`, `DIVISION_BY_ZERO`, `INVALID_ARGUMENT`.

The interpreter emits `evaluation_failed(result: GASResult)` whenever a `flush` result is not `ok`.

```gdscript
interpreter.evaluation_failed.connect(_on_evaluation_failed)

func _on_evaluation_failed(result: GASResult) -> void:
    print(result.first_error().message)
```

## Step 7: profiler

Pass a `GASProfiler` through the config to collect cumulative counters.

```gdscript
var profiler: GASProfiler = GASProfiler.new()
config.profiler = profiler
var interpreter: GASInterpreter = GASInterpreter.new(config)

interpreter.enqueue("$x = 1 + 2")
interpreter.flush()

var snap: GASProfilerSnapshot = profiler.snapshot()
print(snap.parse_count)
print(snap.evaluate_usec)
print(snap.ast_cache_hits)
print(snap.file_cache_misses)
print(snap.max_queue_depth)
```

`interpreter.get_profiler()` returns the same instance. `GASProfiler.reset()` zeroes every counter. `snapshot()` copies the counters into a `GASProfilerSnapshot`, which is useful for capturing deltas without mutating the live counters.

## Step 8: language syntax reference

- Numbers: `14`, `2.5`. Both are stored as floats.
- Strings: `"strength"`. No escape sequences.
- Variables: `$strength`.
- Dice: `2d6`. Both sides are non-negative integers; sides must be greater than zero.
- Booleans: `true`, `false`.
- Arithmetic: `+ - * / % ^`. `^` is exponentiation and is right-associative.
- Comparison: `== != < <= > >=`.
- Logic: `and`, `or`, `not`, `&&`, `||`, `!`.
- Assignment: `$x = 5`. Right-associative.
- Grouping: `( ... )`.
- Arrays: `[1, 2, 3]`, `[]`.
- Function calls: `floor(2.7)`, `max(0, $damage)`.
- Comments: `#` and `//`. Block comments are not supported.
- Statements: separate with newlines or `;`. A block returns its last value.
- Priority blocks in `.gas` files: `[30] ...`.

Division by zero and modulo by zero produce a `DIVISION_BY_ZERO` error and return `0`. Dice with non-positive sides produce an `EVALUATION` error and return `0`.

## Step 9: the battle layer

The battle layer is a declarative wrapper over the interpreter. Use it to compute stat-driven results between two `Entity` instances.

```gdscript
var attacker: Entity = Entity.new("goblin", {
    "strength": 14.0,
}, [
    "[10] $damage = $strength + 2d6 #longsword",
])

var defender: Entity = Entity.new("guard", {
    "resistance": 4.0,
}, [
    "[20] $damage = $damage * 0.85 #chainmail",
])
```

`Entity` holds a name, a stat dictionary, and an array of `[N]`-prefixed statement strings.

`BattleConfiguration` is a `Resource`.

| Field | Type | Purpose |
|---|---|---|
| `calculator_path` | `String` | `.gas` file enqueued after statements |
| `attacker_stats` | `Dictionary[String, String]` | maps an attacker stat key to a GAS variable name |
| `defender_stats` | `Dictionary[String, String]` | maps a defender stat key to a GAS variable name |
| `functions` | `Dictionary[String, int]` | maps a function name to `BattleConfiguration.Role.ATTACKER` or `DEFENDER` |
| `calculator_base_priority` | `int` | priority offset for the calculator file |
| `statement_base_priority` | `int` | priority offset for entity statements |

The `functions` map generates one stat accessor per role. The generated function takes one stat key string and returns that entity's stat value.

```gdscript
var battle_config: BattleConfiguration = BattleConfiguration.new()
battle_config.calculator_path = "res://GASScripts/calculator.gas"
battle_config.attacker_stats = { "strength": "strength" }
battle_config.defender_stats = { "resistance": "resistance" }
battle_config.functions = {
    "attack_stat": BattleConfiguration.Role.ATTACKER,
    "defense_stat": BattleConfiguration.Role.DEFENDER,
}
```

`BattleContext.run` clears variables, queue, and explicit functions, seeds the stat variables, registers the role functions, enqueues the calculator and statements, flushes, and returns a `BattleResult`.

```gdscript
var context: BattleContext = BattleContext.new(attacker, defender, battle_config, interpreter)
var battle_result: BattleResult = context.run()

if battle_result.get_ok():
    print(battle_result.get_symbols().get("final_damage", 0))
else:
    for error: GASError in battle_result.get_errors():
        push_error(error.message)
```

`BattleResult` wraps the underlying `GASResult` with `get_ok()`, `get_symbols()`, `get_errors()`, and `get_warnings()`.

## Complete example: raw GAS, no battle

```gdscript
extends Node

func run_raw() -> void:
    var config: GASInterpreterConfig = GASInterpreterConfig.new()
    config.function_mode = GASInterpreterConfig.FunctionMode.REGISTRY_AND_LIBRARY
    config.library_paths = ["res://function_libraries"]
    config.rng.seed = 7

    var interpreter: GASInterpreter = GASInterpreter.new(config)
    if not interpreter.get_init_result().ok:
        push_error(interpreter.get_init_result().first_error().message)
        return

    interpreter.set_variable("strength", 14.0)
    interpreter.set_variable("resistance", 4.0)

    interpreter.register_function("triple", func(value: float) -> float: return value * 3.0)

    interpreter.enqueue("$attack = $strength + 2d6", 10)
    interpreter.enqueue("$final = max(0, triple($attack) - $resistance)", 30)

    var result: GASResult = interpreter.flush()

    if result.ok:
        print("final = ", result.symbol_table.get("final", 0))
    else:
        for error: GASError in result.errors:
            push_error(error.message)
```

## Complete example: battle

```gdscript
extends Node

func run_battle() -> void:
    var config: GASInterpreterConfig = GASInterpreterConfig.new()
    config.function_mode = GASInterpreterConfig.FunctionMode.REGISTRY_AND_LIBRARY
    config.library_paths = ["res://function_libraries"]

    var interpreter: GASInterpreter = GASInterpreter.new(config)
    if not interpreter.get_init_result().ok:
        push_error(interpreter.get_init_result().first_error().message)
        return

    var attacker: Entity = Entity.new("goblin", {
        "strength": 14.0,
    }, [
        "[10] $damage = $strength + 2d6 #longsword",
    ])

    var defender: Entity = Entity.new("guard", {
        "resistance": 4.0,
    }, [
        "[20] $damage = $damage * 0.85 #chainmail",
    ])

    var battle_config: BattleConfiguration = BattleConfiguration.new()
    battle_config.calculator_path = "res://GASScripts/calculator.gas"
    battle_config.attacker_stats = { "strength": "strength" }
    battle_config.defender_stats = { "resistance": "resistance" }
    battle_config.functions = {
        "attack_stat": BattleConfiguration.Role.ATTACKER,
        "defense_stat": BattleConfiguration.Role.DEFENDER,
    }

    var context: BattleContext = BattleContext.new(attacker, defender, battle_config, interpreter)
    var result: BattleResult = context.run()

    if result.get_ok():
        print("Final damage: ", result.get_symbols().get("final_damage", 0))
    else:
        for error: GASError in result.get_errors():
            push_error(error.message)
```

## Gotchas

- The default `function_mode` is `REGISTRY_AND_LIBRARY` and `auto_load_libraries` is `true`. Constructing with an empty `library_paths` makes `get_init_result()` fail with `"library mode is active but library_paths is empty"`. Set `library_paths`, or set `function_mode` to `REGISTRY_ONLY`, or set `auto_load_libraries` to `false`.
- The config freezes after construction. Seed `rng` and populate `library_paths` before `GASInterpreter.new(config)`.
- `enqueue`, `enqueue_blocks`, and `enqueue_file` return `false` on parse errors. The errors surface in the next `flush` result, not as exceptions.
- `flush` drains the queue. Reuse one interpreter across many flushes; `BattleContext.run` clears variables, queue, and explicit functions each time, but library functions persist.
- `res://` paths are case-sensitive on some platforms. Point `calculator_path` and `library_paths` at the exact directory names on disk.
- `result.value` is the value of the last evaluated queued expression, not a merged total. Read final outputs from `result.symbol_table`.
- The signal `evaluation_failed` fires only when a `flush` result is not `ok`.
