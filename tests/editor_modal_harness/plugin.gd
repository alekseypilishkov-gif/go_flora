@tool
extends EditorPlugin

var failed := false
var results: Array = []
var context := ""

func _enter_tree() -> void:
	call_deferred("run")

func frames(count: int = 6) -> void:
	for i in count:
		await get_tree().process_frame

func check(ok: bool, id: String) -> void:
	id = context + id
	print(("PASS " if ok else "FAIL ") + "STAGE022_EDITOR " + id)
	results.append({"id": id, "status": "PASS" if ok else "FAIL", "scope": "native editor API, not mouse GUI"})
	failed = failed or not ok

func windows(node: Node, type: String) -> Array[Node]:
	var found: Array[Node] = []
	if node.is_class(type):
		found.append(node)
	for child in node.get_children(true):
		found.append_array(windows(child, type))
	return found

func open_menu(picker: EditorResourcePicker) -> PopupMenu:
	# Test-only discovery of the native picker menu; no product hierarchy patch.
	for button in picker.get_children():
		if button is Button and button.toggle_mode:
			button.pressed.emit()
			await frames(2)
			for menu in windows(picker, "PopupMenu"):
				for index in menu.item_count:
					if menu.get_item_text(index) == "Quick Load...":
						return menu as PopupMenu
	return null

func quick_load(picker: EditorResourcePicker) -> Window:
	var menu := await open_menu(picker)
	check(menu != null, "native_ResourcePicker_menu_found")
	if menu == null:
		return null
	for index in menu.item_count:
		if menu.get_item_text(index) == "Quick Load...":
			var id := menu.get_item_id(index)
			menu.hide()
			menu.id_pressed.emit(id)
			break
	await frames()
	for window in windows(get_tree().root, "Window"):
		if window.get_class() == "EditorQuickOpenDialog":
			return window as Window
	return null

func choose_quick(dialog: Window, path: String) -> void:
	var search: LineEdit
	for edit in windows(dialog, "LineEdit"):
		if edit.placeholder_text == "Search files...":
			search = edit as LineEdit
	check(search != null, "native_search_field")
	if search == null:
		return
	search.text = path.trim_prefix("res://")
	search.text_changed.emit(search.text)
	await frames(10)
	var confirmation := dialog as AcceptDialog
	check(not confirmation.get_ok_button().disabled, "native_search_result_selected_" + path.get_file())
	search.text_submitted.emit(search.text)
	await frames()

func regular_load(picker: EditorResourcePicker) -> EditorFileDialog:
	var menu := await open_menu(picker)
	if menu == null:
		return null
	for index in menu.item_count:
		if menu.get_item_text(index) == "Load...":
			var id := menu.get_item_id(index)
			menu.hide()
			menu.id_pressed.emit(id)
			break
	await frames()
	for window in windows(picker, "EditorFileDialog"):
		if window.visible:
			return window as EditorFileDialog
	return null

func choose_file(dialog: EditorFileDialog, path: String) -> void:
	dialog.current_path = path
	await frames()
	if dialog.file_mode == EditorFileDialog.FILE_MODE_OPEN_FILE:
		# Setting current_path fills the address but does not select a file row.
		# Drive the native list's selection handler, as an actual file click does.
		var selected := false
		for list in windows(dialog, "ItemList"):
			for index in list.item_count:
				if list.get_item_text(index) == path.get_file():
					list.select(index)
					list.item_selected.emit(index)
					selected = true
		check(selected, "native_file_row_selected_" + path.get_file())
		await frames(2)
	check(not dialog.get_ok_button().disabled, "native_file_confirm_enabled_" + path.get_file())
	dialog.get_ok_button().pressed.emit()
	await frames()

func snapshot(layer: VegetationLayer3D) -> String:
	var rows: Array = []
	for r in layer.layer_data.records:
		rows.append([r.record_id, r.source_id, r.set_id, r.seed, str(r.local_transform), str(r.local_normal), r.source_revision])
	return JSON.stringify(rows)

func start(plugin: EditorPlugin, alpha: bool = true) -> ConfirmationDialog:
	plugin._create_source(alpha)
	await frames()
	return plugin._creator as ConfirmationDialog

func picker_for(creator: ConfirmationDialog) -> EditorResourcePicker:
	return creator.find_child("SourceAssetPicker", true, false) as EditorResourcePicker

func cancel_window(window: Window, how: String = "Cancel") -> void:
	var input_window_id := get_tree().root.get_window_id() if window.is_embedded() else window.get_window_id()
	if how == "X":
		window.notification(Window.NOTIFICATION_WM_CLOSE_REQUEST)
	elif how == "Escape":
		window.grab_focus()
		await frames(4)
		var event := InputEventKey.new()
		event.keycode = KEY_ESCAPE
		event.pressed = true
		event.window_id = input_window_id
		Input.parse_input_event(event)
	elif window is ConfirmationDialog:
		window.get_cancel_button().pressed.emit()
	else:
		window.notification(Window.NOTIFICATION_WM_CLOSE_REQUEST)
	await frames()
	if how == "Escape":
		var release := InputEventKey.new()
		release.keycode = KEY_ESCAPE
		release.window_id = input_window_id
		Input.parse_input_event(release)

func capture(name_value: String, window: Window) -> void:
	if DisplayServer.get_name() != "headless" and ProjectSettings.get_setting("go_flora_qa/modal_capture", false):
		await frames()
		RenderingServer.force_draw(false)
		var image := window.get_texture().get_image()
		check(image != null and image.save_png("res://.scratch/" + name_value + ".png") == OK, "GPU_capture_" + name_value)

func test_saved_sources(plugin: EditorPlugin, layer: VegetationLayer3D, before: String) -> void:
	var vegetation_set: GFVegetationSet = plugin.active_set
	var manager := plugin.get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(layer))
	var ids: Dictionary = {}
	var persisted: Array = []
	for path in ["res://fixtures/grass.png", "res://fixtures/flower.png", "res://fixtures/grass.webp", "res://fixtures/atlas.png", "res://fixtures/original_plant.glb", "res://fixtures/static_plant.tscn"]:
		for method in ["Quick Load", "Load"]:
			context = path.get_file() + "/" + method + "/"
			var alpha: bool = path.get_extension() in ["png", "webp"]
			var old_count := vegetation_set.entries.size()
			manager.clear_history(manager.get_object_history_id(layer), false)
			var creator := await start(plugin, alpha)
			check(creator.visible and not creator.exclusive and creator.transient, "creator_editor_owned_nonexclusive")
			var picker := picker_for(creator)
			if method == "Quick Load":
				var quick := await quick_load(picker)
				check(quick != null and quick.visible and quick.exclusive, "native_QuickLoad_exclusive")
				if quick != null:
					if path.ends_with("grass.png"):
						await capture("native_quick_load", quick)
					await choose_quick(quick, path)
			else:
				var load_dialog := await regular_load(picker)
				check(load_dialog != null and load_dialog.exclusive, "native_Load_exclusive")
				if load_dialog != null:
					await choose_file(load_dialog, path)
			check(picker.edited_resource != null and picker.edited_resource.resource_path == path and creator.visible, "native_selection_retained_in_picker_and_draft")
			var source: GFVegetationSource = creator.source
			check(source.display_name == path.get_file().get_basename() and not ids.has(source.source_id) and not source.source_id.is_empty(), "human_name_unique_stable_source_ID")
			ids[source.source_id] = true
			if alpha:
				# Range quantizes from min=0.01 in 0.05 steps, so use on-grid values.
				creator.find_child("width_m", true, false).value = 0.86
				creator.find_child("height_m", true, false).value = 1.36
				creator.find_child("splay_degrees", true, false).value = 12
				creator.find_child("alpha_threshold", true, false).value = 0.65
				if path.ends_with("atlas.png"):
					for field in [["Atlas X", 140], ["Atlas Y", 8], ["Atlas width", 128], ["Atlas height", 128]]:
						creator.find_child(str(field[0]).validate_node_name(), true, false).value = field[1]
				check(source.kind == GFVegetationSource.Kind.ALPHA_CARD and source.alpha_card.texture.resource_path == path and creator._preview.texture is AtlasTexture, "alpha_reference_kind_UV_preview")
			else:
				check(source.kind == GFVegetationSource.Kind.IMPORTED_SCENE and source.asset.resource_path == path and source.resolve().parts.size() == 2, "imported_static_two_parts_kept")
			if path.ends_with("grass.png") and method == "Quick Load":
				await capture("selected_png", creator)
			var saved_id := source.source_id
			creator.get_ok_button().pressed.emit()
			creator.get_ok_button().pressed.emit()
			await frames()
			var save: EditorFileDialog = creator._save
			check(save.visible and save.exclusive and not save.get_ok_button().disabled and not creator.visible and save.get_parent() == creator.get_parent()
				and get_tree().root.get_last_exclusive_window() == save, "Save_Source_single_editor_root_modal_double_click_safe")
			if path.ends_with("grass.png") and method == "Quick Load":
				await capture("native_save_source", save)
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			plugin.mode = 1
			check(plugin._forward_3d_gui_input(null, click) == EditorPlugin.AFTER_GUI_INPUT_STOP and plugin._stroke == null and snapshot(layer) == before, "Save_modal_blocks_background_brush")
			await cancel_window(save)
			check(creator.visible and not creator._saving and source.source_id == saved_id and vegetation_set.entries.size() == old_count and not history.has_undo(), "Save_Cancel_restores_same_draft_no_add_or_undo")
			creator.get_ok_button().pressed.emit()
			await frames()
			var output: String = "res://.scratch/" + path.get_file().validate_filename() + "_" + method.replace(" ", "_") + ".tres"
			await choose_file(save, output)
			check(ResourceLoader.exists(output) and vegetation_set.entries.size() == old_count + 1 and not is_instance_valid(creator) and not is_instance_valid(save), "native_Save_Source_writes_once_cleans_windows_adds_once")
			var loaded := ResourceLoader.load(output, "", ResourceLoader.CACHE_MODE_IGNORE) as GFVegetationSource
			check(loaded != null and loaded.source_id == saved_id and loaded.display_name == path.get_file().get_basename(), "saved_tres_stable_identity")
			if alpha:
				check(loaded.alpha_card.texture.resource_path == path and is_equal_approx(loaded.alpha_card.width_m, 0.86) and is_equal_approx(loaded.alpha_card.height_m, 1.36)
					and is_equal_approx(loaded.alpha_card.splay_degrees, 12) and is_equal_approx(loaded.alpha_card.alpha_threshold, 0.65)
					and (not path.ends_with("atlas.png") or loaded.alpha_card.atlas_region_px == Rect2i(140, 8, 128, 128)), "saved_card_dimensions_threshold_atlas_exact")
			else:
				check(loaded.asset.resource_path == path and loaded.resolve().parts.size() == 2, "saved_import_reference_no_flattening_loss")
			check(snapshot(layer) == before and history.has_undo(), "existing_records_unchanged_single_palette_history")
			history.undo()
			check(vegetation_set.entries.size() == old_count and snapshot(layer) == before and not history.has_undo(), "one_native_Undo_only_palette_add")
			history.redo()
			check(vegetation_set.entries.size() == old_count + 1 and vegetation_set.entries[-1].source.source_id == saved_id and snapshot(layer) == before, "native_Redo_same_source_no_duplicate")
			plugin._add_created_source(source, layer, vegetation_set)
			check(vegetation_set.entries.size() == old_count + 1, "duplicate_callback_not_appended")
			persisted.append({"file": output, "id": saved_id, "asset": path})
	context = ""
	FileAccess.open("res://.scratch/modal_sources_expected.json", FileAccess.WRITE).store_string(JSON.stringify(persisted))

func test_cancel_and_context(plugin: EditorPlugin, layer: VegetationLayer3D, before: String) -> void:
	var vegetation_set: GFVegetationSet = plugin.active_set
	var count := vegetation_set.entries.size()
	for how in ["Cancel", "X", "Escape"]:
		context = "cancel/" + how + "/"
		var creator := await start(plugin)
		var save: EditorFileDialog = creator._save
		await cancel_window(creator, how)
		check(not is_instance_valid(creator) and not is_instance_valid(save) and vegetation_set.entries.size() == count and snapshot(layer) == before, "creator_cleans_draft_and_save_no_add")
		if is_instance_valid(creator):
			creator.close_creator()
			await frames()
	context = "cancel/QuickLoad/"
	var creator := await start(plugin)
	var picker := picker_for(creator)
	var load_dialog := await regular_load(picker)
	await cancel_window(load_dialog)
	check(creator.visible and picker.edited_resource == null, "native_Load_Cancel_keeps_draft")
	var quick := await quick_load(picker)
	await cancel_window(quick)
	check(creator.visible and picker.edited_resource == null and creator.source.alpha_card.texture == null, "native_picker_Cancel_keeps_empty_draft")
	var direct: Button
	for child in picker.get_children():
		if child is Button and child.tooltip_text == "Quick Load":
			direct = child as Button
	check(direct != null, "native_direct_QuickLoad_button_found")
	if direct != null:
		direct.pressed.emit()
		await frames()
		check(quick.visible and creator._native_popup != null and creator._native_popup.get_ref() == quick, "direct_QuickLoad_window_ownership_tracked")
		await choose_quick(quick, "res://fixtures/grass.png")
		check(picker.edited_resource.resource_path == "res://fixtures/grass.png" and creator.visible, "QuickLoad_reopen_selects_correct_file")
	creator.close_creator()
	await frames()
	context = "context/set_switch_with_QuickLoad/"
	creator = await start(plugin)
	quick = await quick_load(picker_for(creator))
	check(creator._native_popup != null and creator._native_popup.get_ref() == quick, "menu_QuickLoad_ownership_tracked")
	plugin._set_picker.item_selected.emit(1)
	await frames()
	check(not is_instance_valid(creator) and not quick.visible and get_tree().root.get_last_exclusive_window() == get_tree().root
		and snapshot(layer) == before, "set_switch_closes_owned_chooser_no_leaked_exclusive")
	plugin._set_picker.item_selected.emit(0)
	context = "context/Save_then_Help/"
	creator = await start(plugin)
	await choose_quick(await quick_load(picker_for(creator)), "res://fixtures/flower.png")
	creator.get_ok_button().pressed.emit()
	await frames()
	var save: EditorFileDialog = creator._save
	plugin._show_help()
	await frames()
	check(not is_instance_valid(creator) and not is_instance_valid(save) and plugin._help_window.visible and plugin._help_window.exclusive, "Help_replaces_creator_Save_with_one_modal")
	plugin._show_source_details()
	await frames()
	check(not is_instance_valid(plugin._help_window) and plugin._source_details.visible and plugin._source_details.exclusive, "diagnostics_replaces_Help_exclusive_retained")
	plugin._show_source_details()
	await frames()
	check(windows(get_tree().root, "AcceptDialog").filter(func(w: Node) -> bool: return w is Window and w.visible and w.exclusive).size() == 1, "repeated_diagnostics_single_visible_modal")
	creator = await start(plugin)
	check(not is_instance_valid(plugin._source_details) and creator.visible, "creator_replaces_diagnostics")
	var foreign := ConfirmationDialog.new()
	get_editor_interface().get_base_control().add_child(foreign)
	foreign.popup_centered()
	await frames()
	creator.close_creator()
	await frames()
	check(foreign.visible and foreign.exclusive, "closing_draft_does_not_close_unrelated_editor_modal")
	foreign.hide()
	foreign.queue_free()
	await frames()
	context = "validation/"
	creator = await start(plugin)
	await choose_quick(await quick_load(picker_for(creator)), "res://fixtures/opaque.png")
	check(creator.get_ok_button().disabled and not creator._info.text.is_empty() and snapshot(layer) == before, "opaque_PNG_actionable_diagnostic_records_retained")
	creator.get_ok_button().pressed.emit()
	await frames()
	check(not creator._save.visible and creator.visible, "invalid_alpha_cannot_open_Save")
	creator.close_creator()
	await frames()
	creator = await start(plugin, false)
	await choose_quick(await quick_load(picker_for(creator)), "res://fixtures/authored_plant.tscn")
	check(creator.source.resolve().status == GFSourceResolution.Status.UNSUPPORTED and creator.source.diagnostic().contains("script")
		and not creator.get_ok_button().disabled, "authored_scene_still_requires_review_source_can_be_saved")
	creator.close_creator()
	await frames()
	check(vegetation_set.entries.size() == count and snapshot(layer) == before, "all_cancel_validation_context_paths_no_placement_or_palette_loss")
	context = ""

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
	var opaque := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	opaque.fill(Color.GREEN)
	opaque.save_png("res://fixtures/opaque.png")
	# These hand-authored fixtures predate UID headers. Native Quick Open indexes
	# saved scene UIDs; save only the disposable copies, never repository fixtures.
	for path in ["res://fixtures/static_plant.tscn", "res://fixtures/authored_plant.tscn"]:
		var packed: PackedScene = load(path)
		ResourceSaver.save(packed, path)
	get_editor_interface().get_resource_filesystem().scan()
	while get_editor_interface().get_resource_filesystem().is_scanning():
		await frames(1)
	await frames()
	plugin._edit(scene.get_node("VegetationLayer"))
	await frames()
	plugin._create_source(true)
	await frames()
	var creator: ConfirmationDialog = plugin._creator
	var picker := creator.find_child("SourceAssetPicker", true, false) as EditorResourcePicker
	print("WINDOW_STATE creator=", creator.get_path(), " exclusive=", creator.exclusive, " transient=", creator.transient, " embedded=", creator.is_embedded())
	var quick := await quick_load(picker)
	print("WINDOW_STATE quick=", quick.get_path() if quick != null else "missing", " visible=", quick.visible if quick != null else false, " exclusive=", quick.exclusive if quick != null else false)
	if ProjectSettings.get_setting("go_flora_qa/modal_repro", false):
		if quick != null:
			quick.hide()
		creator.hide()
		creator.queue_free()
		await frames()
		print("REPRO STAGE022_COMPLETE")
		get_tree().quit(0)
		return
	check(not creator.exclusive and quick != null and quick.visible, "creator_nonexclusive_native_QuickLoad_opens")
	if quick != null:
		await cancel_window(quick)
	creator.close_creator()
	await frames()
	var layer := scene.get_node("VegetationLayer") as VegetationLayer3D
	for index in 2:
		layer.layer_data.records.append(GFPlacement.make_record({"position": Vector3(index * 3, 0, 0), "normal": Vector3.UP}, layer.global_transform,
			layer.layer_data.layer_id, plugin.active_set, plugin.brush, "existing", index, 8, plugin.active_set.entries[index].source.source_id))
	layer.rebuild_now()
	var before := snapshot(layer)
	await test_saved_sources(plugin, layer, before)
	await test_cancel_and_context(plugin, layer, before)
	# Reuse an actually saved PNG source in the existing painter and native history.
	var vegetation_set: GFVegetationSet = plugin.active_set
	var selected_id: String = vegetation_set.entries[2].source.source_id
	plugin._select_palette_source(selected_id)
	var history := plugin.get_undo_redo().get_history_undo_redo(plugin.get_undo_redo().get_object_history_id(layer))
	for mode in [GFStroke.Mode.PAINT, GFStroke.Mode.SINGLE, GFStroke.Mode.ERASE]:
		var stroke := GFStroke.new()
		check(stroke.begin(layer.layer_data, layer.global_transform, vegetation_set, plugin.brush, 8, mode, selected_id), "post_creation_stroke_begin_%d" % mode)
		stroke.feed({"position": Vector3.ZERO, "normal": Vector3.UP}, func(point: Vector3, normal: Vector3) -> Dictionary: return {"position": point, "normal": normal})
		plugin.mode = int(mode) + 1
		plugin._stroke = stroke
		plugin._stroke_layer = layer
		plugin._stroke_transform = layer.global_transform
		plugin.commit_stroke()
		var changed := snapshot(layer)
		history.undo()
		check(snapshot(layer) == before, "post_creation_native_Undo_preserves_original_%d" % mode)
		history.redo()
		check(snapshot(layer) == changed, "post_creation_native_Redo_exact_%d" % mode)
		history.undo()
	get_editor_interface().save_scene_as("res://.scratch/modal_saved.tscn", false)
	check(FileAccess.file_exists("res://.scratch/modal_saved.tscn") and snapshot(layer) == before, "native_editor_save_preserves_original_records")
	FileAccess.open("res://.scratch/modal_records_expected.json", FileAccess.WRITE).store_string(before)
	creator = await start(plugin)
	await choose_quick(await quick_load(picker_for(creator)), "res://fixtures/grass.png")
	creator.get_ok_button().pressed.emit()
	await frames()
	var pending_save: EditorFileDialog = creator._save
	get_editor_interface().set_plugin_enabled("go_flora", false)
	await frames()
	check(not is_instance_valid(creator) and not is_instance_valid(pending_save) and snapshot(layer) == before and get_tree().root.get_last_exclusive_window() == get_tree().root, "disable_with_Save_releases_windows_preserves_records")
	get_editor_interface().set_plugin_enabled("go_flora", true)
	await frames(15)
	var live := get_tree().get_nodes_in_group("go_flora_editor_plugin")
	check(live.size() == 1, "reenable_single_plugin_no_stale_windows")
	if live.size() == 1:
		plugin = live[0]
		plugin._edit(layer)
		creator = await start(plugin)
		var other_scene := Node3D.new()
		other_scene.name = "ModalContextB"
		var other_layer := VegetationLayer3D.new()
		other_layer.name = "VegetationLayer"
		other_layer.layer_data.layer_id = "modal-context-b"
		other_layer.layer_data.sets = layer.layer_data.sets
		other_scene.add_child(other_layer)
		other_layer.owner = other_scene
		var packed := PackedScene.new()
		packed.pack(other_scene)
		ResourceSaver.save(packed, "res://.scratch/modal_context_b.tscn")
		other_scene.free()
		get_editor_interface().open_scene_from_path("res://.scratch/modal_context_b.tscn")
		for i in 300:
			await frames(1)
			if get_editor_interface().get_edited_scene_root().name == "ModalContextB":
				break
		await frames()
		check(not is_instance_valid(creator) and plugin.active_layer != layer and snapshot(layer) == before, "scene_switch_cancels_draft_preserves_scene_A")
	check(windows(get_tree().root, "Window").filter(func(w: Node) -> bool: return w.get_name() == "GOFloraSourceSaveDialog").is_empty(), "no_orphan_Save_windows_at_end")
	FileAccess.open("res://.scratch/modal_results.json", FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	print("NOT_RUN INTERACTIVE_GUI_QA")
	print("FAIL STAGE022_EDITOR_COMPLETE" if failed else "PASS STAGE022_EDITOR_COMPLETE")
	get_tree().quit(int(failed))
