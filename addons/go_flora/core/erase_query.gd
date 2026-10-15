@tool
class_name GFEraseQuery
extends RefCounted

# Ephemeral world-space grid. No placement/schema fields are changed. Building,
# empty-cell visits and candidate tests all consume the same per-tick quota.
const WORK_PER_TICK := 512
var removed: Dictionary = {}
var preview_changes: Dictionary = {}
var inspected := 0
var work_last_tick := 0
var _data: GFVegetationLayerData
var _set_id: String
var _transform: Transform3D
var _radius: float
var _indexed := 0
var _grid: Dictionary = {}
var _occupied: Array[Vector3i] = []
var _live_count := 0
var _full_segment := false
var _positions: Dictionary = {}
var _paths: Array[Dictionary] = []
var _head := 0
var _cells: Array[Vector3i] = []
var _cell_head := 0
var _candidate := 0
var _from: Vector3
var _to: Vector3

func _init(data: GFVegetationLayerData, set_id: String, transform: Transform3D, radius: float) -> void:
	_data = data
	_set_id = set_id
	_transform = transform
	_radius = radius

func enqueue(from: Vector3, to: Vector3) -> void:
	_paths.append({"from": from, "to": to})

func pending() -> bool:
	return _indexed < _data.records.size() or _head < _paths.size() or _cell_head < _cells.size()

func cell(point: Vector3) -> Vector3i:
	return Vector3i(floori(point.x / _radius), floori(point.y / _radius), floori(point.z / _radius))

func process_pending(quota: int = WORK_PER_TICK) -> void:
	work_last_tick = 0
	var deadline := Time.get_ticks_usec() + 4000
	while work_last_tick < quota and pending():
		work_last_tick += 1
		if _indexed < _data.records.size():
			var record := _data.records[_indexed]
			if record.set_id == _set_id and (record.flags & 1) == 0:
				var point := _transform * record.local_transform.origin
				var key := cell(point)
				if not _grid.has(key):
					_grid[key] = []
					_occupied.append(key)
				_grid[key].append(_indexed)
				_live_count += 1
				_positions[_indexed] = point
			_indexed += 1
		elif _live_count == 0:
			_paths.clear()
			_head = 0
			_cells = []
			_cell_head = 0
		elif _cell_head < _cells.size():
			if _full_segment and _candidate == 0:
				var center := (Vector3(_cells[_cell_head]) + Vector3.ONE * 0.5) * _radius
				var closest_cell := Geometry3D.get_closest_point_to_segment(center, _from, _to)
				# Bounding sphere conservatively encloses the cell expanded by
				# the brush. Exact record/world distance is still tested below.
				if closest_cell.distance_squared_to(center) > pow(_radius * (1.0 + sqrt(3.0) * 0.5), 2):
					_cell_head += 1
					continue
			var bucket: Array = _grid.get(_cells[_cell_head], [])
			if _candidate >= bucket.size():
				_cell_head += 1
				_candidate = 0
			else:
				var index: int = bucket[_candidate]
				inspected += 1
				var closest := Geometry3D.get_closest_point_to_segment(_positions[index], _from, _to)
				if closest.distance_squared_to(_positions[index]) <= _radius * _radius:
					removed[_data.records[index].record_id] = index
					preview_changes[_data.records[index].record_id] = true
					# Remove hits from the transient grid so overlapping sweeps never
					# retest thousands of already erased plants.
					bucket[_candidate] = bucket.back()
					bucket.pop_back()
					_live_count -= 1
				else:
					_candidate += 1
		else:
			var segment := _paths[_head]
			_from = segment.from
			_full_segment = _from.distance_to(segment.to) / _radius > _occupied.size() * 2
			_to = segment.to if _full_segment else _from.move_toward(segment.to, _radius)
			if _to == segment.to:
				_head += 1
			else:
				segment.from = _to
			_cells = []
			_cell_head = 0
			_candidate = 0
			if _full_segment:
				# Sparse/very long paths visit each occupied cell once, avoiding
				# millions of empty cells for a tiny brush or a distant endpoint.
				_cells = _occupied
				continue
			var low := cell(_from.min(_to) - Vector3.ONE * _radius)
			var high := cell(_from.max(_to) + Vector3.ONE * _radius)
			for x in range(low.x, high.x + 1):
				for y in range(low.y, high.y + 1):
					for z in range(low.z, high.z + 1):
						_cells.append(Vector3i(x, y, z))
		if Time.get_ticks_usec() >= deadline:
			break
	if _head == _paths.size():
		_paths.clear()
		_head = 0
