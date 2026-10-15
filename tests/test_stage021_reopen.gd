extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Node = load("res://.scratch/ux_saved.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var layer := scene.get_node("VegetationLayer") as VegetationLayer3D
	var values: Array = []
	for r in layer.layer_data.records:
		values.append([r.record_id, r.source_id, r.set_id, r.seed, str(r.local_transform), str(r.local_normal), r.source_revision])
	var expected := FileAccess.get_file_as_string("res://.scratch/ux_expected.json")
	var ok := JSON.stringify(values) == expected and not layer.layer_data.sets[0].entries[1].enabled and layer.batch_count() > 0
	print("PASS STAGE021_REOPEN" if ok else "FAIL STAGE021_REOPEN")
	scene.free()
	quit(int(not ok))
