class_name PhaseTimingReporter
extends RefCounted

## PhaseTimingReporter -- renders and exports GASProfiler phase timings.
##
## Reuses the phase counters GASProfiler already collects (parse, evaluate,
## enqueue, flush) and lays them out as a padded text table plus JSON export.

static var HEADERS: PackedStringArray = PackedStringArray([
	"step",
	"calls",
	"total ms",
	"avg us/call",
	"% of wall",
])

static func print_report(profiler: GASProfiler, wall_usec: int, turns: int) -> void:
	print(render_text(profiler, wall_usec, turns))

static func render_text(profiler: GASProfiler, wall_usec: int, turns: int) -> String:
	var rows: Array[PackedStringArray] = _build_rows(profiler, wall_usec, turns)
	var out: String = _render_table(HEADERS, rows)
	out += "\nnote: parse is included in enqueue; evaluate is included in flush."
	out += " enqueue + flush + other = wall clock."
	return out

static func export_text(path: String, profiler: GASProfiler, wall_usec: int, turns: int) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("PhaseTimingReporter: could not write %s" % path)
		return
	file.store_string(render_text(profiler, wall_usec, turns))
	file.close()

static func export_json(path: String, profiler: GASProfiler, wall_usec: int, turns: int) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("PhaseTimingReporter: could not write %s" % path)
		return
	file.store_string(JSON.stringify(_to_dict(profiler, wall_usec, turns), "\t"))
	file.close()

static func _build_rows(profiler: GASProfiler, wall_usec: int, turns: int) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	rows.append(_row("lex + parse", profiler.parse_count, profiler.parse_usec, wall_usec))
	rows.append(_row("evaluate", profiler.evaluate_count, profiler.evaluate_usec, wall_usec))
	rows.append(_row("enqueue (parse + queue insert)", profiler.enqueue_count, profiler.enqueue_usec, wall_usec))
	rows.append(_row("flush (dequeue + evaluate)", profiler.flush_count, profiler.flush_usec, wall_usec))
	rows.append(_row("wall clock (measured)", turns, wall_usec, wall_usec))
	var other_usec: int = maxi(0, wall_usec - profiler.enqueue_usec - profiler.flush_usec)
	rows.append(_row("other (loop + file-load parse)", -1, other_usec, wall_usec))
	return rows

static func _row(label: String, calls: int, total_usec: int, wall_usec: int) -> PackedStringArray:
	var calls_text: String = "-" if calls < 0 else str(calls)
	var total_ms: String = "%.2f" % (float(total_usec) / 1000.0)
	var avg_text: String = "-"
	if calls > 0:
		avg_text = "%.1f" % (float(total_usec) / float(calls))
	var pct_text: String = "-"
	if wall_usec > 0:
		pct_text = "%.1f%%" % (float(total_usec) / float(wall_usec) * 100.0)
	return PackedStringArray([label, calls_text, total_ms, avg_text, pct_text])

static func _to_dict(profiler: GASProfiler, wall_usec: int, turns: int) -> Dictionary:
	var other_usec: int = maxi(0, wall_usec - profiler.enqueue_usec - profiler.flush_usec)
	return {
		"wall_usec": wall_usec,
		"wall_sec": float(wall_usec) / 1_000_000.0,
		"turns": turns,
		"steps": {
			"parse": _phase_dict("lex + parse", profiler.parse_count, profiler.parse_usec, wall_usec),
			"evaluate": _phase_dict("evaluate", profiler.evaluate_count, profiler.evaluate_usec, wall_usec),
			"enqueue": _phase_dict("enqueue (parse + queue insert)", profiler.enqueue_count, profiler.enqueue_usec, wall_usec),
			"flush": _phase_dict("flush (dequeue + evaluate)", profiler.flush_count, profiler.flush_usec, wall_usec),
		},
		"other": _phase_dict("other (loop + file-load parse)", -1, other_usec, wall_usec),
	}

static func _phase_dict(label: String, calls: int, total_usec: int, wall_usec: int) -> Dictionary:
	var result: Dictionary = {
		"label": label,
		"calls": calls,
		"total_usec": total_usec,
		"total_ms": float(total_usec) / 1000.0,
	}
	if calls > 0:
		result["avg_usec"] = float(total_usec) / float(calls)
	else:
		result["avg_usec"] = null
	if wall_usec > 0:
		result["pct_of_wall"] = float(total_usec) / float(wall_usec) * 100.0
	else:
		result["pct_of_wall"] = null
	return result

static func _render_table(headers: PackedStringArray, rows: Array[PackedStringArray]) -> String:
	var widths: PackedInt32Array = PackedInt32Array()
	widths.resize(headers.size())
	for i: int in range(headers.size()):
		widths[i] = headers[i].length()
	for row: PackedStringArray in rows:
		for i: int in range(row.size()):
			widths[i] = maxi(widths[i], row[i].length())
	var lines: PackedStringArray = PackedStringArray()
	lines.append(_format_row(headers, widths))
	for row: PackedStringArray in rows:
		lines.append(_format_row(row, widths))
	return "\n".join(lines)

static func _format_row(values: PackedStringArray, widths: PackedInt32Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for i: int in range(values.size()):
		parts.append(_pad_right(values[i], widths[i]))
	return "  ".join(parts)

static func _pad_right(value: String, width: int) -> String:
	if value.length() >= width:
		return value
	var padding: String = ""
	for i: int in range(width - value.length()):
		padding += " "
	return value + padding
