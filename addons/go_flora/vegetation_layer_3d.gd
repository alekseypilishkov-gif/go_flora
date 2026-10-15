@tool
class_name VegetationLayer3D
extends Node3D

@export var layer_data: GFVegetationLayerData = GFVegetationLayerData.new():
	set(value):
		layer_data = value
		if is_inside_tree():
			_bind_resources()
			request_rebuild()
@export var cell_size_m: float = 8.0:
	set(value):
		cell_size_m = clampf(value, 0.25, 1000.0) if is_finite(value) else 8.0
		request_rebuild()
var render_diagnostics: PackedStringArray = []
var batches_by_set: Dictionary = {}
var _cache_root: Node3D
var _scene_root: Node3D
var _scene_cache: Dictionary = {}
var _bindings: Array[Dictionary] = []
var _palette_signature: String = ""
var _rebuild_pending := false
var _preview_added: Array[GFInstanceRecord] = []
var _preview_removed: Dictionary = {}

func _enter_tree() -> void:
	call_deferred("_initialize_layer")

func _initialize_layer() -> void:
	if not is_inside_tree():
		return
	_bind_resources()
	rebuild_now()

func _exit_tree() -> void:
	_unbind_resources()
	_preview_added.clear()
	_preview_removed.clear()

func editing_diagnostic() -> String:
	if layer_data == null:
		return "Assign VegetationLayerData in the Inspector."
	if not global_transform.is_finite() or absf(global_transform.basis.determinant()) < 0.00001:
		return "Layer transform must be finite and invertible."
	return layer_data.diagnostic()

func _get_configuration_warnings() -> PackedStringArray:
	var reason := editing_diagnostic()
	return PackedStringArray([reason]) if not reason.is_empty() else render_diagnostics

func _unbind_resources() -> void:
	for binding in _bindings:
		if is_instance_valid(binding.resource) and binding.resource.changed.is_connected(binding.callback):
			binding.resource.changed.disconnect(binding.callback)
	_bindings.clear()

func _bind(resource: Resource, callback: Callable) -> void:
	if resource == null:
		return
	for binding in _bindings:
		if binding.resource == resource:
			return
	resource.changed.connect(callback)
	_bindings.append({"resource": resource, "callback": callback})

func _signature() -> String:
	var values: Array = []
	if layer_data != null:
		for vegetation_set in layer_data.sets:
			if vegetation_set == null:
				continue
			values.append([vegetation_set.get_instance_id(), vegetation_set.set_id])
			for entry in vegetation_set.entries:
				if entry != null:
					values.append([entry.get_instance_id(), entry.source.get_instance_id() if entry.source != null else 0])
	return JSON.stringify(values)

func _bind_resources() -> void:
	_unbind_resources()
	_bind(layer_data, _on_data_changed)
	if layer_data != null:
		for vegetation_set in layer_data.sets:
			if vegetation_set == null:
				continue
			_bind(vegetation_set, _on_set_changed)
			for entry in vegetation_set.entries:
				_bind(entry, _on_asset_changed)
				if entry == null or entry.source == null:
					continue
				_bind(entry.source, _on_asset_changed)
				_bind(entry.source.asset, _on_asset_changed)
				_bind(entry.source.alpha_card, _on_asset_changed)
				if entry.source.alpha_card != null:
					_bind(entry.source.alpha_card.texture, _on_asset_changed)
				for material in entry.source.surface_materials:
					_bind(material, _on_asset_changed)
	_palette_signature = _signature()

func _on_data_changed() -> void:
	_bind_resources()
	request_rebuild()

func _on_asset_changed() -> void:
	if layer_data != null:
		for vegetation_set in layer_data.sets:
			if vegetation_set != null:
				for entry in vegetation_set.entries:
					if entry != null and entry.source != null:
						entry.source.invalidate()
	_bind_resources()
	request_rebuild()

func _on_set_changed() -> void:
	if _signature() != _palette_signature:
		_bind_resources()
		request_rebuild()
	# Presentation edits update the SAME existing renderer nodes; records stay unchanged.
	if layer_data != null:
		GFCellRenderer.apply_visibility(batches_by_set, layer_data.sets)

func request_rebuild() -> void:
	if not is_inside_tree() or _rebuild_pending:
		return
	_rebuild_pending = true
	call_deferred("rebuild_now")

func rebuild_now() -> void:
	_rebuild_pending = false
	if not is_inside_tree():
		return
	if not is_instance_valid(_cache_root):
		_cache_root = Node3D.new()
		_cache_root.name = "_GO_FLORA_RenderCache"
		_cache_root.set_meta("go_flora_owned", true)
		add_child(_cache_root, false, Node.INTERNAL_MODE_BACK)
	if not is_instance_valid(_scene_root):
		_scene_root = Node3D.new()
		_scene_root.name = "_GO_FLORA_SceneCache"
		add_child(_scene_root, false, Node.INTERNAL_MODE_BACK)
	for child in _cache_root.get_children():
		child.free()
	batches_by_set.clear()
	render_diagnostics.clear()
	var reason := editing_diagnostic()
	if not reason.is_empty():
		render_diagnostics.append(reason)
		for instance in _scene_cache.values():
			if is_instance_valid(instance):
				instance.free()
		_scene_cache.clear()
	else:
		var rendered: Array[GFInstanceRecord] = []
		for record in layer_data.records:
			if not _preview_removed.has(record.record_id):
				rendered.append(record)
		rendered.append_array(_preview_added)
		var result := GFCellRenderer.build(rendered, layer_data.sets, cell_size_m, _cache_root, _scene_root, _scene_cache)
		batches_by_set = result.by_set
		render_diagnostics = result.diagnostics
	if Engine.is_editor_hint():
		update_configuration_warnings()

func set_stroke_preview(added: Array[GFInstanceRecord], removed: Dictionary) -> void:
	_preview_added = added.duplicate()
	_preview_removed = removed.duplicate()
	request_rebuild()

func cancel_stroke_preview() -> void:
	_preview_added.clear()
	_preview_removed.clear()
	request_rebuild()

func apply_delta(delta: GFRecordDelta, reverse: bool) -> void:
	if layer_data == null or not layer_data.diagnostic().is_empty():
		return
	cancel_stroke_preview()
	delta.apply_to(layer_data, reverse)

func batch_count() -> int:
	var count := 0
	for batches in batches_by_set.values():
		count += batches.size()
	return count
