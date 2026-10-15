@tool
extends VBoxContainer

signal source_selected(source_id: String)
signal inspect_source(source: GFVegetationSource)
signal entry_edited(entry: GFPaletteEntry, property: String, value: Variant)
signal reference_edited(index: int, source: GFVegetationSource)
signal remove_requested(entry: GFPaletteEntry)
const Help = preload("res://addons/go_flora/editor/help_text.gd")
var vegetation_set: GFVegetationSet
var selected_id := ""
var editable_references := false
var rows: Array[Dictionary] = []
var _bindings: Array[Resource] = []
var _structure := ""
var _pending := false

func configure(value: GFVegetationSet, selected: String = "", references: bool = false) -> void:
	vegetation_set = value
	selected_id = selected
	editable_references = references
	if is_inside_tree():
		sync()

func _ready() -> void:
	sync()

func _exit_tree() -> void:
	_unbind()

func _unbind() -> void:
	for resource in _bindings:
		if is_instance_valid(resource) and resource.changed.is_connected(_schedule):
			resource.changed.disconnect(_schedule)
	_bindings.clear()

func _bind(resource: Resource) -> void:
	if resource != null and not _bindings.has(resource):
		resource.changed.connect(_schedule)
		_bindings.append(resource)

func _schedule() -> void:
	if not _pending and is_inside_tree():
		_pending = true
		call_deferred("sync")

func sync() -> void:
	_pending = false
	if not is_inside_tree():
		return
	_unbind()
	_bind(vegetation_set)
	var structure: Array = [editable_references]
	if vegetation_set != null:
		for entry in vegetation_set.entries:
			structure.append([entry.get_instance_id() if entry != null else 0, entry.source.get_instance_id() if entry != null and entry.source != null else 0])
	var key := JSON.stringify(structure)
	if key != _structure:
		for child in get_children():
			remove_child(child)
			child.queue_free()
		rows.clear()
		_structure = key
		if vegetation_set != null:
			for index in vegetation_set.entries.size():
				_add_row(vegetation_set.entries[index], index)
	for row in rows:
		var entry: GFPaletteEntry = row.entry
		var source: GFVegetationSource = entry.source if entry != null else null
		_bind(entry)
		_bind(source)
		if source != null:
			_bind(source.alpha_card)
		row.select.text = source.display_name if source != null and not source.display_name.is_empty() else (source.source_id if source != null else "Источник не назначен")
		row.select.set_pressed_no_signal(source != null and source.source_id == selected_id)
		row.select.disabled = source == null
		row.enabled.disabled = entry == null
		row.enabled.set_pressed_no_signal(entry.enabled if entry != null else false)
		row.weight.editable = entry != null
		row.weight.set_value_no_signal(entry.weight if entry != null and is_finite(entry.weight) else 0.0)
		row.inspect.disabled = source == null
		var identity := "\n%s · ID: %s" % [GFVegetationSource.Kind.keys()[source.kind] if source.kind >= 0 and source.kind < GFVegetationSource.Kind.size() else "UNKNOWN", source.source_id] if source != null else "\nОтсутствующий источник; сохранённые записи остаются."
		row.select.tooltip_text = Help.tip("plant") + identity
		row.preview.tooltip_text = Help.tip("plant") + identity
		row.preview.edited_resource = source.alpha_card.texture if source != null and source.alpha_card != null else (source.asset if source != null else null)
		if row.has("reference"):
			row.reference.edited_resource = source

func _add_row(entry: GFPaletteEntry, index: int) -> void:
	var panel := VBoxContainer.new()
	panel.name = "SourceRow%d" % index
	add_child(panel)
	var heading := HBoxContainer.new()
	panel.add_child(heading)
	var enabled := CheckBox.new()
	enabled.name = "SourceEnabled"
	Help.apply(enabled, "entry_enabled")
	enabled.toggled.connect(func(value: bool) -> void: entry_edited.emit(entry, "enabled", value))
	heading.add_child(enabled)
	var select := Button.new()
	select.name = "SourceName"
	select.clip_text = true
	select.toggle_mode = true
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.pressed.connect(func() -> void:
		if entry != null and entry.source != null:
			source_selected.emit(entry.source.source_id))
	heading.add_child(select)
	var inspect := Button.new()
	inspect.text = "↗"
	Help.apply(inspect, "inspect_source")
	inspect.pressed.connect(func() -> void:
		if entry != null and entry.source != null:
			inspect_source.emit(entry.source))
	heading.add_child(inspect)
	var remove := Button.new()
	remove.name = "RemoveFromPalette"
	remove.text = "−"
	remove.tooltip_text = "Убрать из палитры (Remove from Palette). Уже размещённые растения останутся видимыми. Файлы не удаляются."
	remove.pressed.connect(func() -> void: remove_requested.emit(entry))
	heading.add_child(remove)
	var controls := HBoxContainer.new()
	panel.add_child(controls)
	var preview := EditorResourcePicker.new()
	preview.base_type = "Resource"
	preview.editable = false
	preview.custom_minimum_size = Vector2(52, 40)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.resource_selected.connect(func(_resource: Resource, _inspect: bool) -> void:
		if entry != null and entry.source != null:
			source_selected.emit(entry.source.source_id))
	controls.add_child(preview)
	var label := Label.new()
	label.text = "Вес"
	Help.apply(label, "weight")
	controls.add_child(label)
	var weight := SpinBox.new()
	weight.name = "SourceWeight"
	weight.min_value = 0
	weight.max_value = 1000
	weight.allow_greater = true
	weight.step = 0.1
	weight.custom_minimum_size.x = 92
	Help.apply(weight, "weight")
	weight.value_changed.connect(func(value: float) -> void: entry_edited.emit(entry, "weight", value))
	controls.add_child(weight)
	var row := {"entry": entry, "select": select, "enabled": enabled, "weight": weight, "preview": preview, "inspect": inspect, "remove": remove}
	if editable_references:
		var reference := EditorResourcePicker.new()
		reference.base_type = "GFVegetationSource"
		Help.apply(reference, "source_reference")
		reference.resource_changed.connect(func(resource: Resource) -> void: reference_edited.emit(index, resource as GFVegetationSource))
		panel.add_child(reference)
		row.reference = reference
	rows.append(row)
