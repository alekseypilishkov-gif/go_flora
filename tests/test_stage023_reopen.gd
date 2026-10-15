extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene := load("res://.scratch/palette_saved.tscn").instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await process_frame
	var layer := scene.get_node("VegetationLayer") as VegetationLayer3D
	var data := layer.layer_data
	var vegetation_set := data.sets[0]
	var record := data.records[0]
	var ok := data.schema_version == 1 and data.records.size() == 1 and vegetation_set.source_by_id(record.source_id) == null and vegetation_set.render_only_sources.size() == 1 and layer.batch_count() > 0 and layer.render_diagnostics.is_empty()
	print(("PASS " if ok else "FAIL ") + "STAGE023_FRESH_SOURCE_RECORD_RESOLUTION " + JSON.stringify({"set": record.set_id, "source": record.source_id, "record": record.record_id, "batches": layer.batch_count(), "diagnostics": layer.render_diagnostics}))
	if DisplayServer.get_name() != "headless":
		var color := await preload("res://tests/stage023_visual.gd").capture(data, self, "res://.scratch/palette_reopened.png")
		ok = ok and color.g > 0.8 and color.r < 0.15
		print(("PASS " if ok else "FAIL ") + "STAGE023_FRESH_GPU_RETAINED " + str(color))
	else:
		print("NOT_RUN STAGE023_FRESH_GPU headless")
	scene.free()
	print("PASS STAGE023_REOPEN_COMPLETE" if ok else "FAIL STAGE023_REOPEN_COMPLETE")
	quit(0 if ok else 1)
