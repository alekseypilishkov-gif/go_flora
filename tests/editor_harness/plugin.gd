@tool
extends EditorPlugin

var failed := false
var results: Array[Dictionary] = []

func _enter_tree() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	print(("PASS " if ok else "FAIL ") + "EDITOR_API " + id)
	results.append({"id": id, "status": "PASS" if ok else "FAIL", "scope": "headless native Editor API, not real GUI"})
	failed = failed or not ok

func wait_scene(name_value: String) -> Node:
	for i in 300:
		var scene := get_editor_interface().get_edited_scene_root()
		if scene != null and str(scene.name) == name_value:
			await get_tree().process_frame
			await get_tree().process_frame
			return scene
		await get_tree().process_frame
	return null

func painter() -> EditorPlugin:
	var plugins := get_tree().get_nodes_in_group("go_flora_editor_plugin")
	return plugins[0] as EditorPlugin if plugins.size() == 1 else null

func plane(point: Vector3, _normal: Vector3) -> Dictionary:
	return {"position": Vector3(point.x, 0, point.z), "normal": Vector3.UP}

func pending(plugin: EditorPlugin, layer: VegetationLayer3D, stroke_mode: GFStroke.Mode = GFStroke.Mode.SINGLE) -> void:
	plugin.active_layer = layer
	plugin.active_set = layer.layer_data.sets[0]
	plugin.mode = int(stroke_mode) + 1
	plugin._stroke_layer = layer
	plugin._stroke_transform = layer.global_transform
	plugin._stroke = GFStroke.new()
	plugin._stroke.begin(layer.layer_data, layer.global_transform, plugin.active_set, plugin.brush, layer.cell_size_m, stroke_mode)
	plugin._stroke.feed({"position": Vector3.ZERO, "normal": Vector3.UP}, plane)
	layer.set_stroke_preview(plugin._stroke.delta.added, {})

func tab_group(node: Node) -> TabContainer:
	while node != null and not node is TabContainer:
		node = node.get_parent()
	return node as TabContainer

func check_dock(plugin: EditorPlugin) -> void:
	var dock: Control = plugin.get("_dock_scroll")
	var scenes := get_editor_interface().get_base_control().find_children("*", "SceneTreeDock", true, false)
	check(scenes.size() == 1 and tab_group(dock) == tab_group(scenes[0]), "dock_shares_Scene_Import_tab_group")
	var group := tab_group(dock)
	if group != null:
		group.current_tab = group.get_tab_idx_from_control(dock.get_parent() if dock.get_parent() != group else dock)
	for i in 10:
		await get_tree().process_frame
	var minimum_before := dock.get_combined_minimum_size().x
	var width_before := dock.size.x
	var editor_before := get_editor_interface().get_base_control().size.x
	var stable := true
	plugin.set_process(false)
	# Exercise dynamic labels and the pending-stroke counter through native controls.
	# This does not inject mouse input or prove interactive GUI acceptance.
	for message in ["Eligible surface", "Pending: 20000 added / 20000 erased · 20000 samples · release to commit, Esc to cancel", "A very long missing source diagnostic ".repeat(12)]:
		plugin.set_status(message)
		plugin._counts.text = "999999 saved records · 999999 cells/batches · pending stroke"
		for i in 6:
			await get_tree().process_frame
		stable = stable and is_equal_approx(dock.get_combined_minimum_size().x, minimum_before) and absf(dock.size.x - width_before) <= 1.0
		print("DOCK_WIDTH ", JSON.stringify({"minimum": dock.get_combined_minimum_size().x, "width": dock.size.x, "status": message}))
	plugin.set_process(true)
	check(stable and minimum_before <= 280.0 and get_editor_interface().get_base_control().size.x == editor_before, "dynamic_status_and_counts_do_not_resize_dock")

func run() -> void:
	var scene_a := await wait_scene("GOFloraDemo")
	var plugin := painter()
	check(scene_a != null and plugin != null, "installed_enabled_actual_addon")
	if scene_a == null or plugin == null:
		get_tree().quit(1)
		return
	var layer_a := scene_a.get_node("VegetationLayer") as VegetationLayer3D
	plugin._edit(layer_a)
	await get_tree().process_frame
	await get_tree().process_frame
	var dock_control: Control = plugin.get("_dock_scroll")
	if dock_control == null:
		dock_control = plugin.get("_dock")
	check(dock_control != null and dock_control.get_combined_minimum_size().y <= 180.0, "dock_minimum_height_fits_editor")
	var filesystem := get_editor_interface().get_file_system_dock()
	var editor_bounds := get_editor_interface().get_base_control().get_global_rect()
	var filesystem_bounds := filesystem.get_global_rect()
	check(filesystem_bounds.position.y >= editor_bounds.position.y and filesystem_bounds.end.y <= editor_bounds.end.y + 1.0,
		"filesystem_dock_stays_inside_editor_vertical_bounds")
	await check_dock(plugin)
	pending(plugin, layer_a)
	check(layer_a.layer_data.records.is_empty(), "pending_no_persistent_mutation")
	plugin.cancel_stroke()
	check(plugin._stroke == null and layer_a.layer_data.records.is_empty(), "cancel_no_undo_action")
	pending(plugin, layer_a)
	plugin._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(plugin._stroke == null and layer_a.layer_data.records.is_empty(), "application_focus_loss_cancels_pending_API_only")
	pending(plugin, layer_a)
	plugin._cancel_unhandled_release()
	check(plugin._stroke == null and layer_a.layer_data.records.is_empty(), "outside_viewport_release_cancels_pending_API_only")
	pending(plugin, layer_a)
	plugin.commit_stroke()
	var manager := plugin.get_undo_redo()
	var history_a_id := manager.get_object_history_id(layer_a)
	var history_a := manager.get_history_undo_redo(history_a_id)
	var record_id: String = layer_a.layer_data.records[0].record_id
	check(layer_a.layer_data.records.size() == 1, "single_commit_exactly_one")
	history_a.undo()
	check(layer_a.layer_data.records.is_empty(), "one_scene_history_undo")
	history_a.redo()
	check(layer_a.layer_data.records.size() == 1 and layer_a.layer_data.records[0].record_id == record_id, "scene_redo_exact_id")
	var set_a: GFVegetationSet = layer_a.layer_data.sets[0]
	var set_b: GFVegetationSet = layer_a.layer_data.sets[1]
	var initial_distance := set_a.draw_distance_m
	var initial_b := set_b.draw_distance_m
	var distance_control := plugin.get("_set_distance") as SpinBox
	check(distance_control != null and distance_control.editable and distance_control.value == initial_distance, "active_set_distance_visible_in_dock")
	if distance_control != null:
		layer_a.rebuild_now()
		await get_tree().process_frame
		var batch_ids := layer_a._cache_root.get_children().map(func(node: Node) -> int: return node.get_instance_id())
		distance_control.value = 23.0
		await get_tree().process_frame
		check(set_a.draw_distance_m == 23.0 and set_b.draw_distance_m == initial_b and layer_a.layer_data.records.size() == 1 and layer_a.layer_data.records[0].record_id == record_id,
			"dock_distance_updates_A_without_record_or_B_changes")
		check(layer_a._cache_root.get_children().map(func(node: Node) -> int: return node.get_instance_id()) == batch_ids,
			"dock_distance_reuses_existing_batches")
		history_a.undo()
		check(set_a.draw_distance_m == initial_distance and distance_control.value == initial_distance and layer_a.layer_data.records.size() == 1, "dock_distance_native_undo_syncs_control")
		history_a.redo()
		check(set_a.draw_distance_m == 23.0 and distance_control.value == 23.0, "dock_distance_native_redo_syncs_control")
		history_a.undo()
		plugin._set_picker.item_selected.emit(1)
		check(plugin.active_set == set_b and distance_control.value == initial_b, "distance_control_tracks_selected_set")
		plugin._set_picker.item_selected.emit(0)
	pending(plugin, layer_a, GFStroke.Mode.PAINT)
	plugin._stroke.feed({"position": Vector3(2, 0, 0), "normal": Vector3.UP}, plane)
	plugin.commit_stroke()
	var painted_ids := layer_a.layer_data.records.map(func(record: GFInstanceRecord) -> String: return record.record_id)
	history_a.undo()
	check(painted_ids.size() > 1 and layer_a.layer_data.records.size() == 1, "multi_sample_paint_one_native_undo_step")
	history_a.redo()
	check(layer_a.layer_data.records.map(func(record: GFInstanceRecord) -> String: return record.record_id) == painted_ids, "native_paint_redo_restores_exact_ID_sequence")
	pending(plugin, layer_a, GFStroke.Mode.ERASE)
	plugin.commit_stroke()
	check(layer_a.layer_data.records.size() < painted_ids.size(), "native_erase_commits_record_delta")
	history_a.undo()
	check(layer_a.layer_data.records.map(func(record: GFInstanceRecord) -> String: return record.record_id) == painted_ids, "native_erase_one_undo_restores_exact_order")
	history_a.undo() # Return scene A to its single placement before isolation checks.
	var scene_b := Node3D.new()
	scene_b.name = "HistoryB"
	var layer_b := VegetationLayer3D.new()
	layer_b.name = "VegetationLayer"
	layer_b.layer_data.layer_id = "history-b"
	layer_b.layer_data.sets = layer_a.layer_data.sets
	scene_b.add_child(layer_b)
	layer_b.owner = scene_b
	var packed := PackedScene.new()
	packed.pack(scene_b)
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	ResourceSaver.save(packed, "res://.scratch/history_b.tscn")
	scene_b.free()
	pending(plugin, layer_a)
	get_editor_interface().open_scene_from_path("res://.scratch/history_b.tscn")
	var active_b := await wait_scene("HistoryB")
	check(active_b != null and plugin._stroke == null and layer_a.layer_data.records.size() == 1, "scene_switch_cancels_pending")
	if active_b == null:
		get_tree().quit(1)
		return
	layer_b = active_b.get_node("VegetationLayer") as VegetationLayer3D
	pending(plugin, layer_b)
	plugin.commit_stroke()
	var history_b_id := manager.get_object_history_id(layer_b)
	check(history_a_id != history_b_id, "distinct_scene_history_ids")
	manager.get_history_undo_redo(history_b_id).undo()
	check(layer_b.layer_data.records.is_empty() and layer_a.layer_data.records.size() == 1, "undo_B_does_not_edit_A")
	manager.get_history_undo_redo(history_b_id).redo()
	get_editor_interface().set_plugin_enabled("go_flora", false)
	await get_tree().process_frame
	check(painter() == null and layer_b.layer_data.records.size() == 1, "disable_preserves_data_removes_editor_state")
	get_editor_interface().set_plugin_enabled("go_flora", true)
	await get_tree().process_frame
	await get_tree().process_frame
	plugin = painter()
	layer_b.rebuild_now()
	check(plugin != null and layer_b.layer_data.records.size() == 1 and layer_b.batch_count() > 0, "reenable_one_plugin_no_parse_errors_data_rendered")
	var output := FileAccess.open("res://.scratch/editor_api_results.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(results, "\t"))
	output.close()
	print("NOT_RUN INTERACTIVE_GUI_QA these Editor API checks do not inject real mouse strokes")
	get_tree().quit(1 if failed else 0)
