@tool
extends ConfirmationDialog

signal source_saved(source: GFVegetationSource)
var source := GFVegetationSource.new()
var _preview: TextureRect
var _info: Label
var _save: EditorFileDialog

func setup(alpha: bool) -> void:
	dialog_hide_on_ok = false
	canceled.connect(queue_free)
	title = "Create alpha plant" if alpha else "Add Mesh / imported GLB / PackedScene"
	size = Vector2i(470, 650)
	get_ok_button().text = "Save Source…"
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
	var picker := EditorResourcePicker.new()
	picker.base_type = "Texture2D" if alpha else "Mesh,PackedScene"
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
			_add_number(fields, field[0], float(field[2]), float(field[3]), float(field[4]), float(source.alpha_card.get(field[1])), func(value: float) -> void:
				source.alpha_card.set(field[1], int(value) if field[1] == "radial_count" else value)
				_refresh())
		var atlas_help := Label.new()
		atlas_help.text = "Atlas pixels: X, Y, Width, Height (all 0 = full image). Preview shows the region including the gutter inset. Supply extruded gutters for mipmaps."
		atlas_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fields.add_child(atlas_help)
		for index in 4:
			_add_number(fields, ["Atlas X", "Atlas Y", "Atlas width", "Atlas height"][index], 0, 32768, 1, 0, func(value: float) -> void:
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
	_save.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_save.access = EditorFileDialog.ACCESS_RESOURCES
	_save.add_filter("*.tres", "GO_FLORA source")
	add_child(_save)
	confirmed.connect(func() -> void:
		_save.current_file = source.display_name.validate_filename() + "_source.tres"
		_save.popup_centered_ratio(0.6))
	_save.file_selected.connect(_save_source)
	_refresh()

func _add_number(fields: Control, label_text: String, minimum: float, maximum: float, step_value: float, value: float, callback: Callable) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var spin := SpinBox.new()
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
	if not GFSourceResolver.project_path(path) or path.get_extension() != "tres":
		return
	var error := ResourceSaver.save(source, path)
	if error != OK:
		_info.text = "Cannot save source: %s (error %d). Choose a writable project path." % [path, error]
		return
	source_saved.emit(source)
	queue_free()
