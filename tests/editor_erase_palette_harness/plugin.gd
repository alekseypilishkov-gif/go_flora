@tool
extends EditorPlugin

var failed := false
var results: Array = []
var erase_tick_CPU_usec: Array = []
const Visual = preload("res://tests/stage023_visual.gd")

func _enter_tree() -> void:
	call_deferred("run")

func frames(count: int = 6) -> void:
	for i in count:
		await get_tree().process_frame

func check(ok: bool, id: String, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + "STAGE023_EDITOR " + id + " " + detail)
	results.append({"id": id, "status": "PASS" if ok else "FAIL", "detail": detail})
	failed = failed or not ok

func start(plugin: EditorPlugin, layer: VegetationLayer3D) -> void:
	plugin.mode = 2
	plugin._stroke_layer = layer
	plugin._stroke_transform = layer.global_transform
	plugin._stroke = GFStroke.new()
	plugin._stroke.begin(layer.layer_data, layer.global_transform, plugin.active_set, plugin.brush, 8, GFStroke.Mode.ERASE)
	layer.layer_data.changed.connect(plugin.cancel_stroke)
	plugin._stroke.feed({"position": Vector3.ZERO, "normal": Vector3.UP}, Callable())

func run() -> void:
	var scene: Node
	var plugin: EditorPlugin
	for i in 600:
		scene = get_editor_interface().get_edited_scene_root()
		var plugins := get_tree().get_nodes_in_group("go_flora_editor_plugin")
		if scene != null and plugins.size() == 1:
			plugin = plugins[0]
			break
		await frames(1)
	check(plugin != null and scene != null, "plugin_enabled")
	if plugin == null or scene == null:
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var layer := scene.get_node("VegetationLayer") as VegetationLayer3D
	plugin._edit(layer)
	plugin._refresh_sets()
	var data := layer.layer_data
	var vegetation_set := data.sets[0]
	var entry := vegetation_set.entries[0]
	var source := entry.source
	source.asset = BoxMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.GREEN
	source.surface_materials.assign([material])
	source.mesh_transform.origin = Vector3(0, 0.5, 0)
	data.records.clear()
	for i in 5000:
		var record := GFInstanceRecord.new()
		record.record_id = "native-%d" % i
		record.layer_id = data.layer_id
		record.set_id = vegetation_set.set_id
		record.source_id = source.source_id
		data.records.append(record)
	data.emit_changed()
	await frames()
	var original := data.records.duplicate()
	var manager := plugin.get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(layer))
	manager.clear_history(manager.get_object_history_id(layer), false)
	plugin.brush.radius_m = 1
	start(plugin, layer)
	plugin.commit_stroke()
	check(plugin._stroke_releasing and data.records == original and not history.has_undo(), "release_waits_for_complete_queue_no_partial_commit")
	plugin._cancel_unhandled_release()
	check(plugin._stroke != null, "valid_release_survives_deferred_outside_release_guard")
	var ticks := 0
	while plugin._stroke != null and ticks < 600:
		await frames(1)
		ticks += 1
	check(data.records.is_empty() and ticks < 600, "stationary_held_click_drains_5000_automatic_frames", str(ticks))
	history.undo()
	check(data.records == original and not history.has_undo(), "one_native_undo_exact_records_order")
	history.redo()
	check(data.records.is_empty(), "one_native_redo_complete")
	history.undo()
	manager.clear_history(manager.get_object_history_id(layer), false)
	layer.rebuild_now()
	var held_batch_count := layer.batch_count()
	start(plugin, layer)
	plugin.set_process(false)
	while plugin._stroke.has_pending_work():
		var started := Time.get_ticks_usec()
		plugin._process(0)
		erase_tick_CPU_usec.append(Time.get_ticks_usec() - started)
	check(layer.batch_count() == held_batch_count and layer._preview_removed.size() == 5000, "held_erase_updates_existing_batches_incrementally")
	plugin._update_stroke_preview()
	check(layer._preview_removed.size() == 5000, "idle_preview_keeps_all_pending_erased_ids")
	plugin.cancel_stroke()
	plugin.set_process(true)
	await frames()
	check(data.records == original and layer.batch_count() == held_batch_count, "preview_cancel_restores_render_without_saved_mutation")
	start(plugin, layer)
	await frames(2)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	plugin._input(escape)
	check(plugin._stroke == null and data.records == original and not history.has_undo(), "Escape_drops_all_pending_work_no_undo")
	start(plugin, layer)
	plugin._cancel_unhandled_release()
	check(plugin._stroke == null and data.records == original, "outside_viewport_release_cancels")
	start(plugin, layer)
	data.emit_changed()
	check(plugin._stroke == null, "same_data_mutation_cancels_frozen_index")
	start(plugin, layer)
	var other_scene := Node3D.new()
	plugin._on_scene_changed(other_scene)
	check(plugin._stroke == null and data.records == original, "scene_switch_isolation")
	plugin._on_scene_changed(scene)
	other_scene.free()
	plugin._edit(layer)
	plugin._refresh_sets()
	# Drive the actual viewport callback: press A, release B without motion.
	data.records.assign([original[0], original[1]])
	data.records[0].local_transform.origin = Vector3(0, 0, 2)
	data.records[1].local_transform.origin = Vector3(6, 0, 2)
	data.emit_changed()
	await frames()
	await get_tree().physics_frame
	await get_tree().physics_frame
	manager.clear_history(manager.get_object_history_id(layer), false)
	var camera := scene.get_node("Camera") as Camera3D
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = camera.unproject_position(Vector3(0, 0, 2))
	var handled := plugin._forward_3d_gui_input(camera, press)
	check(handled == EditorPlugin.AFTER_GUI_INPUT_STOP and plugin._stroke != null, "native_viewport_press_hits_collision_surface")
	if plugin._stroke != null:
		for i in 20:
			plugin._stroke.feed({"position": Vector3.ZERO, "normal": Vector3.UP}, Callable())
		check(plugin._stroke._erase_query._indexed == 0, "many_inputs_only_enqueue_before_frame_scheduler")
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.position = camera.unproject_position(Vector3(6, 0, 2))
		plugin._forward_3d_gui_input(camera, release)
		for i in 100:
			if plugin._stroke == null:
				break
			await frames(1)
		check(data.records.is_empty(), "release_endpoint_sweep_included_without_motion_event")
		history.undo()
		check(data.records.size() == 2, "release_routed_one_scene_undo")
	plugin.cancel_stroke()
	original[0].local_transform.origin = Vector3.ZERO
	original[1].local_transform.origin = Vector3.ZERO
	data.records.assign([original[0]])
	data.emit_changed()
	await frames()
	manager.clear_history(manager.get_object_history_id(layer), false)
	plugin._select_palette_source(source.source_id)
	var before := Color.BLACK
	if DisplayServer.get_name() != "headless":
		before = await Visual.capture(data, get_tree(), "res://.scratch/palette_before.png")
		check(before.g > 0.8 and before.r < 0.15, "actual_GPU_before_removal_green_instance", str(before))
	else:
		print("NOT_RUN STAGE023_GPU headless editor")
	var batches := layer.batch_count()
	check(plugin._palette.rows[0].remove.tooltip_text.contains("Remove from Palette"), "dock_visible_remove_button")
	plugin._palette.rows[0].remove.pressed.emit()
	check(plugin._remove_dialog != null and not plugin._remove_dialog.exclusive and plugin._remove_dialog.dialog_text.contains("1"), "safe_confirmation_count_nonexclusive")
	plugin._remove_dialog.confirmed.emit()
	await frames()
	check(not vegetation_set.entries.has(entry) and vegetation_set.render_only_sources.has(source) and data.records.size() == 1, "plain_remove_row_archive_keeps_records")
	check(plugin.source_mode == 1 and plugin.selected_source_id == source.source_id and not plugin.brush_source_diagnostic().is_empty(), "removed_selected_source_explicit_block_no_wrong_paint")
	check(layer.batch_count() == batches and layer.render_diagnostics.is_empty(), "retained_source_resolves_no_lost_batches_no_missing_diagnostics")
	if DisplayServer.get_name() != "headless":
		var after := await Visual.capture(data, get_tree(), "res://.scratch/palette_removed.png")
		check(after.is_equal_approx(before), "actual_GPU_retained_source_same_pixel", str(after))
	history.undo()
	await frames()
	check(vegetation_set.entries[0] == entry and entry.weight == 3 and entry.enabled and vegetation_set.render_only_sources.is_empty(), "palette_undo_exact_entry_order_weight_enabled")
	history.redo()
	await frames()
	check(plugin._palette.rows.size() == 1 and layer.batch_count() == batches, "redo_refreshes_row_keeps_batches")
	plugin.append_palette_source(vegetation_set, source)
	await frames()
	check(vegetation_set.entries.size() == 2 and vegetation_set.render_only_sources.is_empty(), "readd_same_ID_unarchives_atomically")
	plugin.append_palette_source(vegetation_set, source)
	check(vegetation_set.entries.size() == 2, "duplicate_ID_readd_refused")
	history.undo()
	await frames()
	check(vegetation_set.render_only_sources.has(source) and vegetation_set.source_by_id(source.source_id) == null, "readd_undo_restores_render_only")
	# Save the true removed-row state for an independent Godot process.
	var saved := Node3D.new()
	var saved_layer := VegetationLayer3D.new()
	saved_layer.name = "VegetationLayer"
	saved_layer.layer_data = data
	saved.add_child(saved_layer)
	saved_layer.owner = saved
	var packed := PackedScene.new()
	check(packed.pack(saved) == OK and ResourceSaver.save(packed, "res://.scratch/palette_saved.tscn") == OK, "archive_saved_in_scene_no_schema_migration")
	saved.free()
	# Archived resources still drive render rebuilds.
	source.variant_revision = "retained-revised"
	await frames()
	check(layer.render_diagnostics.is_empty() and layer.batch_count() == batches, "archived_revision_observed_rebuilds")
	material.albedo_color = Color.BLUE
	await frames()
	check(layer._bindings.any(func(binding: Dictionary) -> bool: return binding.resource == material) and layer.render_diagnostics.is_empty(), "archived_material_observed_rebuilds")
	if DisplayServer.get_name() != "headless":
		var revised := await Visual.capture(data, get_tree(), "res://.scratch/palette_material_revised.png")
		check(revised.b > 0.8 and revised.g < 0.15, "actual_GPU_archived_material_change_visible", str(revised))
	material.albedo_color = Color.GREEN
	# Inspector uses the same stable entry and controller path.
	history.redo()
	plugin.inspect_resource(vegetation_set)
	await frames(15)
	var properties := get_tree().get_nodes_in_group("go_flora_palette_properties")
	var property: EditorProperty
	for candidate in properties:
		if candidate.get_edited_object() == vegetation_set:
			property = candidate
	check(property != null and property.palette.rows.all(func(row: Dictionary) -> bool: return row.remove != null), "Inspector_visible_remove_controls")
	var zero_entry := vegetation_set.entries[0]
	plugin.request_palette_removal(vegetation_set, zero_entry)
	await frames()
	check(not vegetation_set.entries.has(zero_entry) and data.records.size() == 1, "zero_placements_remove_immediate")
	history.undo()
	await frames()
	check(vegetation_set.entries[0] == zero_entry, "zero_placements_undo_exact_order")
	# Duplicate requests from stale dock/Inspector rows do not add an undo action.
	var other_set_record := original[1].duplicate() as GFInstanceRecord
	other_set_record.record_id = "other-set-same-source"
	other_set_record.set_id = data.sets[1].set_id
	var other_source_record := original[2].duplicate() as GFInstanceRecord
	other_source_record.record_id = "same-set-other-source"
	other_source_record.source_id = zero_entry.source.source_id
	data.records.insert(0, other_set_record)
	data.records.append(other_source_record)
	data.emit_changed()
	var destructive_original := data.records.duplicate()
	plugin.request_palette_removal(vegetation_set, vegetation_set.entries[1])
	plugin._remove_dialog.custom_action.emit("all")
	check(plugin._remove_dialog != null and plugin._remove_dialog.ok_button_text.contains("1"), "destructive_separate_explicit_exact_count_confirmation")
	var serial := data.next_stroke_serial
	plugin._remove_dialog.confirmed.emit()
	await frames()
	check(data.records == [other_set_record, other_source_record] and data.next_stroke_serial == serial, "confirmed_delete_scope_other_sets_sources_and_serial_preserved")
	history.undo()
	await frames()
	check(data.records == destructive_original, "destructive_one_native_undo_restores_exact_ID_order")
	history.redo()
	check(data.records == [other_set_record, other_source_record], "destructive_redo")
	history.undo()
	plugin.request_palette_removal(vegetation_set, vegetation_set.entries[1])
	data.records.append(original[1])
	plugin._remove_dialog.confirmed.emit()
	check(vegetation_set.entries.size() == 2 and data.records.size() == 4, "stale_count_confirmation_refused")
	plugin._close_palette_removal()
	plugin.cancel_stroke()
	var file := FileAccess.open("res://.scratch/stage023_editor_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": results, "erase_tick_CPU_usec": erase_tick_CPU_usec, "scope": "native EditorUndoRedoManager + actual rendered viewport pixels; per-tick CPU query and preview, not FPS; physical mouse NOT_RUN"}, "\t"))
	file.close()
	print("FAIL STAGE023_EDITOR_COMPLETE" if failed else "PASS STAGE023_EDITOR_COMPLETE")
	get_tree().quit(1 if failed else 0)
