@tool
class_name GFPaletteEntry
extends Resource

@export var source: GFVegetationSource:
	set(value):
		source = value
		emit_changed()
@export var weight: float = 1.0:
	set(value):
		weight = value
		emit_changed()
