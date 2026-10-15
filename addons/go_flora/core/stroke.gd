@tool
class_name GFStroke
extends RefCounted

enum Mode { PAINT, ERASE, SINGLE }
var delta := GFRecordDelta.new()
var diagnostic: String = ""
var candidates_used: int = 0
var stamp_count: int = 0
var budget_exhausted: bool = false
var _brush: GFBrush
var _set: GFVegetationSet
var _layer_transform: Transform3D
var _data: GFVegetationLayerData
var _cell_size: float
var _mode: Mode
var _stroke_id: String
var _last_position: Vector3
var _last_normal: Vector3
var _has_last := false
var _distance_to_stamp := 0.0
var _sample_credit := 0.0
var _erased: Dictionary = {}

func begin(data: GFVegetationLayerData, layer_transform: Transform3D, vegetation_set: GFVegetationSet, brush: GFBrush, cell_size: float, mode: Mode) -> bool:
	diagnostic = data.diagnostic()
	if diagnostic.is_empty():
		diagnostic = brush.diagnostic()
	if diagnostic.is_empty() and mode != Mode.ERASE:
		diagnostic = vegetation_set.diagnostic()
	if not diagnostic.is_empty():
		return false
	if not layer_transform.is_finite() or absf(layer_transform.basis.determinant()) < 0.00001:
		diagnostic = "Layer transform must be finite and invertible."
		return false
	if cell_size < 0.25 or cell_size > 1000.0 or not is_finite(cell_size):
		diagnostic = "Cell size must be [0.25,1000] metres."
		return false
	_data = data
	_layer_transform = layer_transform
	_set = vegetation_set
	_brush = brush.duplicate() as GFBrush
	_cell_size = cell_size
	_mode = mode
	delta.before_serial = data.next_stroke_serial
	delta.after_serial = data.next_stroke_serial + 1
	_stroke_id = "%s/stroke/%d" % [data.layer_id, data.next_stroke_serial]
	_distance_to_stamp = brush.radius_m * brush.spacing_ratio
	return true

func break_path() -> void:
	# Single is one attempt per click even when the pointer leaves/re-enters a target.
	if _mode == Mode.SINGLE:
		return
	_has_last = false
	_distance_to_stamp = _brush.radius_m * _brush.spacing_ratio

func feed(hit: Dictionary, resolver: Callable) -> void:
	if budget_exhausted or not _brush.accepts_hit(hit, _layer_transform):
		return
	if _mode == Mode.PAINT and (_brush.density_per_m2 == 0.0 or _set.density_multiplier == 0.0):
		diagnostic = "Zero density: no placements."
		return
	var position: Vector3 = hit.position
	var normal: Vector3 = hit.normal
	if not _has_last:
		_stamp(position, normal, PI * _brush.radius_m * _brush.radius_m, resolver)
		_has_last = true
	elif _mode != Mode.SINGLE:
		var travel := _last_position.distance_to(position)
		var consumed := 0.0
		# Resampling depends on travelled distance, not mouse event count or frame time.
		while travel - consumed >= _distance_to_stamp and not budget_exhausted:
			consumed += _distance_to_stamp
			var fraction := consumed / travel
			_stamp(_last_position.lerp(position, fraction), _last_normal.lerp(normal, fraction).normalized(),
				2.0 * _brush.radius_m * _brush.radius_m * _brush.spacing_ratio, resolver)
			_distance_to_stamp = _brush.radius_m * _brush.spacing_ratio
		_distance_to_stamp -= travel - consumed
	_last_position = position
	_last_normal = normal

func _stamp(position: Vector3, normal: Vector3, area: float, resolver: Callable) -> void:
	if stamp_count >= _brush.max_candidates:
		budget_exhausted = true
		return
	stamp_count += 1
	if _mode == Mode.ERASE:
		# Each scan is bounded by the stroke work budget, as is placement sampling.
		for i in _data.records.size():
			if candidates_used >= _brush.max_candidates:
				budget_exhausted = true
				break
			candidates_used += 1
			var record := _data.records[i]
			if record.set_id != _set.set_id or (record.flags & 1) != 0 or _erased.has(record.record_id):
				continue
			var world_position: Vector3 = _layer_transform * record.local_transform.origin
			if world_position.distance_squared_to(position) <= _brush.radius_m * _brush.radius_m:
				_erased[record.record_id] = i
		return
	if not _set.enabled:
		return
	var count := 1 if _mode == Mode.SINGLE else 0
	if _mode == Mode.PAINT:
		_sample_credit += area * _brush.density_per_m2 * _set.density_multiplier
		count = mini(floori(minf(_sample_credit, float(_brush.max_candidates))), _brush.max_candidates)
		_sample_credit -= count
	var tangent := normal.cross(Vector3.FORWARD).normalized()
	if tangent.length_squared() < 0.5:
		tangent = normal.cross(Vector3.RIGHT).normalized()
	var bitangent := normal.cross(tangent).normalized()
	for sample in count:
		if candidates_used >= _brush.max_candidates:
			budget_exhausted = true
			break
		var index := candidates_used
		candidates_used += 1
		var radius := _brush.radius_m * sqrt(GFPlacement.random_unit(_brush.seed, _stroke_id, index, "radius"))
		var angle := TAU * GFPlacement.random_unit(_brush.seed, _stroke_id, index, "angle")
		var point := position if _mode == Mode.SINGLE else position + radius * (tangent * cos(angle) + bitangent * sin(angle))
		var resolved: Dictionary = resolver.call(point, normal)
		if resolved.is_empty() or not _brush.accepts_hit(resolved, _layer_transform):
			continue
		delta.added.append(GFPlacement.make_record(resolved, _layer_transform, _data.layer_id, _set, _brush, _stroke_id, index, _cell_size))

func preview_removed_ids() -> Dictionary:
	return _erased

func finish_delta() -> GFRecordDelta:
	var indices: Array = _erased.values()
	indices.sort()
	delta.removed.clear()
	delta.removed_indices.clear()
	for index in indices:
		delta.removed.append(_data.records[index])
		delta.removed_indices.append(index)
	return delta
