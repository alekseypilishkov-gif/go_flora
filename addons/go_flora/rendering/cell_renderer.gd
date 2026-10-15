@tool
class_name GFCellRenderer
extends RefCounted

static func build(records: Array[GFInstanceRecord], sets: Array[GFVegetationSet], cell_size: float, container: Node3D, scene_container: Node3D = null, scene_cache: Dictionary = {}) -> Dictionary:
	var sources: Dictionary = {}
	var set_map: Dictionary = {}
	var diagnostics: PackedStringArray = []
	for vegetation_set in sets:
		if vegetation_set == null:
			continue
		set_map[vegetation_set.set_id] = vegetation_set
		for source in vegetation_set.rendering_sources():
			var key := JSON.stringify([vegetation_set.set_id, source.source_id])
			if not sources.has(key):
				var resolution := source.resolve()
				sources[key] = {"source": source, "resolution": resolution}
				diagnostics.append_array(resolution.diagnostics)
	var groups: Dictionary = {}
	var by_set: Dictionary = {}
	var live_scenes: Dictionary = {}
	var record_slots: Dictionary = {}
	for record in records:
		var source_key := JSON.stringify([record.set_id, record.source_id])
		if not set_map.has(record.set_id) or not sources.has(source_key) or sources[source_key].resolution.status != GFSourceResolution.Status.READY:
			diagnostics.append("Record %s: missing/unsupported set or source '%s'; logical record retained." % [record.record_id.left(8), source_key])
			continue
		var resolved: Dictionary = sources[source_key]
		var source: GFVegetationSource = resolved.source
		var resolution: GFSourceResolution = resolved.resolution
		if resolution.scene != null and not Engine.is_editor_hint() and scene_container != null:
			var key := JSON.stringify([record.record_id, resolution.revision])
			live_scenes[key] = true
			var instance := scene_cache.get(key) as Node3D
			if not is_instance_valid(instance):
				instance = resolution.scene.instantiate() as Node3D
				if instance == null:
					diagnostics.append("Fallback root must be Node3D: " + source.source_id)
					continue
				instance.set_meta("go_flora_owned", true)
				instance.set_meta("record_id", record.record_id)
				instance.set_meta("authored_transform", instance.transform)
				# Set transform before _ready. Keep instances alive across cache rebuilds.
				instance.transform = record.local_transform * source.mesh_transform * instance.get_meta("authored_transform")
				scene_cache[key] = instance
				scene_container.add_child(instance)
			instance.transform = record.local_transform * source.mesh_transform * instance.get_meta("authored_transform")
			var visuals := instance.find_children("*", "GeometryInstance3D", true, false)
			if instance is GeometryInstance3D:
				visuals.append(instance)
			for visual in visuals:
				if not visual.has_meta("authored_visible"):
					visual.set_meta("authored_visible", visual.visible)
				visual.set_meta("record_hidden", (record.flags & 2) != 0)
				if not by_set.has(record.set_id):
					by_set[record.set_id] = []
				by_set[record.set_id].append(visual)
			continue
		if (record.flags & 2) != 0:
			continue
		var cell := GFPlacement.cell_for(record.local_transform.origin, cell_size)
		for part in resolution.parts:
			var materials: Array[int] = []
			for surface in part.mesh.get_surface_count():
				var material := part.mesh.surface_get_material(surface)
				materials.append(material.get_instance_id() if material != null else 0)
			var key := JSON.stringify([record.layer_id, record.set_id, cell.x, cell.y, source_key, resolution.revision, part.part_id, part.mesh.get_instance_id(), materials, 0])
			if not groups.has(key):
				groups[key] = {"set_id": record.set_id, "mesh": part.mesh, "part_id": part.part_id, "cell": cell, "transforms": [], "ids": []}
			var origin := Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)
			var transform := record.local_transform * part.transform
			transform.origin -= origin
			groups[key].transforms.append(transform)
			groups[key].ids.append(record.record_id)
	for key in scene_cache.keys():
		if not live_scenes.has(key):
			if is_instance_valid(scene_cache[key]):
				scene_cache[key].free()
			scene_cache.erase(key)
	for key in groups:
		var group: Dictionary = groups[key]
		var batch := MultiMeshInstance3D.new()
		batch.name = "GF_Cell_%s_%s_%s" % [group.cell.x, group.cell.y, group.set_id.validate_node_name()]
		batch.position = Vector3(group.cell.x * cell_size, 0.0, group.cell.y * cell_size)
		batch.set_meta("go_flora_owned", true)
		batch.set_meta("set_id", group.set_id)
		batch.set_meta("cell_key", group.cell)
		batch.set_meta("record_ids", group.ids)
		batch.set_meta("part_id", group.part_id)
		batch.multimesh = MultiMesh.new()
		batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		batch.multimesh.mesh = group.mesh
		batch.multimesh.instance_count = group.transforms.size()
		var bounds := AABB()
		for i in group.transforms.size():
			var transform: Transform3D = group.transforms[i]
			batch.multimesh.set_instance_transform(i, transform)
			if not record_slots.has(group.ids[i]):
				record_slots[group.ids[i]] = []
			record_slots[group.ids[i]].append([batch, i])
			var item_bounds: AABB = transform * group.mesh.get_aabb()
			bounds = item_bounds if i == 0 else bounds.merge(item_bounds)
		batch.multimesh.custom_aabb = bounds.grow(0.01)
		batch.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		container.add_child(batch)
		if not by_set.has(group.set_id):
			by_set[group.set_id] = []
		by_set[group.set_id].append(batch)
	apply_visibility(by_set, sets)
	return {"by_set": by_set, "diagnostics": diagnostics, "record_slots": record_slots}

static func apply_visibility(by_set: Dictionary, sets: Array[GFVegetationSet]) -> void:
	for vegetation_set in sets:
		if vegetation_set == null:
			continue
		for batch in by_set.get(vegetation_set.set_id, []):
			if is_instance_valid(batch):
				batch.visible = vegetation_set.enabled and batch.get_meta("authored_visible", true) and not batch.get_meta("record_hidden", false)
				batch.visibility_range_end = vegetation_set.draw_distance_m
				batch.visibility_range_end_margin = 0.0
				batch.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
