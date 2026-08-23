# Project Index: GASLanguage

Architectural map of the GASLanguage Godot 4.7 project.
Lists every tracked class and script. Scope excludes `.godot/` (engine cache), `.vscode/` (editor settings), and `*.uid` files.

## Core language

| Path | Category | Primary Purpose | Dependencies |
|------|----------|-----------------|--------------|
| `GASCore/AST.gd` | Script (RefCounted, class_name AST) | Token type enum holder. | None |
| `GASCore/Token.gd` | Script (RefCounted, class_name Token) | Lexer output: type, lexeme, literal, line, column. | AST |
| `GASCore/Lexer.gd` | Script (RefCounted, class_name Lexer) | Regex tokenizer; collects lexical errors. | AST, Token, GASError |
| `GASCore/PrattParser.gd` | Script (RefCounted, class_name PrattParser) | Pratt parser producing Expr nodes. | AST, Token, GASError, Expressions |
| `GASCore/Evaluator.gd` | Script (RefCounted, class_name Evaluator) | Tree-walking evaluator over Expr against an environment. | GASEnvironment, GASInterpreterConfig, GASResult, GASError, Expressions |
| `GASCore/GASEnvironment.gd` | Script (RefCounted, class_name GASEnvironment) | Variable store, function resolution, external fallback, symbol snapshots. | GASFunctionRegistry, GASInterpreterConfig |
| `GASCore/GASFunctionRegistry.gd` | Script (RefCounted, class_name GASFunctionRegistry) | Explicit and library function maps with conflict policy. | GASInterpreterConfig |
| `GASCore/GASFunctionLibraryLoader.gd` | Script (RefCounted, class_name GASFunctionLibraryLoader) | Scans directories for `.gd` scripts exposing a `metadata` dictionary; injects the configured RNG into libraries that declare an `rng` property. | GASFunctionRegistry, GASInterpreterConfig, GASError, GASResult |
| `GASCore/GASScriptLoader.gd` | Script (RefCounted, class_name GASScriptLoader) | Loads `.gas` files, splits priority blocks, parses each block, records file cache hits and misses. | GASFileCache, GASPipeline, GASInterpreterConfig, GASBlockSplitter, GASScript, GASSourceBlock, GASResult, GASError, GASProfiler |
| `GASCore/GASBlockSplitter.gd` | Script (RefCounted, class_name GASBlockSplitter) | Splits `[N]`-prefixed source into priority blocks. | None |
| `GASCore/GASPipeline.gd` | Script (RefCounted, class_name GASPipeline) | Parse plus evaluate with AST cache; tracks parse errors and profiler counters. | GASEnvironment, GASAstCache, GASInterpreterConfig, Lexer, PrattParser, Evaluator, GASResult, GASError, GASProfiler |
| `GASCore/GASInterpreter.gd` | Script (RefCounted, class_name GASInterpreter) | Public facade: enqueue, flush, variables, functions, caches, queue; init result via get_init_result; profiler access. | GASInterpreterConfig, GASFunctionRegistry, GASFunctionLibraryLoader, GASEnvironment, GASAstCache, GASFileCache, GASPipeline, GASScriptLoader, GASPriorityQueue, GASQueuedExpression, GASScript, GASSourceBlock, GASBlockSplitter, GASResult, GASError, LruEvictionPolicy, GASProfiler |
| `GASCore/GASInterpreterConfig.gd` | Script (RefCounted, class_name GASInterpreterConfig) | Tunables: function mode, library paths, symbol policy, cache limits, fallback, RNG source, optional profiler. | GASProfiler |
| `GASCore/GASProfiler.gd` | Script (RefCounted, class_name GASProfiler) | Cumulative null-gated profiler counters written by the interpreter. | GASProfilerSnapshot |
| `GASCore/GASProfilerSnapshot.gd` | Script (RefCounted, class_name GASProfilerSnapshot) | Immutable copy of profiler counters. | None |
| `GASCore/GASResult.gd` | Script (RefCounted, class_name GASResult) | Result wrapper: ok, value, errors, warnings, symbol table. | GASError |
| `GASCore/GASError.gd` | Script (RefCounted, class_name GASError) | Error value: code, message, line, column. | None |
| `GASCore/LruEvictionPolicy.gd` | Script (RefCounted, class_name LruEvictionPolicy) | LRU recency ordering for bounded caches. | None |
| `GASCore/GASASTCache.gd` | Script (RefCounted, class_name GASAstCache) | Bounded AST cache keyed by source string. | LruEvictionPolicy |
| `GASCore/GASFileCache.gd` | Script (RefCounted, class_name GASFileCache) | Bounded file cache keyed by path and mtime. | GASScript, LruEvictionPolicy |
| `GASCore/GASPriorityQueue.gd` | Script (RefCounted, class_name GASPriorityQueue) | Priority queue; lower number runs first. | GASQueuedExpression |
| `GASCore/GASQueuedExpression.gd` | Script (RefCounted, class_name GASQueuedExpression) | Queued expression: priority, AST, source. | Expr |
| `GASCore/GASScript.gd` | Script (RefCounted, class_name GASScript) | Loaded script: path, mtime, source blocks. | GASSourceBlock |
| `GASCore/GASSourceBlock.gd` | Script (RefCounted, class_name GASSourceBlock) | Source block descriptor: priority and source text. | None |

## AST nodes

| Path | Category | Primary Purpose | Dependencies |
|------|----------|-----------------|--------------|
| `GASCore/Expressions/Expr.gd` | Script (RefCounted, class_name Expr) | Base class for all expression nodes. | None |
| `GASCore/Expressions/LiteralExpr.gd` | Script (class_name LiteralExpr) | Holds a literal value. | Expr |
| `GASCore/Expressions/SymbolExpr.gd` | Script (class_name SymbolExpr) | Holds a variable name. | Expr |
| `GASCore/Expressions/DiceExpr.gd` | Script (class_name DiceExpr) | Holds dice count and sides. | Expr |
| `GASCore/Expressions/BinaryExpr.gd` | Script (class_name BinaryExpr) | Left operand, operator token, right operand. | Expr, Token |
| `GASCore/Expressions/UnaryExpr.gd` | Script (class_name UnaryExpr) | Operator token and operand. | Expr, Token |
| `GASCore/Expressions/GroupingExpr.gd` | Script (class_name GroupingExpr) | Wraps a parenthesized expression. | Expr |
| `GASCore/Expressions/AssignmentExpr.gd` | Script (class_name AssignmentExpr) | Name token and value expression. | Expr, Token |
| `GASCore/Expressions/FunctionCallExpr.gd` | Script (class_name FunctionCallExpr) | Function name and argument expressions. | Expr |
| `GASCore/Expressions/ArrayExpr.gd` | Script (class_name ArrayExpr) | Element expressions. | Expr |
| `GASCore/Expressions/BlockExpr.gd` | Script (class_name BlockExpr) | Statement expressions. | Expr |

## Battle system

| Path | Category | Primary Purpose | Dependencies |
|------|----------|-----------------|--------------|
| `battle/BattleConfiguration.gd` | Script (Resource, class_name BattleConfiguration) | Declarative recipe: calculator path, stat seed maps, function roles, base priorities. | None |
| `battle/BattleContext.gd` | Script (RefCounted, class_name BattleContext) | Runs one battle: seeds variables, registers functions, enqueues calculator and statements, flushes. | Entity, BattleConfiguration, BattleResult, GASInterpreter, GASResult |
| `battle/BattleResult.gd` | Script (RefCounted, class_name BattleResult) | Wraps GASResult with domain accessors. | GASResult, GASError |

## Domain data

| Path | Category | Primary Purpose | Dependencies |
|------|----------|-----------------|--------------|
| `entities/Entity.gd` | Script (RefCounted, class_name Entity) | Combat participant: name, stat dictionary, `[N]` statement strings. | None |

## Function libraries

| Path | Category | Primary Purpose | Dependencies |
|------|----------|-----------------|--------------|
| `function_libraries/array_funcs.gd` | Library (RefCounted) | Exposes `metadata` entries for `sum`, `average`, `count`. | None |
| `function_libraries/dice_funcs.gd` | Library (RefCounted) | Exposes `metadata` entries for `roll`, `d20`, `d6`, `advantage`, `disadvantage`; uses the injected RNG. | None |
| `function_libraries/math_funcs.gd` | Library (RefCounted) | Exposes `metadata` entries for `floor`, `ceil`, `abs`, `max`, `min`, `clamp`. | None |

## Scripts and demo

| Path | Category | Primary Purpose | Dependencies |
|------|----------|-----------------|--------------|
| `GASScripts/calculator.gas` | GAS script | Elemental damage: physical mitigation and elemental total at 30, final at 40. | Library `max`; seeded `$physical`, `$fire`, `$ice`, `$resistance` |
| `GASScripts/status_effects.gas` | GAS script | Status effect multipliers at 20. | Seeded `$physical`, `$fire` |
| `GASScripts/attack_roll.gas` | GAS script | Attack roll and mitigated physical damage at 10. | Library `max`; seeded `$strength`, `$resistance` |
| `GASScripts/defense.gas` | GAS script | Armor and dodge mitigation at 15. | Libraries `clamp`, `max`; seeded `$armor`, `$dodge`, `$physical` |
| `GASScripts/healing.gas` | GAS script | Healing capped by missing health at 25. | Libraries `max`, `min`; seeded `$hp`, `$max_hp`, `$healing` |
| `GASScripts/crit_damage.gas` | GAS script | Critical hit bonus at 10. | Seeded `$crit_multiplier`, `$physical`, `$fire`, `$ice` |
| `GASScripts/elemental_resistance.gas` | GAS script | Elemental resistance scaling at 20. | Seeded `$physical`, `$fire`, `$ice`, `$resistance` |
| `GASScripts/mana_cost.gas` | GAS script | Ability cost deducted from mana at 5. | Library `max`; seeded `$level`, `$mana` |
| `GASScripts/status_tick.gas` | GAS script | Poison and burn ticks at 30. | Library `max`; seeded `$hp`, `$poison`, `$burn` |
| `main.gd` | Script (Control) | Demo: builds entities and configuration, runs BattleContext, renders result. | Entity, BattleConfiguration, BattleContext, BattleResult, GASInterpreter, GASInterpreterConfig, GASError |
| `main.tscn` | Scene | Root Control with a Label. | main.gd |
| `project.godot` | Config | Project definition; main scene `main.tscn`. | main.tscn |

## Benchmarks

| Path | Category | Primary Purpose | Dependencies |
|------|----------|-----------------|--------------|
| `benchmarks/bench_soak.gd` | Script (SceneTree) | One-minute corpus soak benchmark: enqueues weighted corpus files and statements, flushes, and reports statements per frame plus cache hit rates. | GASInterpreter, GASInterpreterConfig, GASProfiler, GASResult, CorpusLoader, GasCorpus, CorpusFile, CorpusStatement, GASStatementCounter, PhaseTimingReporter, `benchmarks/corpus.json` |
| `benchmarks/PhaseTimingReporter.gd` | Script (RefCounted, class_name PhaseTimingReporter) | Renders and exports GASProfiler phase timings as text and JSON. | GASProfiler |
| `benchmarks/GasCorpus.gd` | Script (RefCounted, class_name GasCorpus) | Corpus data: files, statements, cache-miss ratio, target statement count, scenario weights. | CorpusFile, CorpusStatement |
| `benchmarks/CorpusFile.gd` | Script (RefCounted, class_name CorpusFile) | Weighted corpus file entry. | None |
| `benchmarks/CorpusStatement.gd` | Script (RefCounted, class_name CorpusStatement) | Weighted corpus statement entry. | None |
| `benchmarks/CorpusLoader.gd` | Script (RefCounted, class_name CorpusLoader) | Loads and validates corpus JSON, normalizes weights. | GasCorpus, CorpusFile, CorpusStatement |
| `benchmarks/GASStatementCounter.gd` | Script (RefCounted, class_name GASStatementCounter) | Counts GAS statements in source text and files. | Lexer, PrattParser, Expr, BlockExpr, GASBlockSplitter |
| `benchmarks/corpus.json` | Data | Soak benchmark corpus manifest: weighted files and statements. | `GASScripts/*.gas`, `function_libraries/*` |

## Data flow

Source text flows through `Lexer` to `Token`s, then `PrattParser` to an `Expr` AST, then `Evaluator` to a value.

`GASInterpreter` is the facade. `run` and `enqueue` parse through `GASPipeline`, which caches ASTs in `GASAstCache`. `GASScriptLoader` splits `.gas` files with `GASBlockSplitter` into `GASSourceBlock` items held by the file cache; `enqueue_file` resolves each block through `GASPipeline` into a `GASQueuedExpression` for `GASPriorityQueue`. `flush` evaluates each queued expression against one shared `GASEnvironment`.

Function calls resolve through `GASFunctionRegistry`, then loaded libraries, then the external fallback handler.

The battle layer wraps this: `main.gd` builds `Entity` instances and a `BattleConfiguration`, then `BattleContext.run` seeds variables, registers scoped functions, enqueues the calculator and entity statements, flushes, and returns a `BattleResult`.

## Excluded

`.godot/` is engine-generated editor and shader cache. `.vscode/` holds editor settings. `*.uid` files are Godot resource IDs. `icon.svg` and its import file are project assets.
