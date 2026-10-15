extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Node = load("res://.scratch/modal_saved.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var layer := scene.get_node("VegetationLayer") as VegetationLayer3D
	var values: Array = []
	for r in layer.layer_data.records:
		values.append([r.record_id, r.source_id, r.set_id, r.seed, str(r.local_transform), str(r.local_normal), r.source_revision])
	var ok := JSON.stringify(values) == FileAccess.get_file_as_string("res://.scratch/modal_records_expected.json") and layer.batch_count() > 0 and layer.layer_data.schema_version == 1
	var expected: Array = JSON.parse_string(FileAccess.get_file_as_string("res://.scratch/modal_sources_expected.json"))
	var ids: Dictionary = {}
	for row in expected:
		var source := load(row.file) as GFVegetationSource
		ok = ok and source.source_id == row.id and not ids.has(row.id)
		ids[row.id] = true
		if source.kind == GFVegetationSource.Kind.ALPHA_CARD:
			ok = ok and source.alpha_card.texture.resource_path == row.asset and is_equal_approx(source.alpha_card.width_m, 0.86) and is_equal_approx(source.alpha_card.height_m, 1.36)
		else:
			ok = ok and source.asset.resource_path == row.asset and source.resolve().parts.size() == 2
	ok = ok and expected.size() == 12 and layer.layer_data.sets[0].entries.size() == 14
	print("PASS STAGE022_REOPEN" if ok else "FAIL STAGE022_REOPEN")
	scene.free()
	quit(int(not ok))
