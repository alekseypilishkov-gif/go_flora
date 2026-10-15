@tool
class_name GFVegetationSet
extends Resource

@export var set_id: String = "":
	set(value):
		set_id = value
		emit_changed()
@export var display_name: String = "Vegetation set":
	set(value):
		display_name = value
		emit_changed()
## Именованная палитра растений; выбор отдельного растения для кисти не переписывает этот массив.
@export var entries: Array[GFPaletteEntry] = []:
	set(value):
		entries = value
		emit_changed()
## Serialized render catalog; never used for Paint, Single or named palette rows.
@export_storage var render_only_sources: Array[GFVegetationSource] = []:
	set(value):
		render_only_sources = value
		emit_changed()
## Показывать растения этого набора. Сохранённые записи остаются; gameplay fallback продолжает работу.
@export var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()
## Множитель плотности новых Paint-размещений; 1 = плотность кисти. Прежние записи не удаляются.
@export var density_multiplier: float = 1.0:
	set(value):
		density_multiplier = value
		emit_changed()
## Дальность существующих render cells в метрах. 0 = без ограничения, это не радиус кисти.
@export var draw_distance_m: float = 0.0:
	set(value):
		draw_distance_m = maxf(0.0, value) if is_finite(value) else 0.0
		emit_changed()

func diagnostic() -> String:
	return painting_diagnostic()

func source_by_id(id: String, enabled_only: bool = false) -> GFVegetationSource:
	for entry in entries:
		if entry != null and entry.source != null and entry.source.source_id == id and (not enabled_only or entry.enabled):
			return entry.source
	return null

func rendering_sources() -> Array[GFVegetationSource]:
	var sources: Array[GFVegetationSource] = []
	var ids: Dictionary = {}
	for entry in entries:
		if entry != null and entry.source != null and not ids.has(entry.source.source_id):
			sources.append(entry.source)
			ids[entry.source.source_id] = true
	for source in render_only_sources:
		if source != null and not ids.has(source.source_id):
			sources.append(source)
			ids[source.source_id] = true
	return sources

func painting_diagnostic(selected_id: String = "") -> String:
	if set_id.strip_edges().is_empty():
		return "Set needs a stable set_id."
	if not is_finite(density_multiplier) or density_multiplier < 0.0:
		return "Set '%s': density multiplier must be finite and nonnegative." % set_id
	var ids: Dictionary = {}
	var total := 0.0
	var selected: GFPaletteEntry
	for entry in entries:
		if entry != null and entry.source != null:
			if ids.has(entry.source.source_id):
				return "Palette contains duplicate source_id '%s'." % entry.source.source_id
			ids[entry.source.source_id] = true
		if entry != null and not entry.enabled:
			continue
		if entry == null or entry.source == null:
			if not selected_id.is_empty():
				continue
			return "Set '%s' contains a missing source; repair the palette to paint." % set_id
		if not selected_id.is_empty():
			if entry.source.source_id == selected_id:
				selected = entry
			continue
		if not is_finite(entry.weight) or entry.weight < 0.0:
			return "Palette weights must be finite and nonnegative."
		if entry.weight == 0.0:
			continue
		var reason := entry.source.diagnostic()
		if not reason.is_empty():
			return reason
		total += entry.weight
	if not selected_id.is_empty():
		if selected == null:
			return "Выбранное растение отсутствует или выключено. Выберите включённый источник в палитре."
		return selected.source.diagnostic()
	if total <= 0.0 or not is_finite(total):
		return "MIX: нет включённых источников с положительным весом. Включите растение и задайте вес > 0."
	return ""

func ordered_entries() -> Array[GFPaletteEntry]:
	var ordered: Array[GFPaletteEntry] = entries.duplicate()
	ordered.sort_custom(func(a: GFPaletteEntry, b: GFPaletteEntry) -> bool: return a.source.source_id < b.source.source_id)
	return ordered

func placement_entries() -> Array[GFPaletteEntry]:
	var eligible: Array[GFPaletteEntry] = []
	for entry in entries:
		if entry != null and entry.enabled and entry.source != null and is_finite(entry.weight) and entry.weight > 0.0:
			eligible.append(entry)
	eligible.sort_custom(func(a: GFPaletteEntry, b: GFPaletteEntry) -> bool: return a.source.source_id < b.source.source_id)
	return eligible
