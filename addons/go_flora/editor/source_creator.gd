@tool
extends ConfirmationDialog
const Help = preload("res://addons/go_flora/editor/help_text.gd")

signal source_saved(source: GFVegetationSource)
var source := GFVegetationSource.new()
var _preview: TextureRect
var _info: Label
var _save: EditorFileDialog
var _closing := false
var _saving := false
var _saved := false
var _native_popup: WeakRef
const Persistence = preload("res://addons/go_flora/editor/source_persistence.gd")

func setup(alpha: bool) -> void:
	# EditorResourcePicker Quick Load is an editor-root exclusive window.
	# This tool must leave that slot available; only the native choosers are modal.
	exclusive = false
	transient = true
	dialog_hide_on_ok = false
	canceled.connect(close_creator)
	title = "Create alpha plant" if alpha else "Add Mesh / imported GLB / PackedScene"
	size = Vector2i(470, 650)
	get_ok_button().text = "Save Source…"
	Help.apply(get_ok_button(), "save_source")
	source.source_id = "source-%d-%d" % [Time.get_unix_time_from_system() * 1000, get_instance_id()]
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(430, 480)
	add_child(scroll)
	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(fields)
	var help := Label.new()
	help.text = "Choose a project-local imported resource. Saves a reusable .tres and adds it to the active set. Originals are referenced, never edited."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fields.add_child(help)
	var picker := preload("res://addons/go_flora/editor/source_asset_picker.gd").new()
	picker.native_action_finished.connect(_remember_native_popup)
	picker.base_type = "Texture2D" if alpha else "Mesh,PackedScene"
	picker.name = "SourceAssetPicker"
	Help.apply(picker, "texture" if alpha else "add_model")
	fields.add_child(picker)
	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(220, 140)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fields.add_child(_preview)
	if alpha:
		source.kind = GFVegetationSource.Kind.ALPHA_CARD
		source.alpha_card = GFAlphaCard.new()
		var modes := OptionButton.new()
		modes.name = "CardMode"
		Help.apply(modes, "card_mode")
		for name_value in ["Single upright card", "Two crossed cards", "Radial 3–4 cards"]:
			modes.add_item(name_value)
		modes.select(1)
		modes.item_selected.connect(func(value: int) -> void:
			source.alpha_card.mode = value as GFAlphaCard.Mode
			_refresh())
		fields.add_child(modes)
		for field in [["Width (m)", "width_m", 0.01, 1000, 0.05], ["Height (m)", "height_m", 0.01, 1000, 0.05],
			["Radial count", "radial_count", 3, 4, 1], ["Splay (°)", "splay_degrees", -30, 30, 1],
			["Alpha threshold", "alpha_threshold", 0.01, 0.99, 0.01], ["UV gutter inset (px)", "gutter_px", 0, 32, 0.5]]:
			_add_number(fields, field[0], float(field[2]), float(field[3]), float(field[4]), float(source.alpha_card.get(field[1])), field[1], func(value: float) -> void:
				source.alpha_card.set(field[1], int(value) if field[1] == "radial_count" else value)
				_refresh())
		var atlas_help := Label.new()
		atlas_help.text = "Atlas pixels: X, Y, Width, Height (all 0 = full image). Preview shows the region including the gutter inset. Supply extruded gutters for mipmaps."
		atlas_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fields.add_child(atlas_help)
		for index in 4:
			var key: String = ["Atlas X", "Atlas Y", "Atlas width", "Atlas height"][index]
			_add_number(fields, key, 0, 32768, 1, 0, key, func(value: float) -> void:
				var rect := source.alpha_card.atlas_region_px
				if index < 2:
					rect.position[index] = int(value)
				else:
					rect.size[index - 2] = int(value)
				source.alpha_card.atlas_region_px = rect
				_refresh())
	else:
		var warning := Label.new()
		warning.text = "Static scenes are classified without running scripts. Scenes with gameplay need review in the Source Inspector; copy the exact revision from the diagnostic after inspecting their scripts. Unknown features stay blocked."
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fields.add_child(warning)
	picker.resource_changed.connect(func(resource: Resource) -> void:
		if alpha:
			source.alpha_card.texture = resource as Texture2D
		else:
			source.asset = resource
			source.kind = GFVegetationSource.Kind.STATIC_MESH if resource is Mesh else GFVegetationSource.Kind.IMPORTED_SCENE
		source.display_name = resource.resource_path.get_file().get_basename() if resource != null else "Plant"
		_refresh())
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fields.add_child(_info)
	_save = EditorFileDialog.new()
	_save.name = "GOFloraSourceSaveDialog"
	_save.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_save.access = EditorFileDialog.ACCESS_RESOURCES
	_save.add_filter("*.tres", "GO_FLORA source")
	# Editor-owned sibling: Save is the single exclusive child of the editor root.
	# It is explicitly released with this draft, including context changes.
	get_parent().add_child(_save)
	confirmed.connect(_request_save)
	_save.canceled.connect(_save_cancelled)
	_save.file_selected.connect(_save_source)
	_refresh()

func close_creator() -> void:
	if _closing:
		return
	_closing = true
	_release_native_popup()
	_release_save()
	_hide_owned_windows(self)
	hide()
	queue_free()

func _exit_tree() -> void:
	_closing = true
	_release_native_popup()
	_release_save()

func _remember_native_popup() -> void:
	if _closing:
		return
	var window := get_parent().get_last_exclusive_window()
	if window != null and window != get_parent().get_window():
		_native_popup = weakref(window)
		if not window.visibility_changed.is_connected(_native_popup_visibility.bind(window)):
			window.visibility_changed.connect(_native_popup_visibility.bind(window))

func _native_popup_visibility(window: Window) -> void:
	if not window.visible:
		if _native_popup != null and _native_popup.get_ref() == window:
			_native_popup = null
		if window.visibility_changed.is_connected(_native_popup_visibility.bind(window)):
			window.visibility_changed.disconnect(_native_popup_visibility.bind(window))
		call_deferred("_focus_draft")

func _focus_draft() -> void:
	if not _closing and not _saving and visible and get_parent().get_last_exclusive_window() == get_parent().get_window():
		grab_focus()

func _release_native_popup() -> void:
	var window: Window = _native_popup.get_ref() if _native_popup != null else null
	_native_popup = null
	if is_instance_valid(window):
		if window.visible and window is AcceptDialog:
			window.notification(Window.NOTIFICATION_WM_CLOSE_REQUEST)
		window.hide()
		if window.visibility_changed.is_connected(_native_popup_visibility.bind(window)):
			window.visibility_changed.disconnect(_native_popup_visibility.bind(window))

func _hide_owned_windows(node: Node) -> void:
	for child in node.get_children(true):
		if child is Window:
			child.hide()
		_hide_owned_windows(child)

func _release_save() -> void:
	if is_instance_valid(_save):
		_save.hide()
		if not _save.is_queued_for_deletion():
			_save.queue_free()

func _request_save() -> void:
	if _closing or _saved or _saving:
		return
	_refresh()
	if get_ok_button().disabled:
		return
	_saving = true
	_save.current_file = source.display_name.validate_filename() + "_source.tres"
	hide()
	call_deferred("_show_save")

func _show_save() -> void:
	if not _closing and _saving and is_instance_valid(_save):
		_save.popup_centered_ratio(0.6)

func _save_cancelled() -> void:
	if _closing or _saved:
		return
	_save.hide()
	_saving = false
	call_deferred("_restore_draft")

func _restore_draft() -> void:
	if not _closing and not _saved and not _saving:
		popup_centered()
		grab_focus()

func _add_number(fields: Control, label_text: String, minimum: float, maximum: float, step_value: float, value: float, help_key: String, callback: Callable) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	Help.apply(label, help_key)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var spin := SpinBox.new()
	spin.name = help_key.validate_node_name()
	Help.apply(spin, help_key)
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step_value
	spin.value = value
	spin.value_changed.connect(callback)
	row.add_child(spin)
	fields.add_child(row)

func _refresh() -> void:
	if _info == null:
		return
	var resolved := source.resolve()
	_info.text = "%s\n%s" % ["Ready: %d static parts. Ground pivot at Y=0 for cards." % resolved.parts.size() if resolved.status == GFSourceResolution.Status.READY else resolved.diagnostic(), "; ".join(resolved.diagnostics)]
	get_ok_button().disabled = resolved.status != GFSourceResolution.Status.READY
	if source.kind == GFVegetationSource.Kind.IMPORTED_SCENE and source.asset is PackedScene:
		get_ok_button().disabled = false
	if source.alpha_card != null and source.alpha_card.texture != null:
		var preview := AtlasTexture.new()
		preview.atlas = source.alpha_card.texture
		var region := source.alpha_card.region().grow(-source.alpha_card.gutter_px)
		if region.size.x > 0 and region.size.y > 0 and Rect2(Vector2.ZERO, source.alpha_card.texture.get_size()).encloses(region):
			preview.region = region
			_preview.texture = preview
		else:
			_preview.texture = source.alpha_card.texture

func _save_source(path: String) -> void:
	if _closing or _saved:
		return
	var destination_error := Persistence.destination_error(path)
	if not destination_error.is_empty():
		_info.text = destination_error
		_save_cancelled()
		return
	_refresh()
	if get_ok_button().disabled:
		_save_cancelled()
		return
	if source.schema_version != 1 or source.resource_local_to_scene:
		_info.text = "Новый Source должен иметь schema 1 и resource_local_to_scene=false."
		_save_cancelled()
		return
	var expected := Persistence.snapshot(source)
	var error := _write_source(path)
	if error != OK:
		_info.text = "Cannot save source: %s (error %d). Choose a writable project path." % [path, error]
		_save_cancelled()
		return
	var persisted := _load_persisted_source(path)
	var validation_error := Persistence.validation_error(expected, persisted, path)
	if not validation_error.is_empty():
		_info.text = "Файл записан: %s. Source не добавлен: %s. Файл сохранён; выберите другое имя или проверьте его отдельно." % [path, validation_error]
		_save_cancelled()
		return
	_saved = true
	_saving = false
	_save.hide()
	hide()
	source_saved.emit(persisted)
	close_creator()

# Kept separate for deterministic save/reload failure probes in disposable projects.
func _write_source(path: String) -> Error:
	return ResourceSaver.save(source, path)

func _load_persisted_source(path: String) -> Resource:
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
