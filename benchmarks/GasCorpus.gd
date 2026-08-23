class_name GasCorpus
extends RefCounted

var cache_miss_ratio: float = 0.0
var target_statement_count: int = 0
var files: Array[CorpusFile] = []
var statements: Array[CorpusStatement] = []
var scenario_weights: Dictionary[String, float] = {}
