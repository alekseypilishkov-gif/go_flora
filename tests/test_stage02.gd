extends SceneTree

var failures := 0
var results: Array = []
var benchmarks: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + id + " " + detail)
	results.append({"id": id, "status": "PASS" if ok else "FAIL", "detail": detail})
	failures += 0 if ok else 1

func source_for(path: String, id: String) -> GFVegetationSource:
	var source := GFVegetationSource.new()
	source.source_id = id
	source.kind = GFVegetationSource.Kind.IMPORTED_SCENE
	source.asset = load(path)
	return source

func card_source(texture: String, mode: GFAlphaCard.Mode = GFAlphaCard.Mode.CROSSED) -> GFVegetationSource:
	var source := GFVegetationSource.new()
	source.source_id = "card-" + texture.get_file() + str(mode)
	source.kind = GFVegetationSource.Kind.ALPHA_CARD
	source.alpha_card = GFAlphaCard.new()
	source.alpha_card.texture = load(texture)
	source.alpha_card.mode = mode
	return source

func set_for(source: GFVegetationSource, id: String) -> GFVegetationSet:
	var result := GFVegetationSet.new()
	result.set_id = id
	var entry := GFPaletteEntry.new()
	entry.source = source
	result.entries.assign([entry])
	return result

func plane(point: Vector3, normal: Vector3) -> Dictionary:
	return {"position": point, "normal": normal}

func snap(records: Array[GFInstanceRecord]) -> String:
	var rows: Array = []
	for record in records:
		rows.append([record.record_id, record.source_id, record.set_id, record.seed, str(record.local_transform), record.source_revision])
	return JSON.stringify(rows)

func make_record(layer: VegetationLayer3D, vegetation_set: GFVegetationSet, index: int = 0) -> GFInstanceRecord:
	return GFPlacement.make_record({"position": Vector3(index * 2, 0, 0), "normal": Vector3.UP}, Transform3D.IDENTITY,
		layer.layer_data.layer_id, vegetation_set, GFBrush.new(), "stage02", index, 8.0)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	check(GFVegetationSource.Kind.STATIC_MESH == 0 and GFVegetationSource.Kind.SCENE_UNSUPPORTED == 1 and GFVegetationSource.Kind.GENERATED_UNSUPPORTED == 2, "legacy_enum_values_unchanged")
	var glb := source_for("res://fixtures/original_plant.glb", "real-glb")
	var file_hash := FileAccess.get_sha256(glb.asset.resource_path)
	var imported := glb.resolve()
	check(imported.status == GFSourceResolution.Status.READY and imported.parts.size() == 2, "real_imported_GLB_two_mesh_parts", imported.diagnostic())
	if imported.parts.size() != 2:
		quit(1)
		return
	check(imported.parts[0].part_id != imported.parts[1].part_id and imported.parts[1].mesh.get_surface_count() == 2, "GLB_stable_part_paths_and_multiple_surfaces")
	var original := (glb.asset as PackedScene).instantiate()
	var originals := original.find_children("*", "MeshInstance3D", true, false)
	var transform_ok := originals.size() == 2
	for part in imported.parts:
		var node := original.get_node(NodePath(part.part_id)) as MeshInstance3D
		var expected := node.transform
		var parent := node.get_parent() as Node3D
		while parent != null:
			expected = parent.transform * expected
			parent = parent.get_parent() as Node3D
		transform_ok = transform_ok and part.transform.is_equal_approx(expected) and part.bounds.is_equal_approx(expected * node.mesh.get_aabb())
		for surface in part.mesh.get_surface_count():
			var arrays := part.mesh.surface_get_arrays(surface)
			var original_arrays := node.mesh.surface_get_arrays(surface)
			check(arrays[Mesh.ARRAY_TEX_UV] == original_arrays[Mesh.ARRAY_TEX_UV] and arrays[Mesh.ARRAY_NORMAL] == original_arrays[Mesh.ARRAY_NORMAL]
				and arrays[Mesh.ARRAY_TANGENT] == original_arrays[Mesh.ARRAY_TANGENT], "GLB_UV_normals_tangents_preserved_%s_%d" % [part.part_id, surface])
	check(transform_ok, "GLB_accumulated_nested_nonuniform_transforms_bounds")
	original.free()
	var scene := source_for("res://fixtures/static_plant.tscn", "static-scene")
	var static_result := scene.resolve()
	check(static_result.status == GFSourceResolution.Status.READY and static_result.parts.size() == 2, "PackedScene_all_static_parts", static_result.diagnostic())
	var authored_mesh: Variant = ((scene.asset as PackedScene).get_state().get_node_property_value(2, 0))
	check(static_result.parts[0].mesh.surface_get_material(0).albedo_color.is_equal_approx(Color(0.8, 0.4, 0.1))
		and static_result.parts[1].mesh.surface_get_material(0).albedo_color.is_equal_approx(Color(0.2, 0.7, 0.9)), "material_priority_instance_over_surface_over_mesh")
	check(FileAccess.get_sha256(glb.asset.resource_path) == file_hash and authored_mesh != null, "original_GLB_file_immutable")
	var reference_scene := (scene.asset as PackedScene).instantiate()
	var original_material: Material = reference_scene.get_node("Pivot/One").mesh.surface_get_material(0)
	check(original_material.albedo_color.is_equal_approx(Color(0.1, 0.6, 0.1)), "original_scene_mesh_material_not_mutated")
	reference_scene.free()
	# The frozen file was saved by Stage 01 main before any addon change.
	var legacy_expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://fixtures/stage01_expected.json"))
	var legacy := load("res://fixtures/stage01_saved.tscn").instantiate() as Node3D
	root.add_child(legacy)
	await process_frame
	var legacy_layer := legacy.get_node("VegetationLayer") as VegetationLayer3D
	var legacy_ok: bool = legacy_layer.layer_data.records.size() == legacy_expected.records.size()
	for i in legacy_layer.layer_data.records.size():
		var record := legacy_layer.layer_data.records[i]
		var row: Dictionary = legacy_expected.records[i]
		legacy_ok = legacy_ok and record.record_id == row.id and record.source_id == row.source and record.set_id == row.set and record.seed == row.seed
		var values: Array = []
		for vector in [record.local_transform.origin, record.local_transform.basis.x, record.local_transform.basis.y, record.local_transform.basis.z, record.local_normal]:
			values.append_array([vector.x, vector.y, vector.z])
		for j in values.size():
			legacy_ok = legacy_ok and absf(values[j] - row.values[j]) < 0.00001
	check(legacy_ok and legacy_layer.batch_count() == int(legacy_expected.batch_count), "frozen_pre_stage02_scene_identical_records_transforms_batches")
	legacy.free()
	# Reject unsupported authored features without instantiating their scene.
	for type in ["AnimationPlayer", "Skeleton3D", "OmniLight3D", "GPUParticles3D"]:
		var invalid_root := Node3D.new()
		var feature: Node = ClassDB.instantiate(type)
		feature.name = "UnsupportedFeature"
		invalid_root.add_child(feature)
		feature.owner = invalid_root
		var invalid := PackedScene.new()
		invalid.pack(invalid_root)
		invalid_root.free()
		var invalid_source := GFVegetationSource.new()
		invalid_source.source_id = "unsupported-" + type
		invalid_source.kind = GFVegetationSource.Kind.IMPORTED_SCENE
		invalid_source.asset = invalid
		check(invalid_source.resolve().status == GFSourceResolution.Status.UNSUPPORTED and invalid_source.diagnostic().contains(type), "unsupported_feature_precise_" + type)
	var unknown_script := FileAccess.open("res://.scratch/unknown_tool.gd", FileAccess.WRITE)
	unknown_script.store_string("@tool\nextends Node3D\nfunc _init():\n\tFileAccess.open('res://.scratch/UNSAFE_EXECUTED', FileAccess.WRITE).store_string('bad')\n")
	unknown_script.close()
	var unknown_scene := FileAccess.open("res://.scratch/unknown_scene.tscn", FileAccess.WRITE)
	unknown_scene.store_string('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://.scratch/unknown_tool.gd" id="1"]\n[node name="Unknown" type="Node3D"]\nscript = ExtResource("1")\n')
	unknown_scene.close()
	var unknown := source_for("res://.scratch/unknown_scene.tscn", "unknown-tool")
	unknown.allow_scene_fallback = true
	unknown.reviewed_scene_revision = unknown.resolve().revision
	check(unknown.resolve().status == GFSourceResolution.Status.UNSUPPORTED and not FileAccess.file_exists("res://.scratch/UNSAFE_EXECUTED"), "unknown_tool_script_never_executed_for_resolution")
	var cards: Array[GFVegetationSource] = []
	for mode in [GFAlphaCard.Mode.SINGLE, GFAlphaCard.Mode.CROSSED, GFAlphaCard.Mode.RADIAL]:
		var source := card_source("res://fixtures/grass.png", mode)
		cards.append(source)
		for count in ([3, 4] if mode == GFAlphaCard.Mode.RADIAL else [3]):
			source.alpha_card.radial_count = count
			var resolved := source.resolve()
			check(resolved.status == GFSourceResolution.Status.READY, "card_valid_%d_%d" % [mode, count], resolved.diagnostic())
			var mesh := resolved.parts[0].mesh
			var arrays := mesh.surface_get_arrays(0)
			var n: int = 1 if mode == 0 else (2 if mode == 1 else count)
			check(arrays[Mesh.ARRAY_VERTEX].size() == n * 4 and arrays[Mesh.ARRAY_INDEX].size() == n * 6
				and arrays[Mesh.ARRAY_COLOR] == null and arrays[Mesh.ARRAY_TANGENT].size() == n * 16, "card_bounded_geometry_no_vertex_colors_%d_%d" % [mode, count])
			var normals_ok := true
			for i in n:
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var normal: Vector3 = arrays[Mesh.ARRAY_NORMAL][i * 4]
				normals_ok = normals_ok and is_equal_approx(normal.length(), 1.0) and absf(normal.dot(vertices[i * 4 + 1] - vertices[i * 4])) < 0.00001
				var winding: Vector3 = (vertices[i * 4 + 2] - vertices[i * 4]).cross(vertices[i * 4 + 1] - vertices[i * 4]).normalized()
				normals_ok = normals_ok and winding.dot(normal) < -0.99
			check(normals_ok and is_zero_approx(mesh.get_aabb().position.y) and is_equal_approx(mesh.get_aabb().size.y, 1.0), "card_normals_winding_ground_height_%d_%d" % [mode, count])
			var material := mesh.surface_get_material(0) as StandardMaterial3D
			check(material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR and material.cull_mode == BaseMaterial3D.CULL_DISABLED
				and material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS and not material.texture_repeat, "card_owned_scissor_filter_flags_%d_%d" % [mode, count])
	var atlas := card_source("res://fixtures/atlas.png")
	cards[0].alpha_card.splay_degrees = 25
	check(is_zero_approx(cards[0].resolve().parts[0].mesh.get_aabb().position.y) and is_equal_approx(cards[0].resolve().parts[0].mesh.get_aabb().size.y, cards[0].alpha_card.height_m), "splayed_card_vertical_height_ground_pivot")
	cards[0].alpha_card.splay_degrees = 0
	atlas.alpha_card.atlas_region_px = Rect2i(4, 8, 128, 128)
	atlas.alpha_card.gutter_px = 2
	var uv: PackedVector2Array = atlas.resolve().parts[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	check(uv[3].is_equal_approx(Vector2(6.0 / 272.0, 10.0 / 144.0)) and uv[1].is_equal_approx(Vector2(130.0 / 272.0, 134.0 / 144.0)), "atlas_pixel_region_inset_UV_top_bottom")
	atlas.alpha_card.atlas_region_px = Rect2i(260, 0, 128, 128)
	check(atlas.resolve().status != GFSourceResolution.Status.READY, "atlas_out_of_bounds_rejected")
	atlas.alpha_card.atlas_region_px = Rect2i(4, 8, 128, 128)
	atlas.alpha_card.gutter_px = 80
	check(atlas.resolve().status != GFSourceResolution.Status.READY, "atlas_consumed_gutter_rejected")
	var webp := card_source("res://fixtures/grass.webp")
	check(webp.resolve().status == GFSourceResolution.Status.READY and webp.alpha_card.texture.get_image().detect_alpha() != Image.ALPHA_NONE, "lossless_WebP_import_alpha")
	var tex_hash := FileAccess.get_sha256("res://fixtures/grass.png")
	var first_mesh := cards[0].resolve().parts[0].mesh
	check(first_mesh == cards[0].resolve().parts[0].mesh, "shared_deterministic_card_cache")
	cards[0].alpha_card.width_m = 1.2
	check(cards[0].resolve().parts[0].mesh != first_mesh and is_equal_approx(cards[0].resolve().parts[0].mesh.get_aabb().size.x, 1.2)
		and FileAccess.get_sha256("res://fixtures/grass.png") == tex_hash, "card_parameter_invalidation_original_texture_immutable")
	var fallback := source_for("res://fixtures/authored_plant.tscn", "authored")
	var blocked := fallback.resolve()
	check(blocked.status == GFSourceResolution.Status.UNSUPPORTED and blocked.diagnostic().contains("script") and blocked.diagnostic().contains("StaticBody3D"), "authored_semantics_blocked_before_review", blocked.diagnostic())
	fallback.allow_scene_fallback = true
	fallback.reviewed_scene_revision = blocked.revision
	check(fallback.resolve().status == GFSourceResolution.Status.READY and fallback.resolve().scene != null and fallback.resolve().capabilities.scene_instances, "reviewed_scene_fallback_explicit_capabilities")
	check(not GFSourceResolver.project_path("res://../outside.png") and not GFSourceResolver.project_path("C:/outside.png") and not GFSourceResolver.project_path("user://outside.png"), "source_paths_confined_to_project")
	var layer := VegetationLayer3D.new()
	layer.layer_data.layer_id = "stage02-layer"
	var sources: Array[GFVegetationSource] = [glb, scene, cards[1], fallback]
	for i in sources.size():
		layer.layer_data.sets.append(set_for(sources[i], "set-%d" % i))
	root.add_child(layer)
	await process_frame
	# Paint with mixed imported/card sources uses the original weighted and seed rules.
	var mixed := set_for(glb, "mixed")
	for source in [scene, cards[1], fallback]:
		var entry := GFPaletteEntry.new()
		entry.source = source
		mixed.entries.append(entry)
	var trial := GFVegetationLayerData.new()
	trial.layer_id = "mixed-test"
	trial.sets.assign([mixed])
	var paint := GFStroke.new()
	var repeat := GFStroke.new()
	for stroke in [paint, repeat]:
		stroke.begin(trial, Transform3D.IDENTITY, mixed, GFBrush.new(), 8, GFStroke.Mode.PAINT)
		for point in [Vector3.ZERO, Vector3(4, 1, 0), Vector3(8, 2, 0)]:
			stroke.feed({"position": point, "normal": Vector3(-0.2, 1, 0).normalized()}, plane)
		stroke.finish_delta()
	var chosen: Dictionary = {}
	for record in paint.delta.added:
		chosen[record.source_id] = true
	check(snap(paint.delta.added) == snap(repeat.delta.added) and chosen.size() == 4, "mixed_weighted_paint_deterministic_tilted_surface")
	paint.delta.apply_to(trial, false)
	var erased := GFStroke.new()
	var erase_brush := GFBrush.new()
	erase_brush.radius_m = 100
	erased.begin(trial, Transform3D.IDENTITY, mixed, erase_brush, 8, GFStroke.Mode.ERASE)
	erased.feed({"position": Vector3.ZERO, "normal": Vector3.UP}, plane)
	erased.finish_delta().apply_to(trial, false)
	check(trial.records.is_empty(), "mixed_erase_all_source_types")
	erased.delta.apply_to(trial, true)
	check(snap(trial.records) == snap(paint.delta.added), "mixed_erase_undo_restores_order_ID_transform")
	for vegetation_set in layer.layer_data.sets:
		var stroke := GFStroke.new()
		check(stroke.begin(layer.layer_data, Transform3D.IDENTITY, vegetation_set, GFBrush.new(), 8, GFStroke.Mode.SINGLE), "single_begin_" + vegetation_set.set_id)
		stroke.feed({"position": Vector3.ZERO, "normal": Vector3.UP}, plane)
		stroke.finish_delta()
		layer.set_stroke_preview(stroke.delta.added, {})
		layer.rebuild_now()
		check(layer.layer_data.records.is_empty() and layer.batch_count() > 0, "pending_preview_no_records_" + vegetation_set.set_id)
		layer.cancel_stroke_preview()
		layer.rebuild_now()
		check(layer.batch_count() == 0 and layer._scene_cache.is_empty(), "cancel_no_orphans_" + vegetation_set.set_id)
		layer.apply_delta(stroke.delta, false)
		layer.rebuild_now()
		var before := snap(layer.layer_data.records)
		layer.apply_delta(stroke.delta, true)
		layer.rebuild_now()
		check(layer.layer_data.records.is_empty() and layer._scene_cache.is_empty() and layer.batch_count() == 0, "undo_all_parts_removed_" + vegetation_set.set_id)
		layer.apply_delta(stroke.delta, false)
		layer.rebuild_now()
		check(snap(layer.layer_data.records) == before, "redo_exact_record_" + vegetation_set.set_id)
		layer.apply_delta(stroke.delta, true)
		layer.rebuild_now()
	for vegetation_set in layer.layer_data.sets:
		layer.layer_data.records.append(make_record(layer, vegetation_set, layer.layer_data.records.size()))
	layer.rebuild_now()
	var snapshot := snap(layer.layer_data.records)
	check(layer.batches_by_set["set-0"].size() == 2 and layer.batches_by_set["set-1"].size() == 2 and layer._scene_cache.size() == 1, "one_record_many_parts_and_managed_scene")
	await process_frame
	await process_frame
	var instance: Node3D = layer._scene_cache.values()[0]
	check(instance.get_meta("authored_ready", false) and instance.ticks > 0 and instance.signal_count == 1 and instance.is_in_group("original_plants")
		and instance.get_node("Collider/Shape").shape != null and instance.get_node("Collider").collision_layer == 4, "fallback_script_signals_collider_preserved")
	await physics_frame
	await physics_frame
	var query := PhysicsRayQueryParameters3D.create(Vector3(6, 3, 0), Vector3(6, -1, 0), 4)
	check(not layer.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "fallback_real_physics_authored_collider")
	var ticks: int = instance.ticks
	layer.layer_data.sets[3].draw_distance_m = 0.1
	layer.layer_data.sets[3].enabled = false
	for i in 3:
		await process_frame
	check(instance.ticks > ticks and instance.get_node("Collider").collision_layer == 4 and not instance.get_node("Visual").visible, "fallback_hidden_visual_gameplay_keeps_processing_collision",
		"ticks %d -> %d; visible=%s" % [ticks, instance.ticks, instance.get_node("Visual").visible])
	layer.rebuild_now()
	check(layer._scene_cache.values()[0] == instance and instance.signal_count == 1, "fallback_lifecycle_survives_static_cache_rebuild")
	layer.layer_data.sets[3].enabled = true
	for i in 3:
		var set_a := layer.layer_data.sets[i]
		var before_nodes: Array = layer.batches_by_set[set_a.set_id].duplicate()
		set_a.draw_distance_m = 13 + i
		check(before_nodes.all(func(batch: GeometryInstance3D) -> bool: return is_instance_valid(batch) and batch.visibility_range_end == 13 + i)
			and layer.layer_data.sets[3].draw_distance_m == 0.1 and snap(layer.layer_data.records) == snapshot, "distance_existing_parts_B_records_unchanged_%d" % i)
		set_a.draw_distance_m = 0
		check(before_nodes.all(func(batch: GeometryInstance3D) -> bool: return batch.visibility_range_end == 0), "distance_zero_%d" % i)
	var old_kind := glb.kind
	glb.kind = GFVegetationSource.Kind.SCENE_UNSUPPORTED
	layer.rebuild_now()
	check(snap(layer.layer_data.records) == snapshot and not layer.render_diagnostics.is_empty(), "legacy_unsupported_keeps_logical_data")
	glb.kind = old_kind
	glb.asset = null
	layer.rebuild_now()
	check(snap(layer.layer_data.records) == snapshot and glb.resolve().status == GFSourceResolution.Status.UNAVAILABLE, "missing_GLB_keeps_records")
	glb.asset = load("res://fixtures/original_plant.glb")
	cards[1].alpha_card.texture = null
	layer.rebuild_now()
	check(snap(layer.layer_data.records) == snapshot and not cards[1].diagnostic().is_empty(), "missing_texture_keeps_records")
	cards[1].alpha_card.texture = load("res://fixtures/grass.png")
	for schema in [0, 99]:
		glb.schema_version = schema
		layer.rebuild_now()
		check(snap(layer.layer_data.records) == snapshot and glb.resolve().status == GFSourceResolution.Status.UNSUPPORTED, "source_schema_readonly_%d" % schema)
	glb.schema_version = 1
	layer.layer_data.schema_version = 99
	layer.rebuild_now()
	check(snap(layer.layer_data.records) == snapshot and layer.batch_count() == 0, "future_layer_schema_preserves_records")
	layer.layer_data.schema_version = 1
	layer.layer_data.records[0].schema_version = 99
	layer.rebuild_now()
	check(layer.layer_data.records.size() == 4 and layer.batch_count() == 0 and not layer.editing_diagnostic().is_empty(), "future_record_schema_preserved_not_rendered")
	layer.layer_data.records[0].schema_version = 1
	var valid_transform := layer.layer_data.records[0].local_transform
	layer.layer_data.records[0].local_transform.origin.x = NAN
	layer.rebuild_now()
	check(layer.layer_data.records.size() == 4 and layer.batch_count() == 0 and not layer.editing_diagnostic().is_empty(), "corrupted_record_coordinate_preserved_not_rendered")
	layer.layer_data.records[0].local_transform = valid_transform
	fallback.reviewed_scene_revision = "stale-review"
	layer.rebuild_now()
	check(layer._scene_cache.is_empty() and snap(layer.layer_data.records) == snapshot and fallback.diagnostic().contains("review"), "changed_scene_revision_requires_review_no_record_loss")
	fallback.reviewed_scene_revision = fallback.resolve().revision
	layer.rebuild_now()
	# Save native sources and placements; next process verifies exact records and rebuilt parts.
	layer.name = "Stage02Layer"
	var packed := PackedScene.new()
	check(packed.pack(layer) == OK and ResourceSaver.save(packed, "res://.scratch/stage02_roundtrip.tscn") == OK, "stage02_native_scene_saved")
	var expected := FileAccess.open("res://.scratch/stage02_expected.json", FileAccess.WRITE)
	var saved_records: Array = []
	for record in layer.layer_data.records:
		var values: Array = []
		for vector in [record.local_transform.origin, record.local_transform.basis.x, record.local_transform.basis.y, record.local_transform.basis.z]:
			values.append_array([vector.x, vector.y, vector.z])
		saved_records.append({"id": record.record_id, "source": record.source_id, "set": record.set_id, "seed": record.seed, "revision": record.source_revision, "values": values})
	expected.store_string(JSON.stringify({"records": saved_records, "batches": layer.batch_count()}))
	expected.close()
	# Moderate CPU-only benchmarks. No GPU/FPS inference from this timer.
	for source in [cards[1], glb]:
		for count in [1000, 5000]:
			var bench := VegetationLayer3D.new()
			bench.layer_data.layer_id = "bench"
			var vegetation_set := set_for(source, "bench-set")
			bench.layer_data.sets.assign([vegetation_set])
			root.add_child(bench)
			for i in count:
				var record := make_record(bench, vegetation_set, i)
				record.local_transform.origin = Vector3(i % 100, 0, i / 100)
				bench.layer_data.records.append(record)
			var memory := OS.get_static_memory_usage()
			var start := Time.get_ticks_usec()
			bench.rebuild_now()
			var elapsed := (Time.get_ticks_usec() - start) / 1000.0
			var row := {"source": source.source_id, "records": count, "parts_per_record": source.resolve().parts.size(), "batches": bench.batch_count(), "cache_ms": elapsed,
				"static_memory_delta_bytes": OS.get_static_memory_usage() - memory, "scope": "headless CPU cache construction, not GPU/FPS"}
			benchmarks.append(row)
			print("BENCH ", JSON.stringify(row))
			bench.free()
	var output := FileAccess.open("res://.scratch/stage02_results.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": results, "benchmarks": benchmarks}, "\t"))
	output.close()
	layer.free()
	await process_frame
	print(("PASS " if failures == 0 else "FAIL ") + "STAGE02_COMPLETE")
	quit(0 if failures == 0 else 1)
