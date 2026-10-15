@tool
class_name GFBrushPreview
extends MeshInstance3D

func _init() -> void:
	set_meta("go_flora_owned", true)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	material.albedo_color = Color(0.15, 1.0, 0.55)
	material_override = material
	visible = false

func show_hit(hit: Dictionary, radius: float, erase: bool) -> void:
	var normal: Vector3 = hit.normal.normalized()
	var basis := Basis(Quaternion(Vector3.UP, normal))
	global_transform = Transform3D(basis, hit.position + normal * 0.015)
	var ring := ImmediateMesh.new()
	ring.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 65:
		var angle := TAU * float(i) / 64.0
		ring.surface_add_vertex(Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))
	ring.surface_end()
	mesh = ring
	(material_override as StandardMaterial3D).albedo_color = Color(1.0, 0.3, 0.15) if erase else Color(0.15, 1.0, 0.55)
	visible = true
