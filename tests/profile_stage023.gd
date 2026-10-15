extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var rows: Array = []
	for count in [1, 1000, 2001, 5000, 12000]:
		var data := GFVegetationLayerData.new()
		data.layer_id = "profile"
		var vegetation_set := GFVegetationSet.new()
		vegetation_set.set_id = "active"
		data.sets.append(vegetation_set)
		for i in count:
			var record := GFInstanceRecord.new()
			record.record_id = "id-%d" % i
			record.layer_id = data.layer_id
			record.set_id = "active"
			record.source_id = "source"
			record.local_transform.origin = Vector3(i * 0.01, 0, 0)
			data.records.append(record)
		var brush := GFBrush.new()
		brush.radius_m = 1
		var stroke := GFStroke.new()
		var start := Time.get_ticks_usec()
		stroke.begin(data, Transform3D.IDENTITY, vegetation_set, brush, 8, GFStroke.Mode.ERASE)
		for i in 61:
			stroke.feed({"position": Vector3(i * 2, 0, 0), "normal": Vector3.UP}, Callable())
		var delta := stroke.finish_delta()
		var row := {"records": count, "removed": delta.removed.size(), "CPU_usec": Time.get_ticks_usec() - start, "candidates": stroke.candidates_used, "budget_exhausted": stroke.budget_exhausted}
		rows.append(row)
		print("PASS ERASE_PROFILE " + JSON.stringify(row))
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var file := FileAccess.open("res://.scratch/erase_profile.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows": rows, "scope": "CPU total for 61 inputs; not FPS; PASS means probe executed, compare removed counts"}, "\t"))
	file.close()
	print("PASS ERASE_PROFILE_COMPLETE")
	quit()
