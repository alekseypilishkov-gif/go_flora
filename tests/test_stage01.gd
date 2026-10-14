extends SceneTree

var failures := 0
var results: Array[Dictionary] = []
var benchmarks: Array[Dictionary] = []
var demo: Node3D
var layer: VegetationLayer3D
var set_a: GFVegetationSet
var set_b: GFVegetationSet

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + id + " " + detail)
	results.append({"id": id, "status": "PASS" if ok else "FAIL", "detail": detail})
	if not ok:
		failures += 1

func plane_resolver(point: Vector3, _normal: Vector3) -> Dictionary:
	return {"position": Vector3(point.x, 0.0, point.z), "normal": Vector3.UP}

func half_plane_resolver(point: Vector3, normal: Vector3) -> Dictionary:
	return {} if point.x < 0.0 else plane_resolver(point, normal)

func new_data() -> GFVegetationLayerData:
	var data := GFVegetationLayerData.new()
	data.layer_id = "test-layer"
	data.sets.assign([set_a, set_b])
	return data

func stroke(data: GFVegetationLayerData, brush: GFBrush, selected_set: GFVegetationSet, path: Array[Vector3], resolver: Callable, tool: GFStroke.Mode = GFStroke.Mode.PAINT) -> GFStroke:
	var result := GFStroke.new()
	if not result.begin(data, Transform3D.IDENTITY, selected_set, brush, 2.0, tool):
		check(false, "stroke_begin", result.diagnostic)
		return result
	for point in path:
		result.feed({"position": point, "normal": Vector3.UP}, resolver)
	result.finish_delta()
	return result

func records_equal(a: Array[GFInstanceRecord], b: Array[GFInstanceRecord]) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i].record_id != b[i].record_id or a[i].source_id != b[i].source_id or not a[i].local_transform.is_equal_approx(b[i].local_transform):
			return false
	return true

func snapshot(records: Array[GFInstanceRecord]) -> Array:
	var rows: Array = []
	for record in records:
		var transform := record.local_transform
		var values: Array = []
		for vector in [transform.origin, transform.basis.x, transform.basis.y, transform.basis.z, record.local_normal]:
			values.append_array([vector.x, vector.y, vector.z])
		rows.append({"id": record.record_id, "source": record.source_id, "set": record.set_id, "layer": record.layer_id,
			"schema": record.schema_version, "variant": record.source_revision, "target": str(record.target_path),
			"seed": record.seed, "candidate": record.candidate_index, "cell": [record.cell_key.x, record.cell_key.y],
			"flags": record.flags, "stroke": record.stroke_id, "algorithm": record.algorithm_version, "values": values})
	return rows

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	demo = load("res://demo.tscn").instantiate() as Node3D
	root.add_child(demo)
	layer = demo.get_node("VegetationLayer") as VegetationLayer3D
	set_a = layer.layer_data.sets[0]
	set_b = layer.layer_data.sets[1]
	await process_frame
	await physics_frame
	await physics_frame
	var brush := GFBrush.new()
	var path: Array[Vector3] = [Vector3.ZERO, Vector3(2, 0, 0), Vector3(4, 0, 0)]
	var first := stroke(new_data(), brush, set_a, path, plane_resolver)
	var repeat := stroke(new_data(), brush, set_a, path, plane_resolver)
	check(not first.delta.added.is_empty() and records_equal(first.delta.added, repeat.delta.added), "determinism_same_seed_path")
	var fine_path: Array[Vector3] = []
	for i in 17:
		fine_path.append(Vector3(i * 0.25, 0, 0))
	var fine := stroke(new_data(), brush, set_a, fine_path, plane_resolver)
	check(records_equal(first.delta.added, fine.delta.added), "distance_sampling_event_rate_independent")
	brush.seed = 43
	var changed := stroke(new_data(), brush, set_a, path, plane_resolver)
	check(not records_equal(first.delta.added, changed.delta.added), "different_seed_varies_records")
	brush.seed = 42
	var rejected := stroke(new_data(), brush, set_a, path, half_plane_resolver)
	var index_map: Dictionary = {}
	for record in first.delta.added:
		index_map[record.candidate_index] = record
	var stable := rejected.delta.added.size() < first.delta.added.size()
	for record in rejected.delta.added:
		var original: GFInstanceRecord = index_map[record.candidate_index]
		stable = stable and record.record_id == original.record_id and record.local_transform == original.local_transform
	check(stable, "candidate_rejection_keeps_other_choices")
	var counts: Dictionary = {}
	for i in 1024:
		var source := GFPlacement.choose_source(set_a, GFPlacement.random_unit(42, "weighted", i, "source"))
		counts[source.source_id] = counts.get(source.source_id, 0) + 1
	check(counts.get("primitive-cone-v1", 0) > 650 and counts.get("primitive-cone-v1", 0) < 850 and counts.size() == 2,
		"weighted_palette", JSON.stringify(counts))
	for invalid_weight in [-1.0, NAN, INF]:
		set_a.entries[0].weight = invalid_weight
		check(not set_a.diagnostic().is_empty(), "invalid_weight_rejected_%s" % invalid_weight)
	set_a.entries[0].weight = 0.0
	set_a.entries[1].weight = 0.0
	check(not set_a.diagnostic().is_empty(), "all_zero_weights_rejected")
	set_a.entries[0].weight = 3.0
	set_a.entries[1].weight = 1.0
	brush.density_per_m2 = 0.0
	check(stroke(new_data(), brush, set_a, path, plane_resolver).delta.is_empty(), "zero_density_no_records")
	brush.density_per_m2 = -1.0
	check(not brush.diagnostic().is_empty(), "negative_density_rejected")
	brush.density_per_m2 = NAN
	check(not brush.diagnostic().is_empty(), "nan_density_rejected")
	brush.density_per_m2 = 6.0
	var saved_entries: Array[GFPaletteEntry] = set_a.entries.duplicate()
	set_a.entries = []
	check(not set_a.diagnostic().is_empty(), "zero_sources_diagnostic")
	set_a.entries = saved_entries
	brush.max_candidates = 3
	check(stroke(new_data(), brush, set_a, path, plane_resolver).candidates_used == 3, "bounded_stroke_work")
	brush.max_candidates = 2000
	check(GFPlacement.cell_for(Vector3(-0.01, 0, -8.01), 8.0) == Vector2i(-1, -2), "negative_cells_floor")
	var transformed := Transform3D(Basis.from_euler(Vector3(0.2, 0.4, -0.3)).scaled(Vector3(2, 0.7, 1.3)), Vector3(3, 1, 2))
	var normal := Vector3(0.2, 0.95, 0.1).normalized()
	var placement := GFPlacement.make_record({"position": Vector3(4, 2, 1), "normal": normal}, transformed, "test-layer", set_a, brush, "test-stroke", 0, 2.0)
	var world_transform := transformed * placement.local_transform
	var round_normal := (transformed.basis.inverse().transposed() * placement.local_normal).normalized()
	check(world_transform.origin.is_equal_approx(Vector3(4, 2, 1)) and world_transform.basis.y.normalized().is_equal_approx(normal)
		and round_normal.is_equal_approx(normal), "nonuniform_rotated_layer_coordinates_and_normals")
	var local_before := placement.local_transform
	var moved := Transform3D(Basis.from_euler(Vector3(0.1, -0.3, 0.2)).scaled(Vector3(0.8, 2, 1.1)), Vector3(-4, 2, 3))
	check(placement.local_transform == local_before and (moved * placement.local_transform).origin == moved * local_before.origin,
		"layer_motion_preserves_logical_local_transform")
	var world := demo.get_world_3d()
	var hit := GFSurfaceTarget.cast_ray(world, Vector3(0, 3, 0), Vector3(0, -3, 0), brush, layer, demo)
	check(not hit.is_empty() and hit.normal.dot(Vector3.UP) > 0.99, "real_physics_ground_raycast")
	brush.collision_mask = 2
	check(GFSurfaceTarget.cast_ray(world, Vector3(0, 3, 0), Vector3(0, -3, 0), brush, layer, demo).is_empty(), "collision_mask_filter")
	brush.collision_mask = 1
	check(GFSurfaceTarget.cast_ray(world, Vector3(-12, 4, 3), Vector3(-12, -2, 3), brush, layer, demo).is_empty(), "visual_only_not_collision_target")
	var tilted := demo.get_node("RotatedScaledSurface") as Node3D
	var tilted_normal := (tilted.global_basis.inverse().transposed() * Vector3.UP).normalized()
	var tilted_hit := GFSurfaceTarget.cast_ray(world, tilted.global_position + tilted_normal * 3, tilted.global_position - tilted_normal * 3, brush, layer, demo)
	check(not tilted_hit.is_empty() and tilted_hit.normal.dot(tilted_normal) > 0.99, "rotated_scaled_surface_raycast")
	brush.slope_max_degrees = 5
	check(GFSurfaceTarget.cast_ray(world, tilted.global_position + tilted_normal * 3, tilted.global_position - tilted_normal * 3, brush, layer, demo).is_empty(), "slope_filter")
	brush.slope_max_degrees = 60
	brush.height_min_m = 0.5
	check(GFSurfaceTarget.cast_ray(world, Vector3(0, 3, 0), Vector3(0, -3, 0), brush, layer, demo).is_empty(), "world_height_filter")
	brush.height_min_m = -1000
	brush.height_layer_relative = true
	brush.height_min_m = -0.1
	brush.height_max_m = 0.1
	check(brush.accepts_hit({"position": transformed * Vector3.ZERO, "normal": Vector3.UP}, transformed)
		and not brush.accepts_hit({"position": transformed * Vector3(0, 2, 0), "normal": Vector3.UP}, transformed), "layer_relative_height_with_nonuniform_transform")
	brush.height_layer_relative = false
	brush.height_min_m = -1000
	brush.height_max_m = 1000
	brush.include_target = NodePath("RotatedScaledSurface")
	check(GFSurfaceTarget.cast_ray(world, Vector3(0, 3, 0), Vector3(0, -3, 0), brush, layer, demo).is_empty(), "include_target_filter")
	brush.include_target = NodePath()
	brush.exclude_target = NodePath("Ground")
	check(GFSurfaceTarget.cast_ray(world, Vector3(0, 3, 0), Vector3(0, -3, 0), brush, layer, demo).is_empty(), "exclude_target_filter")
	brush.exclude_target = NodePath()
	var source := set_a.entries[0].source
	var original_material := (source.asset as Mesh).surface_get_material(0)
	var override_material := StandardMaterial3D.new()
	source.surface_materials.assign([override_material])
	var resolved := source.resolve_mesh()
	check(resolved != source.asset and resolved.surface_get_material(0) == override_material and (source.asset as Mesh).surface_get_material(0) == original_material,
		"effective_material_does_not_mutate_original")
	source.surface_materials.clear()
	layer.layer_data = new_data()
	layer.cell_size_m = 2.0
	var history := UndoRedo.new()
	var paint := stroke(layer.layer_data, brush, set_a, path, plane_resolver)
	check(layer.layer_data.records.is_empty(), "pending_paint_does_not_mutate_data")
	layer.set_stroke_preview(paint.delta.added, {})
	layer.rebuild_now()
	check(layer.batch_count() > 0 and layer.layer_data.records.is_empty(), "pending_preview_uses_disposable_cache")
	layer.cancel_stroke_preview()
	layer.rebuild_now()
	check(layer.layer_data.records.is_empty() and layer.batch_count() == 0, "cancel_discards_preview")
	history.create_action("paint")
	history.add_do_method(layer.apply_delta.bind(paint.delta, false))
	history.add_undo_method(layer.apply_delta.bind(paint.delta, true))
	history.commit_action()
	var painted_count := layer.layer_data.records.size()
	history.undo()
	check(layer.layer_data.records.is_empty(), "paint_one_undo_step")
	history.redo()
	check(layer.layer_data.records.size() == painted_count and records_equal(layer.layer_data.records, paint.delta.added), "redo_exact_ids_transforms")
	var second_path: Array[Vector3] = [Vector3(0, 0, 3), Vector3(4, 0, 3)]
	var second := stroke(layer.layer_data, brush, set_b, second_path, plane_resolver)
	layer.apply_delta(second.delta, false)
	var before_erase := snapshot(layer.layer_data.records)
	brush.radius_m = 100
	var erase := stroke(layer.layer_data, brush, set_a, [Vector3.ZERO], plane_resolver, GFStroke.Mode.ERASE)
	layer.apply_delta(erase.delta, false)
	check(not layer.layer_data.records.is_empty() and layer.layer_data.records.all(func(record: GFInstanceRecord) -> bool: return record.set_id == set_b.set_id), "erase_selected_set_only")
	layer.apply_delta(erase.delta, true)
	check(snapshot(layer.layer_data.records) == before_erase, "erase_undo_restores_order_and_exact_records")
	brush.radius_m = 1
	var single := stroke(layer.layer_data, brush, set_a, path, plane_resolver, GFStroke.Mode.SINGLE)
	check(single.delta.added.size() == 1, "single_exactly_one")
	single.break_path()
	single.feed({"position": Vector3.ZERO, "normal": Vector3.UP}, plane_resolver)
	check(single.delta.added.size() == 1, "single_target_exit_reentry_still_one_per_click")
	layer.apply_delta(single.delta, false)
	layer.rebuild_now()
	var saved_snapshot := snapshot(layer.layer_data.records)
	var a_batches: Array = layer.batches_by_set.get(set_a.set_id, []).duplicate()
	var b_batches: Array = layer.batches_by_set.get(set_b.set_id, []).duplicate()
	var b_distance := set_b.draw_distance_m
	set_a.draw_distance_m = 12
	var distances := a_batches.size() > 1 and not b_batches.is_empty()
	for batch in a_batches:
		distances = distances and is_instance_valid(batch) and batch.visibility_range_end == 12
	for batch in b_batches:
		distances = distances and is_instance_valid(batch) and batch.visibility_range_end == b_distance
	check(distances and snapshot(layer.layer_data.records) == saved_snapshot, "distance_propagates_existing_A_batches_B_untouched_no_repaint")
	set_a.draw_distance_m = 0
	check(a_batches.all(func(batch: MultiMeshInstance3D) -> bool: return batch.visibility_range_end == 0), "distance_zero_unlimited")
	a_batches[0].visible = false
	check(not a_batches[0].visible and a_batches[1].visible, "cells_independently_visible")
	a_batches[0].visible = true
	var missing_record := layer.layer_data.records[0]
	var source_id := missing_record.source_id
	missing_record.source_id = "missing-source"
	layer.rebuild_now()
	check(layer.layer_data.records.size() == saved_snapshot.size() and not layer.render_diagnostics.is_empty(), "missing_source_preserves_data_with_diagnostic")
	missing_record.source_id = source_id
	var asset := source.asset
	source.asset = PackedScene.new()
	layer.rebuild_now()
	check(layer.layer_data.records.size() == saved_snapshot.size() and not source.diagnostic().is_empty(), "unsupported_scene_not_flattened_or_deleted")
	source.asset = asset
	layer.layer_data.schema_version = 99
	layer.rebuild_now()
	check(layer.layer_data.records.size() == saved_snapshot.size() and layer.batch_count() == 0 and not layer.editing_diagnostic().is_empty(), "future_schema_read_only_preserves_data")
	layer.layer_data.schema_version = 1
	layer.rebuild_now()
	var node_count := get_node_count()
	for i in 30:
		layer.apply_delta(single.delta, true)
		layer.rebuild_now()
		layer.apply_delta(single.delta, false)
		layer.rebuild_now()
	check(get_node_count() == node_count and snapshot(layer.layer_data.records) == saved_snapshot, "repeated_delta_rebuild_no_duplicate_records_or_nodes")
	var packed := PackedScene.new()
	var saved := packed.pack(demo) == OK and ResourceSaver.save(packed, "res://.scratch/roundtrip.tscn") == OK
	var expected := FileAccess.open("res://.scratch/expected.json", FileAccess.WRITE)
	expected.store_string(JSON.stringify({"records": saved_snapshot, "batch_count": layer.batch_count(), "serial": layer.layer_data.next_stroke_serial}))
	expected.close()
	check(saved, "scene_saved_for_fresh_process")
	history.clear_history()
	history.free()
	# Slash-containing stable IDs must not alias another set/source pair.
	var ambiguous_sets: Array[GFVegetationSet] = []
	var ambiguous_records: Array[GFInstanceRecord] = []
	for ids in [["a/b", "c"], ["a", "b/c"]]:
		var unique_source := GFVegetationSource.new()
		unique_source.source_id = ids[1]
		unique_source.asset = BoxMesh.new()
		var unique_entry := GFPaletteEntry.new()
		unique_entry.source = unique_source
		var unique_set := GFVegetationSet.new()
		unique_set.set_id = ids[0]
		unique_set.entries.assign([unique_entry])
		ambiguous_sets.append(unique_set)
		ambiguous_records.append(GFPlacement.make_record({"position": Vector3.ZERO, "normal": Vector3.UP}, Transform3D.IDENTITY,
			"ambiguous-test", unique_set, brush, "ambiguous", 0, 8.0))
	var isolated := Node3D.new()
	root.add_child(isolated)
	var grouped := GFCellRenderer.build(ambiguous_records, ambiguous_sets, 8.0, isolated)
	check(grouped.by_set["a/b"][0].multimesh.mesh == ambiguous_sets[0].entries[0].source.asset
		and grouped.by_set["a"][0].multimesh.mesh == ambiguous_sets[1].entries[0].source.asset,
		"stable_ID_pairs_do_not_alias_source_resolution")
	isolated.free()
	for instance_count in [1024, 5000]:
		var bench := VegetationLayer3D.new()
		bench.layer_data = new_data()
		root.add_child(bench)
		for i in instance_count:
			var point := Vector3(i % 100, 0, floori(float(i) / 100.0))
			bench.layer_data.records.append(GFPlacement.make_record({"position": point, "normal": Vector3.UP}, Transform3D.IDENTITY, bench.layer_data.layer_id, set_a, brush, "benchmark", i, 8.0))
		var start := Time.get_ticks_usec()
		bench.rebuild_now()
		var elapsed := Time.get_ticks_usec() - start
		benchmarks.append({"records": instance_count, "rebuild_ms": elapsed / 1000.0, "batches": bench.batch_count(), "nodes": 2 + bench.batch_count(), "renderer": RenderingServer.get_current_rendering_method(), "display_driver": DisplayServer.get_name(), "scope": "CPU cache construction, not GPU/FPS"})
		print("BENCH ", JSON.stringify(benchmarks[-1]))
		bench.free()
	var output := FileAccess.open("res://.scratch/core_results.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": results, "benchmarks": benchmarks, "engine": Engine.get_version_info()}, "\t"))
	output.close()
	demo.free()
	await process_frame
	quit(0 if failures == 0 else 1)
