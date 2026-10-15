extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://.scratch/expected.json"))
	var demo := load("res://.scratch/roundtrip.tscn").instantiate() as Node3D
	root.add_child(demo)
	await process_frame
	var layer := demo.get_node("VegetationLayer") as VegetationLayer3D
	layer.rebuild_now()
	var records := layer.layer_data.records
	var ok: bool = records.size() == expected.records.size() and layer.batch_count() == expected.batch_count and layer.layer_data.next_stroke_serial == expected.serial
	for i in records.size():
		var record := records[i]
		var row: Dictionary = expected.records[i]
		ok = ok and record.record_id == row.id and record.source_id == row.source and record.set_id == row.set and record.layer_id == row.layer
		ok = ok and record.schema_version == row.schema and record.source_revision == row.variant and str(record.target_path) == row.target
		ok = ok and record.seed == row.seed and record.candidate_index == row.candidate and record.flags == row.flags and record.stroke_id == row.stroke and record.algorithm_version == row.algorithm
		ok = ok and record.cell_key == Vector2i(row.cell[0], row.cell[1])
		var values: Array = []
		for vector in [record.local_transform.origin, record.local_transform.basis.x, record.local_transform.basis.y, record.local_transform.basis.z, record.local_normal]:
			values.append_array([vector.x, vector.y, vector.z])
		for j in values.size():
			ok = ok and absf(values[j] - row.values[j]) < 0.00001
	var owned_cache_count := 0
	for child in layer.get_children(true):
		if child.has_meta("go_flora_owned"):
			owned_cache_count += 1
	ok = ok and owned_cache_count == 1
	print(("PASS " if ok else "FAIL ") + "fresh_process_scene_reopen exact IDs/count/seed/set/cells; transform tolerance 1e-5; one rebuilt cache")
	demo.free()
	await process_frame
	quit(0 if ok else 1)
