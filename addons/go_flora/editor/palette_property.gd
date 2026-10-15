@tool
extends EditorProperty

const Palette = preload("res://addons/go_flora/editor/palette_view.gd")
const Help = preload("res://addons/go_flora/editor/help_text.gd")
var controller: EditorPlugin
var palette: VBoxContainer

func _init() -> void:
	add_to_group("go_flora_palette_properties")
	var box := VBoxContainer.new()
	add_child(box)
	set_bottom_editor(box)
	palette = Palette.new()
	box.add_child(palette)
	palette.source_selected.connect(func(id: String) -> void:
		var vegetation_set := get_edited_object() as GFVegetationSet
		if vegetation_set != null:
			controller.inspect_resource(vegetation_set.source_by_id(id)))
	palette.inspect_source.connect(func(source: GFVegetationSource) -> void: controller.inspect_resource(source))
	palette.entry_edited.connect(func(entry: GFPaletteEntry, property: String, value: Variant) -> void:
		controller.edit_palette_entry(get_edited_object(), entry, property, value))
	palette.reference_edited.connect(func(index: int, source: GFVegetationSource) -> void:
		controller.assign_palette_source(get_edited_object(), index, source))
	var label := Label.new()
	label.text = "Добавить существующий Source .tres"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Help.apply(label, "source_reference")
	box.add_child(label)
	var add := EditorResourcePicker.new()
	add.name = "AddExistingSource"
	add.base_type = "GFVegetationSource"
	Help.apply(add, "source_reference")
	add.resource_changed.connect(func(resource: Resource) -> void:
		if resource is GFVegetationSource:
			controller.append_palette_source(get_edited_object(), resource)
			add.edited_resource = null)
	box.add_child(add)
	add_focusable(add)

func _update_property() -> void:
	palette.configure(get_edited_object() as GFVegetationSet, "", true)
