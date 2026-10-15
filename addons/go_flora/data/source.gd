@tool
class_name GFVegetationSource
extends Resource

enum Kind { STATIC_MESH, SCENE_UNSUPPORTED, GENERATED_UNSUPPORTED }
@export var source_id: String = "":
	set(value):
		source_id = value
		emit_changed()
@export var display_name: String = "Mesh source"
@export var kind: Kind = Kind.STATIC_MESH:
	set(value):
		kind = value
		emit_changed()
@export var asset: Resource:
	set(value):
		asset = value
		emit_changed()
@export var surface_materials: Array[Material] = []:
	set(value):
		surface_materials = value
		emit_changed()
@export var mesh_transform: Transform3D = Transform3D.IDENTITY:
	set(value):
		mesh_transform = value
		emit_changed()
@export var variant_revision: String = "static-v1":
	set(value):
		variant_revision = value
		emit_changed()

func diagnostic() -> String:
	if source_id.strip_edges().is_empty():
		return "Source needs a stable, non-empty source_id."
	if kind != Kind.STATIC_MESH or not asset is Mesh:
		return "Source '%s': Stage 01 accepts static Mesh only; scenes/GLB/generated providers are unsupported." % source_id
	var mesh := asset as Mesh
	if mesh.get_surface_count() == 0:
		return "Source '%s' has no mesh surfaces." % source_id
	if not mesh_transform.is_finite() or absf(mesh_transform.basis.determinant()) < 0.00001:
		return "Source '%s' has an invalid mesh transform." % source_id
	if not surface_materials.is_empty() and surface_materials.size() != mesh.get_surface_count():
		return "Source '%s': material overrides must contain one entry per surface (null keeps the original)." % source_id
	return ""

func resolve_mesh() -> Mesh:
	if not diagnostic().is_empty():
		return null
	var mesh := asset as Mesh
	if surface_materials.is_empty():
		return mesh
	var owned := mesh.duplicate() as Mesh
	for i in surface_materials.size():
		if surface_materials[i] != null:
			owned.surface_set_material(i, surface_materials[i])
	return owned
