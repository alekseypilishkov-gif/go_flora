@tool
class_name GFRecordDelta
extends RefCounted

var added: Array[GFInstanceRecord] = []
var removed: Array[GFInstanceRecord] = []
var removed_indices: PackedInt32Array = []
var before_serial: int = 0
var after_serial: int = 0

func is_empty() -> bool:
	return added.is_empty() and removed.is_empty()

func apply_to(data: GFVegetationLayerData, reverse: bool) -> void:
	var exclude: Dictionary = {}
	for record in (added if reverse else removed):
		exclude[record.record_id] = true
	var records: Array[GFInstanceRecord] = []
	for record in data.records:
		if not exclude.has(record.record_id):
			records.append(record)
	if reverse:
		# Merge ascending original indices in linear time, including dense erases.
		var restored: Array[GFInstanceRecord] = []
		var cursor := 0
		for i in removed.size():
			while restored.size() < removed_indices[i] and cursor < records.size():
				restored.append(records[cursor])
				cursor += 1
			restored.append(removed[i])
		while cursor < records.size():
			restored.append(records[cursor])
			cursor += 1
		records = restored
	else:
		for record in added:
			records.append(record)
	data.records = records
	data.next_stroke_serial = before_serial if reverse else after_serial
	data.emit_changed()
