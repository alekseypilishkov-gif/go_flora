extends SceneTree

var failed := false
var checks: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	print(("PASS " if ok else "FAIL ") + "STAGE023_CATALOG " + id)
	checks.append({"id": id, "status": "PASS" if ok else "FAIL"})
	failed = failed or not ok

func run() -> void:
	var sources: Array[GFVegetationSource] = []
	for file in ["original_plant.glb", "static_plant.tscn", "authored_plant.tscn", "grass.png", "grass.webp"]:
		var source := GFVegetationSource.new()
		source.source_id = file
		if file.ends_with("png") or file.ends_with("webp"):
			source.kind = GFVegetationSource.Kind.ALPHA_CARD
			source.alpha_card = GFAlphaCard.new()
			source.alpha_card.texture = load("res://fixtures/" + file)
		else:
			source.kind = GFVegetationSource.Kind.IMPORTED_SCENE
			source.asset = load("res://fixtures/" + file)
			if file == "authored_plant.tscn":
				source.allow_scene_fallback = true
				source.reviewed_scene_revision = source.resolve().revision
		sources.append(source)
	for source in sources:
		var layer := VegetationLayer3D.new()
		var data := layer.layer_data
		var vegetation_set := GFVegetationSet.new()
		vegetation_set.set_id = "catalog"
		var entry := GFPaletteEntry.new()
		entry.source = source
		entry.enabled = false
		vegetation_set.entries.append(entry)
		data.sets.append(vegetation_set)
		var record := GFInstanceRecord.new()
		record.record_id = "archived-" + source.source_id
		record.layer_id = data.layer_id
		record.set_id = vegetation_set.set_id
		record.source_id = source.source_id
		data.records.append(record)
		root.add_child(layer)
		await process_frame
		layer.rebuild_now()
		var batches := layer.batch_count()
		var scenes := layer._scene_cache.size()
		var diagnostics := layer.render_diagnostics.duplicate()
		vegetation_set.render_only_sources.assign([source])
		vegetation_set.entries = []
		await process_frame
		check(layer.batch_count() == batches and layer._scene_cache.size() == scenes and layer.render_diagnostics == diagnostics and (batches > 0 or scenes > 0), "archive_preserves_source_record_resolution_" + source.source_id)
		check(vegetation_set.source_by_id(source.source_id) == null and vegetation_set.placement_entries().is_empty() and not vegetation_set.painting_diagnostic().is_empty(), "archive_never_paintable_" + source.source_id)
		check(layer._bindings.any(func(binding: Dictionary) -> bool: return binding.resource == source), "archive_source_observed_" + source.source_id)
		var packed := PackedScene.new()
		packed.pack(layer)
		var file := "res://.scratch/catalog_" + source.source_id + ".tscn"
		check(ResourceSaver.save(packed, file) == OK, "serialized_" + source.source_id)
		var reopened := (ResourceLoader.load(file, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate() as VegetationLayer3D
		root.add_child(reopened)
		await process_frame
		check(reopened.layer_data.sets[0].render_only_sources[0].source_id == source.source_id and reopened.layer_data.records[0].record_id == record.record_id and reopened.batch_count() == batches and reopened._scene_cache.size() == scenes, "serialized_archive_load_" + source.source_id)
		if source.source_id == "authored_plant.tscn":
			source.reviewed_scene_revision = "stale"
			await process_frame
			check(layer._scene_cache.is_empty() and data.records.size() == 1 and not layer.render_diagnostics.is_empty(), "archived_fallback_still_refuses_stale_review")
		reopened.free()
		layer.free()
	var file := FileAccess.open("res://.scratch/stage023_catalog.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "scope": "native runtime source catalog; no GUI"}, "\t"))
	file.close()
	print("FAIL STAGE023_CATALOG_COMPLETE" if failed else "PASS STAGE023_CATALOG_COMPLETE")
	quit(1 if failed else 0)
