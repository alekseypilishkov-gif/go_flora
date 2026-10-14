@tool
class_name GFVegetationSet
extends Resource

@export var set_id: String = "":
	set(value):
		set_id = value
		emit_changed()
@export var display_name: String = "Vegetation set"
@export var entries: Array[GFPaletteEntry] = []:
	set(value):
		entries = value
		emit_changed()
@export var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()
@export var density_multiplier: float = 1.0:
	set(value):
		density_multiplier = value
		emit_changed()
@export var draw_distance_m: float = 0.0:
	set(value):
		draw_distance_m = maxf(0.0, value) if is_finite(value) else 0.0
		emit_changed()

func diagnostic() -> String:
	if set_id.strip_edges().is_empty():
		return "Set needs a stable set_id."
	if not is_finite(density_multiplier) or density_multiplier < 0.0:
		return "Set '%s': density multiplier must be finite and nonnegative." % set_id
	var ids: Dictionary = {}
	var total := 0.0
	for entry in entries:
		if entry == null or entry.source == null:
			return "Set '%s' contains a missing source; repair the palette to paint." % set_id
		if not is_finite(entry.weight) or entry.weight < 0.0:
			return "Palette weights must be finite and nonnegative."
		if ids.has(entry.source.source_id):
			return "Palette contains duplicate source_id '%s'." % entry.source.source_id
		ids[entry.source.source_id] = true
		var reason := entry.source.diagnostic()
		if not reason.is_empty():
			return reason
		total += entry.weight
	if total <= 0.0 or not is_finite(total):
		return "Palette needs at least one valid source with positive weight."
	return ""

func ordered_entries() -> Array[GFPaletteEntry]:
	var ordered: Array[GFPaletteEntry] = entries.duplicate()
	ordered.sort_custom(func(a: GFPaletteEntry, b: GFPaletteEntry) -> bool: return a.source.source_id < b.source.source_id)
	return ordered
