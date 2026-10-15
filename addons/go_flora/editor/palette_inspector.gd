@tool
extends EditorInspectorPlugin

var controller: EditorPlugin
const EntriesProperty = preload("res://addons/go_flora/editor/palette_property.gd")
const Help = preload("res://addons/go_flora/editor/help_text.gd")

func _can_handle(object: Object) -> bool:
	return object is GFVegetationSet

func _parse_begin(_object: Object) -> void:
	var help := Button.new()
	help.name = "SetSettingsHelp"
	help.text = "Enabled / Density / Distance — справка"
	help.clip_text = true
	help.tooltip_text = "Enabled: " + Help.tip("enabled") + "\nDensity Multiplier: " + Help.tip("density_multiplier") + "\nDraw Distance: " + Help.tip("distance")
	help.pressed.connect(controller._show_help)
	add_custom_control(help)

func _parse_property(object: Object, _type: Variant.Type, property: String, _hint: PropertyHint, _hint_string: String, _usage: int, _wide: bool) -> bool:
	if property != "entries":
		return false
	var editor := EntriesProperty.new()
	editor.controller = controller
	add_property_editor(property, editor)
	return true
