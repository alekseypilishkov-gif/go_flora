@tool
class_name GFVegetationSource
extends Resource

## Values 0/1/2 are the immutable Stage 01 serialized contract.
enum Kind { STATIC_MESH, SCENE_UNSUPPORTED, GENERATED_UNSUPPORTED, IMPORTED_SCENE, ALPHA_CARD }
@export var schema_version: int = 1
@export var source_id: String = "":
	set(value):
		source_id = value
		emit_changed()
@export var display_name: String = "Mesh source":
	set(value):
		display_name = value
		emit_changed()
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
@export var alpha_card: GFAlphaCard:
	set(value):
		alpha_card = value
		emit_changed()
@export var allow_scene_fallback: bool = false:
	set(value):
		allow_scene_fallback = value
		emit_changed()
@export var reviewed_scene_revision: String = "":
	set(value):
		reviewed_scene_revision = value
		emit_changed()
var _resolved: GFSourceResolution
var _resolved_key := ""

func _init() -> void:
	changed.connect(invalidate)

func invalidate() -> void:
	_resolved = null

func placement_revision() -> String:
	if kind == Kind.STATIC_MESH:
		return variant_revision
	return (_resolved if _resolved != null else resolve()).revision

func resolve() -> GFSourceResolution:
	var materials: Array = []
	for material in surface_materials:
		materials.append(material.get_instance_id() if material != null else 0)
	var card_key: Array = []
	if alpha_card != null:
		card_key = [GFSourceResolver.fingerprint(alpha_card.texture), alpha_card.mode, alpha_card.radial_count,
			alpha_card.width_m, alpha_card.height_m, alpha_card.splay_degrees, str(alpha_card.atlas_region_px), alpha_card.gutter_px, alpha_card.alpha_threshold]
	var key := JSON.stringify([schema_version, source_id, kind, GFSourceResolver.fingerprint(asset), materials, str(mesh_transform), variant_revision, card_key, allow_scene_fallback, reviewed_scene_revision])
	if _resolved == null or _resolved_key != key:
		_resolved = GFSourceResolver.resolve(self)
		_resolved_key = key
	return _resolved

func diagnostic() -> String:
	return resolve().diagnostic()

func resolve_mesh() -> Mesh:
	# Legacy direct-Mesh API. Multi-part clients use resolve().parts.
	var result := resolve()
	return result.parts[0].mesh if result.status == GFSourceResolution.Status.READY and result.parts.size() == 1 and result.scene == null else null
