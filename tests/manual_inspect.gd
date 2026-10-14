@tool
extends EditorScript

# Optional evidence capture after the OWNER's real mouse/Inspector actions.
# Reading records/batches here is not an interactive GUI acceptance test.
func _run() -> void:
	var scene := EditorInterface.get_edited_scene_root()
	if scene == null:
		push_error("Open a scene with VegetationLayer3D first.")
		return
	var output: Array[Dictionary] = []
	_collect(scene, output)
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var path := "res://.scratch/manual_snapshot_%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write manual evidence snapshot.")
		return
	file.store_string(JSON.stringify({"scope": "Owner-triggered inspection; GUI action outcome must be reviewed separately", "layers": output}, "\t"))
	file.close()
	print("GO_FLORA_MANUAL_SNAPSHOT ", path)

func _collect(node: Node, output: Array[Dictionary]) -> void:
	if node is VegetationLayer3D and node.layer_data != null:
		var records: Array[Dictionary] = []
		for record in node.layer_data.records:
			records.append({"id": record.record_id, "set": record.set_id, "source": record.source_id,
				"transform": str(record.local_transform), "normal": str(record.local_normal), "seed": record.seed})
		var batches: Array[Dictionary] = []
		for set_id in node.batches_by_set:
			for batch in node.batches_by_set[set_id]:
				batches.append({"node_id": batch.get_instance_id(), "set": set_id,
					"cell": str(batch.get_meta("cell_key")), "records": batch.get_meta("record_ids"),
					"distance": batch.visibility_range_end, "fade": batch.visibility_range_fade_mode})
		output.append({"path": str(node.get_path()), "record_count": records.size(), "records": records, "batches": batches})
	for child in node.get_children():
		_collect(child, output)
