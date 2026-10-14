@tool
class_name GFCellRenderer
extends RefCounted

static func build(records: Array[GFInstanceRecord], sets: Array[GFVegetationSet], cell_size: float, container: Node3D) -> Dictionary:
	var sources: Dictionary = {}
	var set_map: Dictionary = {}
	var diagnostics: PackedStringArray = []
	for vegetation_set in sets:
		if vegetation_set == null:
			continue
		set_map[vegetation_set.set_id] = vegetation_set
		for entry in vegetation_set.entries:
			if entry == null or entry.source == null:
				continue
			var source := entry.source
			var key := JSON.stringify([vegetation_set.set_id, source.source_id])
			if not sources.has(key):
				var mesh := source.resolve_mesh()
				sources[key] = {"source": source, "mesh": mesh}
				if mesh == null:
					diagnostics.append(source.diagnostic())
	var groups: Dictionary = {}
	for record in records:
		if (record.flags & 2) != 0:
			continue
		var source_key := JSON.stringify([record.set_id, record.source_id])
		if not set_map.has(record.set_id) or not sources.has(source_key) or sources[source_key].mesh == null:
			diagnostics.append("Record %s: missing/unsupported set or source '%s'; logical record retained." % [record.record_id.left(8), source_key])
			continue
		var resolved: Dictionary = sources[source_key]
		var source: GFVegetationSource = resolved.source
		var cell := GFPlacement.cell_for(record.local_transform.origin, cell_size)
		var materials: Array[int] = []
		var mesh: Mesh = resolved.mesh
		for surface in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface)
			materials.append(material.get_instance_id() if material != null else 0)
		var key := JSON.stringify([record.layer_id, record.set_id, cell.x, cell.y, source_key, source.variant_revision, mesh.get_instance_id(), materials])
		if not groups.has(key):
			groups[key] = {"set_id": record.set_id, "mesh": resolved.mesh, "cell": cell, "transforms": [], "ids": []}
		var origin := Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)
		var transform := record.local_transform * source.mesh_transform
		transform.origin -= origin
		groups[key].transforms.append(transform)
		groups[key].ids.append(record.record_id)
	var by_set: Dictionary = {}
	for key in groups:
		var group: Dictionary = groups[key]
		var batch := MultiMeshInstance3D.new()
		batch.name = "GF_Cell_%s_%s_%s" % [group.cell.x, group.cell.y, group.set_id.validate_node_name()]
		batch.position = Vector3(group.cell.x * cell_size, 0.0, group.cell.y * cell_size)
		batch.set_meta("go_flora_owned", true)
		batch.set_meta("set_id", group.set_id)
		batch.set_meta("cell_key", group.cell)
		batch.set_meta("record_ids", group.ids)
		batch.multimesh = MultiMesh.new()
		batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		batch.multimesh.mesh = group.mesh
		batch.multimesh.instance_count = group.transforms.size()
		var bounds := AABB()
		for i in group.transforms.size():
			var transform: Transform3D = group.transforms[i]
			batch.multimesh.set_instance_transform(i, transform)
			var item_bounds: AABB = transform * group.mesh.get_aabb()
			bounds = item_bounds if i == 0 else bounds.merge(item_bounds)
		batch.multimesh.custom_aabb = bounds.grow(0.01)
		batch.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		container.add_child(batch)
		if not by_set.has(group.set_id):
			by_set[group.set_id] = []
		by_set[group.set_id].append(batch)
	apply_visibility(by_set, sets)
	return {"by_set": by_set, "diagnostics": diagnostics}

static func apply_visibility(by_set: Dictionary, sets: Array[GFVegetationSet]) -> void:
	for vegetation_set in sets:
		if vegetation_set == null:
			continue
		for batch in by_set.get(vegetation_set.set_id, []):
			if is_instance_valid(batch):
				batch.visible = vegetation_set.enabled
				batch.visibility_range_end = vegetation_set.draw_distance_m
				batch.visibility_range_end_margin = 0.0
