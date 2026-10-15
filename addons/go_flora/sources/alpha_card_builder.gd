@tool
class_name GFAlphaCardBuilder
extends RefCounted

static func build(card: GFAlphaCard) -> Mesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var rect := card.region().grow(-card.gutter_px)
	var uv_min := rect.position / card.texture.get_size()
	var uv_max := rect.end / card.texture.get_size()
	var count := 1 if card.mode == GFAlphaCard.Mode.SINGLE else (2 if card.mode == GFAlphaCard.Mode.CROSSED else card.radial_count)
	var card_length := card.height_m / cos(deg_to_rad(card.splay_degrees))
	for i in count:
		var basis := Basis(Vector3.UP, PI * float(i) / count) * Basis(Vector3.RIGHT, deg_to_rad(card.splay_degrees))
		var offset := vertices.size()
		for point in [Vector3(-card.width_m / 2, 0, 0), Vector3(card.width_m / 2, 0, 0), Vector3(card.width_m / 2, card_length, 0), Vector3(-card.width_m / 2, card_length, 0)]:
			vertices.append(basis * point)
			normals.append(basis * Vector3.BACK)
			tangents.append_array([basis.x.x, basis.x.y, basis.x.z, 1.0])
		uvs.append_array([Vector2(uv_min.x, uv_max.y), uv_max, Vector2(uv_max.x, uv_min.y), uv_min])
		# Godot front faces are clockwise when viewed from +Z.
		indices.append_array([offset, offset + 2, offset + 1, offset, offset + 3, offset + 2])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.resource_name = "GO_FLORA owned alpha-scissor"
	material.albedo_texture = card.texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = card.alpha_threshold
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.texture_repeat = false
	mesh.surface_set_material(0, material)
	return mesh
