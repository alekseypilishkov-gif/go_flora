extends SceneTree

var failures := 0
var results: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	print(("PASS " if ok else "FAIL ") + "STAGE021 " + id)
	results.append({"id": id, "status": "PASS" if ok else "FAIL"})
	failures += int(not ok)

func plane(point: Vector3, normal: Vector3) -> Dictionary:
	return {"position": point, "normal": normal}

func snapshot(records: Array[GFInstanceRecord]) -> String:
	var values: Array = []
	for r in records:
		values.append([r.record_id, r.source_id, r.set_id, r.seed, str(r.local_transform), str(r.local_normal), r.source_revision])
	return JSON.stringify(values)

func stroke(data: GFVegetationLayerData, vegetation_set: GFVegetationSet, mode: GFStroke.Mode, selected: String = "") -> GFStroke:
	var result := GFStroke.new()
	var brush := GFBrush.new()
	brush.radius_m = 5
	if result.begin(data, Transform3D.IDENTITY, vegetation_set, brush, 8, mode, selected):
		for point in [Vector3.ZERO, Vector3(6, 0, 0), Vector3(12, 0, 0)]:
			result.feed({"position": point, "normal": Vector3.UP}, plane)
		result.finish_delta()
	return result

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var scene: Node = load("res://demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var layer := scene.get_node("VegetationLayer") as VegetationLayer3D
	var vegetation_set := layer.layer_data.sets[0]
	for name in ["grass", "flower"]:
		var source := GFVegetationSource.new()
		source.source_id = name
		source.display_name = name
		source.kind = GFVegetationSource.Kind.ALPHA_CARD
		source.alpha_card = GFAlphaCard.new()
		source.alpha_card.texture = load("res://fixtures/grass.png" if name == "grass" else "res://fixtures/flower.png")
		var entry := GFPaletteEntry.new()
		entry.source = source
		vegetation_set.entries.append(entry)
	check(vegetation_set.entries.size() == 4 and vegetation_set.entries.all(func(e: GFPaletteEntry) -> bool: return e.enabled), "legacy_default_enabled_and_four_sources")
	var data := layer.layer_data
	var weights := vegetation_set.entries.map(func(e: GFPaletteEntry) -> float: return e.weight)
	var references := vegetation_set.entries.duplicate()
	var original := stroke(data, vegetation_set, GFStroke.Mode.PAINT)
	var repeat := stroke(data, vegetation_set, GFStroke.Mode.PAINT)
	check(original.diagnostic.is_empty() and original.delta.added.size() > 20 and snapshot(original.delta.added) == snapshot(repeat.delta.added), "mix_deterministic_before_change")
	# Reference sampling formula from accepted Stage 01, independent of new eligibility filter.
	var legacy_equal := true
	for seed in 1000:
		var unit := GFPlacement.random_unit(seed, "reference", seed, "source")
		var entries := vegetation_set.ordered_entries()
		var total := 0.0
		for e in entries:
			total += e.weight
		var target := unit * total
		var expected: GFVegetationSource = entries[-1].source
		for e in entries:
			target -= e.weight
			if target < 0:
				expected = e.source
				break
		legacy_equal = legacy_equal and GFPlacement.choose_source(vegetation_set, unit) == expected
	check(legacy_equal, "one_thousand_legacy_weighted_choices_unchanged")
	original.delta.apply_to(data, false)
	var saved := snapshot(data.records)
	for i in 2:
		vegetation_set.entries[i].enabled = false
	var filtered := stroke(data, vegetation_set, GFStroke.Mode.PAINT)
	check(filtered.diagnostic.is_empty() and filtered.delta.added.size() > 20 and filtered.delta.added.all(func(r: GFInstanceRecord) -> bool: return r.source_id in ["grass", "flower"]), "disabled_cone_cube_mix_only_grass_flower")
	check(weights == vegetation_set.entries.map(func(e: GFPaletteEntry) -> float: return e.weight) and saved == snapshot(data.records), "disable_preserves_weights_IDs_transforms_records")
	layer.rebuild_now()
	check(layer.batch_count() > 0 and saved == snapshot(data.records), "disabled_sources_existing_placements_still_rendered")
	for i in 2:
		vegetation_set.entries[i].enabled = true
	# Replay the same stroke serial as before applying the baseline delta.
	var replay := GFVegetationLayerData.new()
	replay.layer_id = data.layer_id
	replay.sets = data.sets
	check(snapshot(stroke(replay, vegetation_set, GFStroke.Mode.PAINT).delta.added) == snapshot(original.delta.added), "reenable_restores_exact_seeded_mix")
	for id in ["grass", "flower"]:
		for mode in [GFStroke.Mode.PAINT, GFStroke.Mode.SINGLE]:
			var selected := stroke(data, vegetation_set, mode, id)
			check(selected.diagnostic.is_empty() and not selected.delta.added.is_empty() and selected.delta.added.all(func(r: GFInstanceRecord) -> bool: return r.source_id == id)
				and (mode != GFStroke.Mode.SINGLE or selected.delta.added.size() == 1), "selected_%s_mode_%d" % [id, mode])
	check(references == vegetation_set.entries and weights == vegetation_set.entries.map(func(e: GFPaletteEntry) -> float: return e.weight) and saved == snapshot(data.records), "selection_never_rewrites_palette_weights_or_old_records")
	for e in vegetation_set.entries:
		e.weight = 0
	check(not vegetation_set.painting_diagnostic().is_empty() and GFPlacement.choose_source(vegetation_set, 0.5) == null, "all_zero_mix_actionable_diagnostic_no_choice")
	check(stroke(data, vegetation_set, GFStroke.Mode.PAINT).delta.added.is_empty(), "noeligible_paint_no_records")
	check(stroke(data, vegetation_set, GFStroke.Mode.SINGLE, "grass").delta.added.size() == 1, "selected_enabled_zero_mix_weight_is_explicitly_allowed")
	vegetation_set.entries[2].enabled = false
	check(not vegetation_set.painting_diagnostic("grass").is_empty() and stroke(data, vegetation_set, GFStroke.Mode.SINGLE, "grass").delta.added.is_empty(), "disabled_selected_rejected")
	check(not vegetation_set.painting_diagnostic("missing-id").is_empty(), "missing_selection_rejected")
	var grass := vegetation_set.entries[2]
	grass.enabled = true
	var original_texture := grass.source.alpha_card.texture
	grass.source.alpha_card.texture = null
	check(not vegetation_set.painting_diagnostic("grass").is_empty() and stroke(data, vegetation_set, GFStroke.Mode.PAINT, "grass").delta.added.is_empty(), "unavailable_selected_texture_rejected_without_loss")
	grass.enabled = false
	vegetation_set.entries[3].weight = 1
	check(vegetation_set.painting_diagnostic().is_empty(), "disabled_unavailable_source_does_not_block_valid_mix")
	grass.source.alpha_card.texture = original_texture
	vegetation_set.entries[3].weight = 0
	check(saved == snapshot(data.records), "unavailable_selected_retains_every_record")
	var erase := stroke(data, vegetation_set, GFStroke.Mode.ERASE, "missing-id")
	check(erase.diagnostic.is_empty() and not erase.delta.removed.is_empty(), "erase_independent_of_noeligible_and_invalid_selection")
	var before_erase := snapshot(data.records)
	erase.delta.apply_to(data, false)
	erase.delta.apply_to(data, true)
	check(snapshot(data.records) == before_erase, "erase_delta_undo_exact_old_order_and_IDs")
	vegetation_set.entries[0].weight = -1
	check(not vegetation_set.painting_diagnostic().is_empty(), "negative_weight_invalid")
	vegetation_set.entries[0].weight = NAN
	check(not vegetation_set.painting_diagnostic().is_empty(), "nonfinite_weight_invalid")
	for i in vegetation_set.entries.size():
		vegetation_set.entries[i].weight = weights[i]
	vegetation_set.entries[0].source.display_name = "Понятное имя растения"
	vegetation_set.entries[1].enabled = false
	check(ResourceSaver.save(vegetation_set, "res://.scratch/ux_set.tres") == OK, "save_enabled_state_additive_schema")
	var reopened := ResourceLoader.load("res://.scratch/ux_set.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as GFVegetationSet
	check(reopened != null and reopened.entries.size() == 4 and not reopened.entries[1].enabled and reopened.entries[0].source.display_name == "Понятное имя растения"
		and reopened.entries[0].source.source_id == vegetation_set.entries[0].source.source_id, "reload_enabled_names_weights_stable_IDs")
	check(snapshot(data.records) == saved, "all_palette_edits_preserve_every_legacy_record")
	var packed := PackedScene.new()
	check(packed.pack(scene) == OK and ResourceSaver.save(packed, "res://.scratch/ux_saved.tscn") == OK, "scene_save_with_disabled_sources")
	FileAccess.open("res://.scratch/ux_expected.json", FileAccess.WRITE).store_string(saved)
	scene.free()
	FileAccess.open("res://.scratch/ux_core_results.json", FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	print("PASS STAGE021_COMPLETE" if failures == 0 else "FAIL STAGE021_COMPLETE")
	quit(int(failures > 0))
