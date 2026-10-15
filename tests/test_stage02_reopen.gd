extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://.scratch/stage02_expected.json"))
	var layer := load("res://.scratch/stage02_roundtrip.tscn").instantiate() as VegetationLayer3D
	root.add_child(layer)
	await process_frame
	layer.rebuild_now()
	var ok: bool = layer.layer_data.records.size() == expected.records.size() and layer.batch_count() == int(expected.batches) and layer._scene_cache.size() == 1
	for i in layer.layer_data.records.size():
		var record := layer.layer_data.records[i]
		var row: Dictionary = expected.records[i]
		ok = ok and record.record_id == row.id and record.source_id == row.source and record.set_id == row.set and record.seed == row.seed and record.source_revision == row.revision
		var values: Array = []
		for vector in [record.local_transform.origin, record.local_transform.basis.x, record.local_transform.basis.y, record.local_transform.basis.z]:
			values.append_array([vector.x, vector.y, vector.z])
		for j in values.size():
			ok = ok and absf(values[j] - row.values[j]) < 0.00001
	ok = ok and is_equal_approx(layer.batches_by_set["set-3"][0].visibility_range_end, 0.1)
	if not ok:
		print("REOPEN_DETAIL ", layer.batch_count(), " expected=", expected.batches, " scenes=", layer._scene_cache.size(), " diagnostics=", layer.render_diagnostics)
	print(("PASS " if ok else "FAIL ") + "STAGE02_REOPEN records/parts/distance/runtime fallback")
	layer.free()
	await process_frame
	quit(0 if ok else 1)
