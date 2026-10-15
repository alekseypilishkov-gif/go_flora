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
		for i in removed.size():
			records.insert(mini(removed_indices[i], records.size()), removed[i])
	else:
		for record in added:
			records.append(record)
	data.records = records
	data.next_stroke_serial = before_serial if reverse else after_serial
	data.emit_changed()
