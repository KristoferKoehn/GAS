class_name BattleConfiguration
extends Resource

enum Role { ATTACKER, DEFENDER }

@export var calculator_path: String = ""
@export var attacker_stats: Dictionary[String, String] = {}
@export var defender_stats: Dictionary[String, String] = {}
@export var functions: Dictionary[String, int] = {}
@export var calculator_base_priority: int = 0
@export var statement_base_priority: int = 0
