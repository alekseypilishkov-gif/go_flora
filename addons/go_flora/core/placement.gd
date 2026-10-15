@tool
class_name GFPlacement
extends RefCounted

static func random_unit(seed: int, stroke_id: String, index: int, purpose: String) -> float:
	var bytes := JSON.stringify(["sha256-counter-v1", seed, stroke_id, index, purpose]).sha256_text()
	return float(bytes.substr(0, 8).hex_to_int()) / 4294967296.0

static func cell_for(position: Vector3, cell_size: float) -> Vector2i:
	return Vector2i(floori(position.x / cell_size), floori(position.z / cell_size))

static func choose_source(vegetation_set: GFVegetationSet, unit: float) -> GFVegetationSource:
	var ordered := vegetation_set.ordered_entries()
	var total := 0.0
	for entry in ordered:
		total += entry.weight
	var value := unit * total
	for entry in ordered:
		if entry.weight <= 0.0:
			continue
		value -= entry.weight
		if value < 0.0:
			return entry.source
	return ordered[-1].source

static func make_record(hit: Dictionary, layer_transform: Transform3D, layer_id: String, vegetation_set: GFVegetationSet, brush: GFBrush, stroke_id: String, index: int, cell_size: float) -> GFInstanceRecord:
	var source := choose_source(vegetation_set, random_unit(brush.seed, stroke_id, index, "source"))
	var normal: Vector3 = hit.normal.normalized()
	var alignment := Quaternion(Vector3.UP, normal)
	var basis := Basis(Quaternion.IDENTITY.slerp(alignment, brush.align_normal))
	var yaw := deg_to_rad(lerpf(brush.yaw_min_degrees, brush.yaw_max_degrees, random_unit(brush.seed, stroke_id, index, "yaw")))
	basis = basis * Basis(Vector3.UP, yaw)
	var scale_value := lerpf(brush.scale_min, brush.scale_max, random_unit(brush.seed, stroke_id, index, "scale"))
	var record := GFInstanceRecord.new()
	record.record_id = JSON.stringify([layer_id, vegetation_set.set_id, stroke_id, brush.seed, index]).sha256_text()
	record.layer_id = layer_id
	record.set_id = vegetation_set.set_id
	record.source_id = source.source_id
	record.source_revision = source.variant_revision
	record.stroke_id = stroke_id
	record.seed = brush.seed
	record.candidate_index = index
	record.local_transform = layer_transform.affine_inverse() * Transform3D(basis.scaled(Vector3.ONE * scale_value), hit.position)
	record.local_normal = (layer_transform.basis.transposed() * normal).normalized()
	record.cell_key = cell_for(record.local_transform.origin, cell_size)
	record.target_path = hit.get("target_path", NodePath())
	return record
