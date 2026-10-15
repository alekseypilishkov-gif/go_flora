@tool
extends EditorPlugin

enum Tool { NAVIGATION, PAINT, ERASE, SINGLE }
var active_layer: VegetationLayer3D
var active_set: GFVegetationSet
var brush := GFBrush.new()
var mode: Tool = Tool.NAVIGATION
var _dock: VBoxContainer
var _dock_scroll: ScrollContainer
var _layer_picker: OptionButton
var _set_picker: OptionButton
var _set_distance: SpinBox
var _observed_set: GFVegetationSet
var _status: Label
var _sources: Label
var _source_previews: HFlowContainer
var _counts: Label
var _preview: GFBrushPreview
var _layers: Array[VegetationLayer3D] = []
var _stroke: GFStroke
var _stroke_layer: VegetationLayer3D
var _stroke_transform: Transform3D
var _scene_root: Node
var _ui_updating := false
var _last_hit: Dictionary = {}
var _creator: ConfirmationDialog
var _source_details: AcceptDialog

func _enter_tree() -> void:
	add_to_group("go_flora_editor_plugin")
	set_input_event_forwarding_always_enabled()
	set_process_input(true)
	scene_changed.connect(_on_scene_changed)
	scene_closed.connect(_on_scene_closed)
	get_editor_interface().get_resource_filesystem().resources_reimported.connect(_resources_reimported)
	_build_dock()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, _dock_scroll)
	call_deferred("_on_scene_changed", get_editor_interface().get_edited_scene_root())
	set_process(true)
	print("GO_FLORA_PLUGIN_ENABLED")

func _exit_tree() -> void:
	cancel_stroke()
	_remove_preview()
	_observe_set(null)
	if is_instance_valid(_creator):
		_creator.queue_free()
	if is_instance_valid(_source_details):
		_source_details.queue_free()
	if is_instance_valid(_dock_scroll):
		remove_control_from_docks(_dock_scroll)
		_dock_scroll.queue_free()

func _handles(object: Object) -> bool:
	return object is VegetationLayer3D

func _edit(object: Object) -> void:
	if object is VegetationLayer3D and object != active_layer:
		cancel_stroke()
		active_layer = object
		_refresh_layers()

func _input(event: InputEvent) -> void:
	if _stroke != null and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_stroke()
		set_status("Stroke cancelled; saved records unchanged.")
		get_viewport().set_input_as_handled()
	elif _stroke != null and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		# The viewport callback commits a valid release first. A release outside it
		# leaves pending work, which must be discarded instead of hanging around.
		call_deferred("_cancel_unhandled_release")

func _cancel_unhandled_release() -> void:
	if _stroke != null:
		cancel_stroke()
		set_status("Stroke cancelled after release outside the 3D viewport.")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_stroke()

func _process(_delta: float) -> void:
	if _stroke != null and (not is_instance_valid(_stroke_layer) or _stroke_layer != active_layer or _stroke_layer.global_transform != _stroke_transform or _stroke_layer.layer_data != _stroke._data):
		cancel_stroke()
	if active_layer != null and not is_instance_valid(active_layer):
		active_layer = null
		active_set = null
	if is_instance_valid(active_layer) and active_layer.layer_data != null:
		_counts.text = "Saved records: %d%s\nCells / batches: %d" % [active_layer.layer_data.records.size(), " (pending stroke)" if _stroke != null else "", active_layer.batch_count()]
		var reasons := active_layer.render_diagnostics
		if not reasons.is_empty() and _stroke == null:
			set_status(reasons[0])

func set_status(message: String) -> void:
	if is_instance_valid(_status):
		_status.text = message

func _on_scene_changed(root: Node) -> void:
	cancel_stroke()
	_remove_preview()
	_scene_root = root
	active_layer = null
	active_set = null
	_refresh_layers()

func _on_scene_closed(_path: String) -> void:
	cancel_stroke()
	_remove_preview()

func _walk_layers(node: Node) -> void:
	if node is VegetationLayer3D:
		_layers.append(node)
	for child in node.get_children():
		_walk_layers(child)

func _refresh_layers() -> void:
	cancel_stroke()
	_layers.clear()
	if is_instance_valid(_scene_root):
		_walk_layers(_scene_root)
	_ui_updating = true
	_layer_picker.clear()
	for layer in _layers:
		_layer_picker.add_item(str(layer.name))
	if not _layers.has(active_layer):
		active_layer = _layers[0] if not _layers.is_empty() else null
	if active_layer != null:
		_layer_picker.select(_layers.find(active_layer))
	_ui_updating = false
	_refresh_sets()
	set_status("Choose a set and a tool. Navigation mode passes editor input through." if active_layer != null else "Add/select a VegetationLayer3D with data and sets, then Refresh Layers.")

func _refresh_sets() -> void:
	_ui_updating = true
	_set_picker.clear()
	if is_instance_valid(active_layer) and active_layer.layer_data != null:
		for vegetation_set in active_layer.layer_data.sets:
			_set_picker.add_item(vegetation_set.display_name if vegetation_set != null else "Missing set")
		if not active_layer.layer_data.sets.has(active_set):
			active_set = active_layer.layer_data.sets[0] if not active_layer.layer_data.sets.is_empty() else null
		if active_set != null:
			_set_picker.select(active_layer.layer_data.sets.find(active_set))
	else:
		active_set = null
	_ui_updating = false
	_observe_set(active_set)
	var names: PackedStringArray = []
	if active_set != null:
		for entry in active_set.entries:
			if entry != null and entry.source != null:
				names.append("%s (weight %s)" % [entry.source.display_name, entry.weight])
	_sources.text = "Sources: " + ", ".join(names)
	for child in _source_previews.get_children():
		child.queue_free()
	if active_set != null:
		for entry in active_set.entries:
			if entry != null and entry.source != null:
				var picker := EditorResourcePicker.new()
				picker.base_type = "Resource"
				picker.edited_resource = entry.source.alpha_card.texture if entry.source.alpha_card != null else entry.source.asset
				picker.editable = false
				picker.custom_minimum_size = Vector2(96, 64)
				picker.tooltip_text = entry.source.display_name
				picker.resource_selected.connect(func(_resource: Resource, _inspect: bool) -> void:
					get_editor_interface().edit_resource(entry.source))
				_source_previews.add_child(picker)

func _build_dock() -> void:
	# Limit the whole dock's minimum height, including wrapped labels/previews.
	# A scrollbar around only the numeric fields still lets other children push
	# Godot's shared dock splits far below the visible editor window.
	_dock_scroll = ScrollContainer.new()
	_dock_scroll.name = "GO_FLORA"
	_dock_scroll.custom_minimum_size = Vector2(260, 120)
	# Isolate both minimum-size axes: changing status/counts/source names must
	# never resize the editor splits. Horizontal scrolling is a narrow-dock fallback.
	_dock_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_dock_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	_dock = VBoxContainer.new()
	_dock.name = "Content"
	_dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dock_scroll.add_child(_dock)
	var title := Label.new()
	title.text = "GO_FLORA · Vegetation painter"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(title)
	_layer_picker = OptionButton.new()
	_layer_picker.fit_to_longest_item = false
	_layer_picker.clip_text = true
	_layer_picker.tooltip_text = "Active authored VegetationLayer3D"
	_dock.add_child(_layer_picker)
	_layer_picker.item_selected.connect(func(index: int) -> void:
		if not _ui_updating:
			cancel_stroke()
			_remove_preview()
			active_layer = _layers[index]
			_refresh_sets())
	var refresh := Button.new()
	refresh.text = "Refresh Layers / Sets"
	refresh.pressed.connect(_refresh_layers)
	_dock.add_child(refresh)
	_set_picker = OptionButton.new()
	_set_picker.fit_to_longest_item = false
	_set_picker.clip_text = true
	_set_picker.tooltip_text = "Paint/erase affects this set only"
	_dock.add_child(_set_picker)
	_set_picker.item_selected.connect(func(index: int) -> void:
		if not _ui_updating:
			cancel_stroke()
			active_set = active_layer.layer_data.sets[index]
			_refresh_sets())
	var distance_label := Label.new()
	distance_label.text = "Draw distance (m)"
	_dock.add_child(distance_label)
	_set_distance = SpinBox.new()
	_set_distance.name = "SetDrawDistance"
	_set_distance.min_value = 0.0
	_set_distance.max_value = 10000.0
	_set_distance.allow_greater = true
	_set_distance.step = 1.0
	_set_distance.tooltip_text = "Active set only. 0 = unlimited; existing cells update without repaint."
	_set_distance.value_changed.connect(_set_distance_changed)
	_dock.add_child(_set_distance)
	var distance_help := Label.new()
	distance_help.text = "0 = unlimited · applies to this set"
	distance_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(distance_help)
	var edit_set := Button.new()
	edit_set.text = "Edit Set in Inspector"
	edit_set.clip_text = true
	edit_set.tooltip_text = "Edit the active set's palette, enabled state and density in Inspector."
	edit_set.pressed.connect(func() -> void:
		if active_set != null:
			get_editor_interface().edit_resource(active_set))
	_dock.add_child(edit_set)
	_sources = Label.new()
	_sources.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(_sources)
	_source_previews = HFlowContainer.new()
	_dock.add_child(_source_previews)
	for action in [["Add Mesh / GLB / Scene…", false], ["Create Alpha Plant…", true]]:
		var button := Button.new()
		button.text = action[0]
		button.clip_text = true
		button.pressed.connect(_create_source.bind(action[1]))
		_dock.add_child(button)
	var details := Button.new()
	details.text = "Source diagnostics / revision…"
	details.clip_text = true
	details.pressed.connect(_show_source_details)
	_dock.add_child(details)
	var tools := GridContainer.new()
	tools.columns = 2
	var group := ButtonGroup.new()
	for i in 4:
		var button := Button.new()
		button.text = ["Navigate", "Paint", "Erase", "Single"][i]
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = i == 0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_choose_tool.bind(i))
		tools.add_child(button)
	_dock.add_child(tools)
	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dock.add_child(fields)
	for field in [
		["Radius (m)", "radius_m", 0.05, 100.0, 0.05],
		["Density / m²", "density_per_m2", 0.0, 10000.0, 0.5],
		["Spacing / radius", "spacing_ratio", 0.1, 2.0, 0.05],
		["Seed", "seed", 0.0, 2147483647.0, 1.0],
		["Yaw min (°)", "yaw_min_degrees", -360.0, 360.0, 1.0],
		["Yaw max (°)", "yaw_max_degrees", -360.0, 360.0, 1.0],
		["Scale min", "scale_min", 0.01, 100.0, 0.05],
		["Scale max", "scale_max", 0.01, 100.0, 0.05],
		["Normal alignment", "align_normal", 0.0, 1.0, 0.1],
		["Slope min (°)", "slope_min_degrees", 0.0, 180.0, 1.0],
		["Slope max (°)", "slope_max_degrees", 0.0, 180.0, 1.0],
		["Height min (m)", "height_min_m", -10000.0, 10000.0, 1.0],
		["Height max (m)", "height_max_m", -10000.0, 10000.0, 1.0],
		["Collision mask", "collision_mask", 1.0, 4294967295.0, 1.0],
		["Ray range (m)", "ray_range_m", 0.1, 10000.0, 1.0],
		["Stroke work budget", "max_candidates", 1.0, 20000.0, 100.0]]:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = field[0]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var spin := SpinBox.new()
		spin.min_value = field[2]
		spin.max_value = field[3]
		spin.step = field[4]
		spin.value = brush.get(field[1])
		spin.custom_minimum_size.x = 105
		spin.value_changed.connect(_brush_value_changed.bind(field[1]))
		row.add_child(spin)
		fields.add_child(row)
	var height_space := CheckBox.new()
	height_space.text = "Height relative to active layer"
	height_space.clip_text = true
	height_space.tooltip_text = height_space.text
	height_space.toggled.connect(func(value: bool) -> void:
		cancel_stroke()
		brush.height_layer_relative = value)
	fields.add_child(height_space)
	for option in ["Only selected collision target", "Exclude selected collision target", "Clear target restrictions"]:
		var button := Button.new()
		button.text = option
		button.clip_text = true
		button.tooltip_text = option
		button.pressed.connect(_target_restriction.bind(option))
		fields.add_child(button)
	_counts = Label.new()
	_counts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(_counts)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(_status)
	var help := Label.new()
	help.text = "LMB drag: stroke · LMB click: Single\nEsc: cancel · RMB/MMB/Alt/Ctrl: navigation\nDistance = cell visibility; 0 = unlimited; fade off"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(help)

func _show_source_details() -> void:
	if active_set == null or active_set.entries.is_empty():
		set_status("Choose a set containing source entries.")
		return
	if is_instance_valid(_creator):
		_creator.hide()
		_creator.queue_free()
	if is_instance_valid(_source_details):
		_source_details.hide()
		_source_details.queue_free()
	_source_details = AcceptDialog.new()
	_source_details.title = "Source diagnostics / review revision"
	var fields := VBoxContainer.new()
	fields.custom_minimum_size = Vector2(560, 360)
	_source_details.add_child(fields)
	var picker := OptionButton.new()
	picker.fit_to_longest_item = false
	var sources: Array[GFVegetationSource] = []
	for entry in active_set.entries:
		if entry != null and entry.source != null:
			sources.append(entry.source)
			picker.add_item(entry.source.display_name)
	fields.add_child(picker)
	var text := TextEdit.new()
	text.editable = false
	text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fields.add_child(text)
	var refresh := func(_index: int = 0) -> void:
		if sources.is_empty():
			return
		var result := sources[picker.selected].resolve()
		text.text = "Status: %s\nProvider: %s\nRevision: %s\nCapabilities: %s\nReferences: %s\n\n%s" % [GFSourceResolution.Status.keys()[result.status], result.provider,
			result.revision, JSON.stringify(result.capabilities), str(result.references), "\n".join(result.diagnostics)]
	picker.item_selected.connect(refresh)
	var copy := Button.new()
	copy.text = "Copy revision for reviewed fallback"
	copy.pressed.connect(func() -> void:
		if not sources.is_empty():
			DisplayServer.clipboard_set(sources[picker.selected].resolve().revision))
	fields.add_child(copy)
	var inspect := Button.new()
	inspect.text = "Edit selected Source in Inspector"
	inspect.pressed.connect(func() -> void:
		if not sources.is_empty():
			get_editor_interface().edit_resource(sources[picker.selected]))
	fields.add_child(inspect)
	get_editor_interface().get_base_control().add_child(_source_details)
	_source_details.confirmed.connect(_source_details.queue_free)
	_source_details.canceled.connect(_source_details.queue_free)
	refresh.call()
	_source_details.popup_centered()

func _create_source(alpha: bool) -> void:
	if active_set == null or not is_instance_valid(active_layer):
		set_status("Select a layer and set first. Use Edit Set in Inspector to create a set if needed.")
		return
	cancel_stroke()
	if is_instance_valid(_source_details):
		_source_details.hide()
		_source_details.queue_free()
	if is_instance_valid(_creator):
		_creator.hide()
		_creator.queue_free()
	_creator = preload("res://addons/go_flora/editor/source_creator.gd").new()
	get_editor_interface().get_base_control().add_child(_creator)
	_creator.setup(alpha)
	_creator.source_saved.connect(_add_created_source.bind(active_layer, active_set))
	_creator.popup_centered()

func _add_created_source(source: GFVegetationSource, layer: VegetationLayer3D, vegetation_set: GFVegetationSet) -> void:
	get_editor_interface().get_resource_filesystem().scan()
	if not is_instance_valid(layer) or layer != active_layer or vegetation_set != active_set:
		set_status("Source saved. Scene/set changed; add the .tres through the Set Inspector.")
		return
	var entry := GFPaletteEntry.new()
	entry.source = source
	var entries := vegetation_set.entries.duplicate()
	entries.append(entry)
	var history := get_undo_redo()
	history.create_action("GO_FLORA Add plant source", UndoRedo.MERGE_DISABLE, layer)
	history.add_do_property(vegetation_set, "entries", entries)
	history.add_undo_property(vegetation_set, "entries", vegetation_set.entries.duplicate())
	history.add_do_method(self, "_refresh_sets")
	history.add_undo_method(self, "_refresh_sets")
	history.commit_action()
	get_editor_interface().edit_resource(source)
	set_status("Source saved and added. Edit weight in Set Inspector; Paint / Single are ready.")

func _resources_reimported(paths: PackedStringArray) -> void:
	cancel_stroke()
	for layer in _layers:
		if not is_instance_valid(layer) or layer.layer_data == null:
			continue
		for vegetation_set in layer.layer_data.sets:
			if vegetation_set == null:
				continue
			for entry in vegetation_set.entries:
				if entry == null or entry.source == null:
					continue
				var source := entry.source
				if source.asset != null and source.asset.resource_path in paths:
					source.asset = ResourceLoader.load(source.asset.resource_path, "", ResourceLoader.CACHE_MODE_REPLACE)
				if source.alpha_card != null and source.alpha_card.texture != null and source.alpha_card.texture.resource_path in paths:
					source.alpha_card.texture = ResourceLoader.load(source.alpha_card.texture.resource_path, "", ResourceLoader.CACHE_MODE_REPLACE) as Texture2D
		layer.request_rebuild()

func _observe_set(vegetation_set: GFVegetationSet) -> void:
	if _observed_set != null and _observed_set.changed.is_connected(_sync_set_distance):
		_observed_set.changed.disconnect(_sync_set_distance)
	_observed_set = vegetation_set
	if _observed_set != null:
		_observed_set.changed.connect(_sync_set_distance)
	_sync_set_distance()

func _sync_set_distance() -> void:
	if is_instance_valid(_set_distance):
		_set_distance.editable = _observed_set != null
		_set_distance.set_value_no_signal(_observed_set.draw_distance_m if _observed_set != null else 0.0)

func _set_distance_changed(value: float) -> void:
	if _ui_updating or active_set == null or not is_instance_valid(active_layer) or active_set.draw_distance_m == value:
		return
	cancel_stroke()
	var history := get_undo_redo()
	history.create_action("GO_FLORA Set draw distance", UndoRedo.MERGE_DISABLE, active_layer)
	history.add_do_property(active_set, "draw_distance_m", value)
	history.add_undo_property(active_set, "draw_distance_m", active_set.draw_distance_m)
	history.commit_action()

func _choose_tool(value: int) -> void:
	cancel_stroke()
	mode = value as Tool
	if is_instance_valid(_preview):
		_preview.visible = false
	set_status("Navigation: editor input passes through." if mode == Tool.NAVIGATION else "Hover a collision-backed surface. Esc cancels a pending stroke.")

func _brush_value_changed(value: float, property: String) -> void:
	cancel_stroke()
	brush.set(property, int(value) if property in ["seed", "collision_mask", "max_candidates"] else value)

func _target_restriction(option: String) -> void:
	cancel_stroke()
	if option == "Clear target restrictions":
		brush.include_target = NodePath()
		brush.exclude_target = NodePath()
		set_status("All eligible collision-backed targets.")
		return
	var nodes := get_editor_interface().get_selection().get_selected_nodes()
	if nodes.size() != 1:
		set_status("Select exactly one collider (or its parent) in the Scene tree.")
		return
	var selected: Node = nodes[0]
	while selected != null and not selected is CollisionObject3D:
		selected = selected.get_parent()
	if selected == null or _scene_root == null:
		set_status("Selection has no CollisionObject3D ancestor.")
		return
	var path := _scene_root.get_path_to(selected)
	if option.begins_with("Only"):
		brush.include_target = path
	else:
		brush.exclude_target = path
	set_status(option + ": " + str(path))

func _remove_preview() -> void:
	if is_instance_valid(_preview):
		_preview.queue_free()
	_preview = null

func _ensure_preview() -> void:
	if not is_instance_valid(_preview):
		_preview = GFBrushPreview.new()
		_preview.name = "_GO_FLORA_BrushPreview"
		active_layer.add_child(_preview, false, Node.INTERNAL_MODE_FRONT)
		_preview.top_level = true

func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	if not is_instance_valid(active_layer) or active_set == null or mode == Tool.NAVIGATION or not is_instance_valid(_scene_root):
		return AFTER_GUI_INPUT_PASS
	if not _scene_root.is_ancestor_of(active_layer) and _scene_root != active_layer:
		cancel_stroke()
		return AFTER_GUI_INPUT_PASS
	if event is InputEventKey:
		if event.pressed and (event.ctrl_pressed or event.alt_pressed):
			cancel_stroke()
		return AFTER_GUI_INPUT_PASS
	if not event is InputEventMouse:
		return AFTER_GUI_INPUT_PASS
	if event.alt_pressed or event.ctrl_pressed or (event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT):
		cancel_stroke()
		if is_instance_valid(_preview):
			_preview.visible = false
		return AFTER_GUI_INPUT_PASS
	if event is InputEventMouseMotion and (event.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)) != 0:
		cancel_stroke()
		return AFTER_GUI_INPUT_PASS
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _stroke != null:
		commit_stroke()
		return AFTER_GUI_INPUT_STOP
	var reason := active_layer.editing_diagnostic()
	if reason.is_empty():
		reason = brush.diagnostic()
	if not reason.is_empty():
		set_status(reason)
		return AFTER_GUI_INPUT_PASS
	_last_hit = GFSurfaceTarget.from_camera(camera, event.position, brush, active_layer, _scene_root)
	if _last_hit.is_empty():
		if is_instance_valid(_preview):
			_preview.visible = false
		if _stroke != null:
			_stroke.break_path()
		set_status("No eligible collision surface: check collision, mask, slope/height and target restrictions.")
		return AFTER_GUI_INPUT_STOP if _stroke != null else AFTER_GUI_INPUT_PASS
	_ensure_preview()
	_preview.show_hit(_last_hit, brush.radius_m, mode == Tool.ERASE)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_stroke = GFStroke.new()
		var stroke_mode := [GFStroke.Mode.PAINT, GFStroke.Mode.ERASE, GFStroke.Mode.SINGLE][mode - 1] as GFStroke.Mode
		if not _stroke.begin(active_layer.layer_data, active_layer.global_transform, active_set, brush, active_layer.cell_size_m, stroke_mode):
			set_status(_stroke.diagnostic)
			_stroke = null
			return AFTER_GUI_INPUT_PASS
		_stroke_layer = active_layer
		_stroke_transform = active_layer.global_transform
		_feed_stroke(camera)
		return AFTER_GUI_INPUT_STOP
	if event is InputEventMouseMotion and _stroke != null:
		_feed_stroke(camera)
		return AFTER_GUI_INPUT_STOP
	set_status("Eligible surface · %s · %.1f m radius" % [active_set.display_name, brush.radius_m])
	return AFTER_GUI_INPUT_PASS

func _feed_stroke(camera: Camera3D) -> void:
	var resolver := GFSurfaceTarget.project_sample.bind(camera.get_world_3d(), brush, active_layer, _scene_root)
	_stroke.feed(_last_hit, resolver)
	active_layer.set_stroke_preview(_stroke.delta.added, _stroke.preview_removed_ids())
	set_status("Pending: %d added / %d erased · %d samples%s" % [_stroke.delta.added.size(), _stroke.preview_removed_ids().size(), _stroke.candidates_used,
		" · work budget reached; release to commit" if _stroke.budget_exhausted else " · release to commit, Esc to cancel"])

func cancel_stroke() -> void:
	var was_pending := _stroke != null
	if is_instance_valid(_stroke_layer):
		_stroke_layer.cancel_stroke_preview()
	_stroke = null
	_stroke_layer = null
	if was_pending:
		print("GO_FLORA_PENDING_CLEARED")

func commit_stroke() -> void:
	if _stroke == null or not is_instance_valid(_stroke_layer):
		cancel_stroke()
		return
	var delta := _stroke.finish_delta()
	var layer := _stroke_layer
	var action_name: String = "GO_FLORA " + ["Navigation", "Paint stroke", "Erase stroke", "Single placement"][mode]
	cancel_stroke()
	if delta.is_empty():
		set_status("No logical changes; no undo action created.")
		return
	var history := get_undo_redo()
	history.create_action(action_name, UndoRedo.MERGE_DISABLE, layer)
	history.add_do_method(layer, "apply_delta", delta, false)
	history.add_undo_method(layer, "apply_delta", delta, true)
	history.commit_action()
	print("GO_FLORA_COMMIT added=%d removed=%d records=%d set=%s" % [delta.added.size(), delta.removed.size(), layer.layer_data.records.size(), active_set.set_id])
	set_status("Committed %d additions / %d removals as one scene undo step." % [delta.added.size(), delta.removed.size()])
