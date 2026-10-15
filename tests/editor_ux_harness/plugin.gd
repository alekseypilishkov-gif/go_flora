@tool
extends EditorPlugin

var failed := false
var results: Array = []

func _enter_tree() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	print(("PASS " if ok else "FAIL ") + "STAGE021_EDITOR " + id)
	results.append({"id": id, "status": "PASS" if ok else "FAIL", "scope": "native Editor API; not interactive GUI"})
	failed = failed or not ok

func frames(count: int = 6) -> void:
	for i in count:
		await get_tree().process_frame

func group(node: Node) -> TabContainer:
	while node != null and not node is TabContainer:
		node = node.get_parent()
	return node as TabContainer

func snap(layer: VegetationLayer3D) -> String:
	var rows: Array = []
	for r in layer.layer_data.records:
		rows.append([r.record_id, r.source_id, r.set_id, r.seed, str(r.local_transform)])
	return JSON.stringify(rows)

func plane(point: Vector3, normal: Vector3) -> Dictionary:
	return {"position": point, "normal": normal}

func pending(plugin: EditorPlugin, mode: GFStroke.Mode) -> bool:
	var layer: VegetationLayer3D = plugin.active_layer
	plugin.mode = int(mode) + 1
	plugin._stroke_layer = layer
	plugin._stroke_transform = layer.global_transform
	plugin._stroke = GFStroke.new()
	if not plugin._stroke.begin(layer.layer_data, layer.global_transform, plugin.active_set, plugin.brush, 8, mode,
		plugin.selected_source_id if plugin.source_mode == 1 else ""):
		return false
	plugin._stroke.feed({"position": Vector3.ZERO, "normal": Vector3.UP}, plane)
	layer.set_stroke_preview(plugin._stroke.delta.added, {})
	return true

func help_keys(node: Node) -> Dictionary:
	var keys: Dictionary = {}
	for control in node.find_children("*", "Control", true, false):
		if control.has_meta("go_flora_help_key"):
			var key: String = control.get_meta("go_flora_help_key")
			keys[key] = not control.tooltip_text.is_empty() and control.tooltip_text.contains(" ")
	return keys

func capture(name_value: String) -> void:
	if DisplayServer.get_name() != "headless" and ProjectSettings.get_setting("go_flora_qa/capture", false):
		# Allow asynchronous editor import progress and previews to finish.
		await get_tree().create_timer(2.0).timeout
		# Hidden/offscreen editor windows can stop requesting frames when idle.
		RenderingServer.force_draw(false)
		var image := get_editor_interface().get_base_control().get_viewport().get_texture().get_image()
		check(image != null and image.save_png("res://.scratch/" + name_value + ".png") == OK, "GPU_editor_capture_" + name_value)

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
	check(scene != null and plugin != null, "installed_enabled")
	if plugin == null or scene == null:
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var layer := scene.get_node("VegetationLayer") as VegetationLayer3D
	var set_a := layer.layer_data.sets[0]
	var set_b := layer.layer_data.sets[1]
	for name_value in ["grass", "flower"]:
		var source := GFVegetationSource.new()
		source.source_id = name_value
		source.display_name = name_value
		source.kind = GFVegetationSource.Kind.ALPHA_CARD
		source.alpha_card = GFAlphaCard.new()
		source.alpha_card.texture = load("res://fixtures/grass.png" if name_value == "grass" else "res://fixtures/flower.png")
		var entry := GFPaletteEntry.new()
		entry.source = source
		set_a.entries.append(entry)
	set_a.emit_changed()
	plugin._edit(layer)
	plugin._refresh_sets()
	await frames()
	var dock: Control = plugin._dock_scroll
	var tabs := group(dock)
	check(tabs != null and tabs == group(get_editor_interface().get_inspector()), "fresh_default_right_Inspector_tab_group")
	tabs.current_tab = tabs.get_tab_idx_from_control(dock.get_parent() if dock.get_parent() != tabs else dock)
	await frames()
	var minimum := dock.get_combined_minimum_size()
	var width := dock.size.x
	check(minimum.x <= 280 and minimum.y <= 180, "bounded_minimum_260_by_120")
	var palette: VBoxContainer = plugin._palette
	check(palette.rows.size() == 4 and palette.rows[0].select.text == "Green cone bush" and palette.rows[1].select.text == "Orange block shrub"
		and palette.rows[2].select.text == "grass" and palette.rows[3].select.text == "flower", "four_owner_names_no_GFPaletteEntry_labels")
	check(palette.rows.all(func(row: Dictionary) -> bool: return row.select.tooltip_text.contains("ID:") and row.preview.edited_resource != null), "all_rows_type_ID_tooltip_and_asset_preview")
	await capture("named_dock")
	var manager := plugin.get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(layer))
	history.clear_history()
	var entries := set_a.entries.duplicate()
	var weights := set_a.entries.map(func(e: GFPaletteEntry) -> float: return e.weight)
	for index in 2:
		layer.layer_data.records.append(GFPlacement.make_record({"position": Vector3(index * 3, 0, 0), "normal": Vector3.UP}, layer.global_transform,
			layer.layer_data.layer_id, set_a, plugin.brush, "existing", index, 8, set_a.entries[index].source.source_id))
	layer.rebuild_now()
	var before := snap(layer)
	palette.rows[2].select.pressed.emit()
	check(plugin.selected_source_id == "grass" and plugin.source_mode == 1 and plugin._brush_sources.selected == 1 and not history.has_undo(), "click_grass_transient_selected_mode_no_history")
	for id in ["grass", "flower"]:
		plugin._select_palette_source(id)
		for mode in [GFStroke.Mode.PAINT, GFStroke.Mode.SINGLE]:
			check(pending(plugin, mode), "selected_begin_%s_%d" % [id, mode])
			var ids: Array = plugin._stroke.delta.added.map(func(r: GFInstanceRecord) -> String: return r.source_id)
			plugin.commit_stroke()
			check(not ids.is_empty() and ids.all(func(value: String) -> bool: return value == id) and (mode != GFStroke.Mode.SINGLE or ids.size() == 1), "selected_commit_%s_%d" % [id, mode])
			var painted := snap(layer)
			history.undo()
			check(snap(layer) == before, "selected_one_native_undo_%s_%d" % [id, mode])
			history.redo()
			check(snap(layer) == painted, "selected_native_redo_IDs_%s_%d" % [id, mode])
			history.undo()
	check(entries == set_a.entries and weights == set_a.entries.map(func(e: GFPaletteEntry) -> float: return e.weight), "selection_does_not_rewrite_mix_configuration")
	plugin._brush_sources.item_selected.emit(0)
	check(plugin.source_mode == 0 and plugin.mode == 3, "mix_source_selector_independent_of_Single_tool")
	history.clear_history()
	palette.rows[0].enabled.button_pressed = false
	palette.rows[1].enabled.button_pressed = false
	await frames()
	check(not set_a.entries[0].enabled and not set_a.entries[1].enabled and snap(layer) == before and palette.rows[0].weight.value == weights[0], "disable_two_via_controls_keeps_old_records_weights")
	check(pending(plugin, GFStroke.Mode.PAINT), "filtered_mix_begin")
	check(plugin._stroke.delta.added.all(func(r: GFInstanceRecord) -> bool: return r.source_id in ["grass", "flower"]), "filtered_mix_only_enabled_sources")
	plugin.commit_stroke()
	history.undo()
	history.undo()
	check(set_a.entries[1].enabled and not set_a.entries[0].enabled and snap(layer) == before, "native_undo_enable_flag_scene_history")
	history.redo()
	check(not set_a.entries[1].enabled and snap(layer) == before, "native_redo_enable_flag_records_unchanged")
	await frames()
	palette.rows[2].weight.value = 0
	await frames()
	check(set_a.entries[2].weight == 0 and palette.rows[2].weight.value == 0 and snap(layer) == before, "weight_zero_control_excludes_mix_only")
	history.undo()
	await frames()
	check(set_a.entries[2].weight == weights[2] and palette.rows[2].weight.value == weights[2], "weight_native_undo_refreshes_row")
	for row in palette.rows:
		row.enabled.button_pressed = false
	await frames()
	check(not plugin.brush_source_diagnostic().is_empty() and plugin._status.text.contains("MIX:"), "noeligible_mix_visible_actionable_diagnostic")
	check(pending(plugin, GFStroke.Mode.ERASE), "erase_available_with_all_sources_disabled")
	plugin.cancel_stroke()
	plugin._select_palette_source("grass")
	check(not plugin.brush_source_diagnostic().is_empty(), "disabled_selected_visible_diagnostic")
	for e in set_a.entries:
		e.enabled = true
	set_a.entries[0].source.display_name = "Очень длинное имя источника ".repeat(25)
	plugin.set_status("Длинная диагностика ".repeat(30))
	await frames()
	check(palette.rows[0].select.text.begins_with("Очень длинное") and is_equal_approx(dock.get_combined_minimum_size().x, minimum.x) and absf(dock.size.x - width) <= 1, "resource_rename_refresh_and_long_text_stable_width")
	set_a.entries[0].source.display_name = "Green cone bush"
	var initial_entries := set_a.entries.duplicate()
	for index in 20:
		var extra := GFPaletteEntry.new()
		extra.source = set_a.entries[0].source.duplicate()
		extra.source.source_id = "many-%d" % index
		extra.source.display_name = "Длинное название растения ".repeat(10)
		set_a.entries.append(extra)
	set_a.emit_changed()
	await frames()
	check(palette.rows.size() == 24 and dock.get_combined_minimum_size() == minimum and absf(dock.size.x - width) <= 1, "many_sources_scroll_without_resizing_dock")
	set_a.entries = initial_entries
	await frames()
	var open_button := plugin._dock.find_child("OpenSetInInspector", true, false) as Button
	open_button.pressed.emit()
	await frames(15)
	var inspector := get_editor_interface().get_inspector()
	check(inspector.get_edited_object() == set_a and inspector.is_visible_in_tree(), "OpenSet_official_API_focuses_visible_Inspector_from_GOFLORA_tab")
	await capture("named_Inspector")
	var set_help := inspector.find_child("SetSettingsHelp", true, false) as Button
	check(set_help != null and set_help.tooltip_text.contains("Множитель") and set_help.tooltip_text.contains("Density Multiplier:") and set_help.tooltip_text.contains("Draw Distance:") and set_help.tooltip_text.contains("0 ="), "Russian_set_Enabled_Density_Distance_click_help")
	var properties := get_tree().get_nodes_in_group("go_flora_palette_properties")
	check(properties.size() == 1 and properties[0].palette.rows.size() == 4, "official_EditorInspectorPlugin_one_named_entries_property")
	if properties.size() == 1:
		var property: EditorProperty = properties[0]
		check(property.palette.rows[2].select.text == "grass" and property.palette.rows[2].reference.base_type == "GFVegetationSource", "Inspector_names_and_native_reusable_source_picker")
		property.palette.rows[2].weight.value = 2.5
		await frames()
		check(set_a.entries[2].weight == 2.5 and plugin._palette.rows[2].weight.value == 2.5, "Inspector_weight_edits_sync_dock")
		history.undo()
		await frames()
		check(set_a.entries[2].weight == weights[2] and property.palette.rows[2].weight.value == weights[2], "Inspector_weight_native_undo_sync_both_views")
		var old_source := set_a.entries[2].source
		var version := history.get_version()
		property.palette.rows[2].reference.resource_changed.emit(set_b.entries[0].source)
		check(set_a.entries[2].source == old_source and snap(layer) == before, "Inspector_duplicate_reference_refused_keeps_records")
		check(history.get_version() == version, "Inspector_duplicate_reference_no_undo_action")
		var add := property.find_child("AddExistingSource", true, false) as EditorResourcePicker
		add.resource_changed.emit(set_b.entries[0].source)
		check(set_a.entries.size() == 4 and snap(layer) == before, "Inspector_append_active_duplicate_refused")
		check(history.get_version() == version, "Inspector_append_duplicate_no_undo_action")
	check(set_a.entries.all(func(e: GFPaletteEntry) -> bool: return e.resource_name.is_empty()), "no_resource_name_persistence_hack")
	plugin._set_picker.item_selected.emit(1)
	plugin._open_set_in_inspector()
	await frames()
	check(plugin.active_set == set_b and inspector.get_edited_object() == set_b, "set_switch_OpenSet_uses_current_set")
	get_editor_interface().get_selection().clear()
	get_editor_interface().get_selection().add_node(scene.get_node("Ground"))
	await frames()
	plugin._open_set_in_inspector()
	await frames()
	check(inspector.get_edited_object() == set_b, "other_node_selection_OpenSet_keeps_active_set")
	plugin._set_picker.item_selected.emit(0)
	await frames()
	check(plugin.selected_source_id == "grass" and plugin._palette.rows.size() == 4, "return_set_restores_transient_selection_no_stale_rows")
	var keys := help_keys(plugin._dock)
	for key in ["layer", "set", "refresh", "mix", "entry_enabled", "weight", "inspect_set", "Paint", "Erase", "Single", "radius_m", "density_per_m2", "spacing_ratio", "seed", "yaw_min_degrees", "yaw_max_degrees", "scale_min", "scale_max", "align_normal", "slope_min_degrees", "slope_max_degrees", "height_min_m", "height_max_m", "height_layer_relative", "collision_mask", "ray_range_m", "max_candidates", "distance", "target", "help"]:
		check(keys.get(key, false), "Russian_tooltip_" + key)
	plugin._show_help()
	check(plugin._help_window.visible and plugin._help_window.find_children("*", "TextEdit", true, false)[0].text.contains("MIX"), "click_Help_opens_Russian_legend")
	plugin._help_window.hide()
	plugin._help_window.queue_free()
	await frames()
	plugin._create_source(true)
	var creator: ConfirmationDialog = plugin._creator
	keys = help_keys(creator)
	for key in ["texture", "card_mode", "width_m", "height_m", "radial_count", "splay_degrees", "alpha_threshold", "gutter_px", "Atlas X", "Atlas Y", "Atlas width", "Atlas height"]:
		check(keys.get(key, false), "Russian_Alpha_tooltip_" + key)
	check(not creator.get_ok_button().tooltip_text.is_empty(), "Russian_Alpha_save_tooltip")
	creator.hide()
	creator.queue_free()
	await frames()
	# Save through real EditorInterface; separate core process verifies persistence as well.
	get_editor_interface().save_scene_as("res://.scratch/ux_editor_saved.tscn", false)
	check(FileAccess.file_exists("res://.scratch/ux_editor_saved.tscn") and snap(layer) == before, "native_editor_save_no_record_changes")
	get_editor_interface().set_plugin_enabled("go_flora", false)
	await frames()
	check(get_tree().get_nodes_in_group("go_flora_editor_plugin").is_empty(), "plugin_disable_removes_dock_and_observers")
	get_editor_interface().set_plugin_enabled("go_flora", true)
	await frames(20)
	var live := get_tree().get_nodes_in_group("go_flora_editor_plugin")
	check(live.size() == 1, "plugin_reenable_single_instance")
	if live.size() == 1:
		live[0]._edit(layer)
		live[0]._open_set_in_inspector()
		await frames(15)
		check(get_tree().get_nodes_in_group("go_flora_palette_properties").size() == 1 and live[0]._palette.rows.size() == 4, "reenable_single_Inspector_palette_no_stale_callbacks")
		var next_scene := Node3D.new()
		next_scene.name = "PaletteSceneB"
		var next_layer := VegetationLayer3D.new()
		next_layer.name = "VegetationLayer"
		next_layer.layer_data.layer_id = "ux-scene-b"
		var next_set := GFVegetationSet.new()
		next_set.set_id = "ux-set-b"
		next_set.display_name = "Сцена B"
		next_set.entries = set_b.entries.duplicate()
		next_layer.layer_data.sets.assign([next_set])
		next_scene.add_child(next_layer)
		next_layer.owner = next_scene
		var packed := PackedScene.new()
		packed.pack(next_scene)
		ResourceSaver.save(packed, "res://.scratch/ux_scene_b.tscn")
		next_scene.free()
		get_editor_interface().open_scene_from_path("res://.scratch/ux_scene_b.tscn")
		for i in 300:
			await frames(1)
			if get_editor_interface().get_edited_scene_root().name == "PaletteSceneB":
				break
		await frames()
		live[0]._open_set_in_inspector()
		await frames()
		check(live[0].active_set.set_id == "ux-set-b" and inspector.get_edited_object() == live[0].active_set and live[0].selected_source_id.is_empty()
			and snap(layer) == before, "scene_switch_OpenSet_new_resource_resets_selection_preserves_scene_A")
	FileAccess.open("res://.scratch/ux_editor_results.json", FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	print("NOT_RUN INTERACTIVE_GUI_QA")
	print("FAIL STAGE021_EDITOR_COMPLETE" if failed else "PASS STAGE021_EDITOR_COMPLETE")
	get_tree().quit(int(failed))
