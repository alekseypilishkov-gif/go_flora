@tool
class_name GFVegetationLayerData
extends Resource

const CURRENT_SCHEMA := 1
@export var schema_version: int = CURRENT_SCHEMA
@export var layer_id: String = "":
	set(value):
		layer_id = value
		emit_changed()
@export var sets: Array[GFVegetationSet] = []:
	set(value):
		sets = value
		emit_changed()
@export_storage var records: Array[GFInstanceRecord] = []
@export_storage var next_stroke_serial: int = 0

func _init() -> void:
	resource_local_to_scene = true
	layer_id = "layer-" + str(Time.get_ticks_usec()) + "-" + str(get_instance_id())

func diagnostic() -> String:
	if schema_version != CURRENT_SCHEMA:
		return "Layer schema %d is unsupported (supported: %d). Data preserved; editing disabled." % [schema_version, CURRENT_SCHEMA]
	if layer_id.is_empty():
		return "Layer needs a stable layer_id."
	var set_ids: Dictionary = {}
	for vegetation_set in sets:
		if vegetation_set == null or vegetation_set.set_id.is_empty() or set_ids.has(vegetation_set.set_id):
			return "Layer sets must have unique, non-empty IDs."
		set_ids[vegetation_set.set_id] = true
	var record_ids: Dictionary = {}
	for record in records:
		if record == null or record.schema_version != CURRENT_SCHEMA:
			return "Unsupported record schema or missing record. Data preserved."
		if record.record_id.is_empty() or record_ids.has(record.record_id):
			return "Layer contains missing/duplicate record IDs. Data preserved."
		if record.layer_id != layer_id or not record.local_transform.is_finite() or not record.local_normal.is_finite():
			return "Invalid record coordinate/layer data. Editing disabled; data preserved."
		record_ids[record.record_id] = true
	return ""
