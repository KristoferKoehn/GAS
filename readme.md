# GAS Language

A declarative formula engine for Godot 4.7, built for RPG combat math.

GAS turns tangled stat and damage logic into small, ordered, composable
expressions. Write formulas in `.gas` files, register functions from
GDScript, roll dice, and let priority blocks decide what applies first.

Built for games where numbers matter: RPGs, roguelikes, tactics games,
and anything with modifiers that stack, resist, and interact.

## Why GAS

Combat math is a pipeline, not one formula. Base damage, then gear, then
armor, then resistances, then status effects, then a final cap.
Hard-coding that order gets brittle the moment you add a new mechanic.

GAS models the pipeline as ordered blocks. Each block reads and writes
variables. Lower priorities run first, so attacker, defender, and global
rules compose without touching each other's code.

## Highlights

- **Dice with deterministic output.** `2d6`, `3d8`, and `d20()` share one
  seedable RNG. Set a seed and every roll is reproducible.
- **Three ways to add functions.** GDScript callables, `.gd` libraries
  through a `metadata` dictionary, or an external fallback handler.
- **Priority blocks.** `[10]`, `[20]`, `[30]` set execution order.
  Design content, not control flow.
- **Batch and flush.** Enqueue many expressions, parse once, evaluate in
  priority order.
- **Caching included.** AST and file caches with LRU eviction and
  modification-time invalidation.
- **Structured errors.** Every run returns `ok`, `value`, errors,
  warnings, and a symbol snapshot.
- **Optional profiler.** Track parse, evaluate, enqueue, flush, and
  cache-hit timing.

## Install

Copy into your Godot 4.7 project:

- `GASCore/` (required)
- `battle/` and `entities/` (for the battle layer)
- `function_libraries/` (example libraries, or write your own)

## Quick start

```gdscript
var config: GASInterpreterConfig = GASInterpreterConfig.new()
config.function_mode = GASInterpreterConfig.FunctionMode.REGISTRY_AND_LIBRARY
config.library_paths = ["res://function_libraries"]
config.rng.seed = 7

var interpreter: GASInterpreter = GASInterpreter.new(config)
interpreter.set_variable("strength", 14.0)
interpreter.enqueue("$damage = $strength + 2d6")
var result: GASResult = interpreter.flush()
print(result.symbol_table["damage"])
```

## Battle example

```gas
# Attacker, runs at priority 10
[10]
$damage = $strength + 2d6

# Defender, runs at priority 20
[20]
$damage = $damage * 0.85
```

Compose those with `BattleContext` and read the final value from the
result. The full walkthrough is in `documentation.md`.

## Project structure

| Path | Purpose |
|------|---------|
| `GASCore/` | Language core: lexer, parser, evaluator, interpreter, config, results, caches, profiler |
| `GASCore/Expressions/` | AST node classes |
| `battle/` | Battle orchestration over the interpreter |
| `entities/` | `Entity` data class |
| `function_libraries/` | Example libraries for dice, math, and arrays |
| `GASScripts/` | Example `.gas` formula files |
| `benchmarks/` | Corpus soak benchmark and its support files |
| `main.gd`, `main.tscn` | Runnable demo scene |
| `documentation.md` | Public API walkthrough with examples |
| `project_index.md` | Architectural index |

## Documentation

- `documentation.md`: public API walkthrough with examples
- `project_index.md`: architectural map

## License

0BSD (Zero-Clause BSD). Use, modify, and distribute freely.
See [LICENSE](LICENSE).
