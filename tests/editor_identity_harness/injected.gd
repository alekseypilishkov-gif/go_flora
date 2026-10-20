@tool
extends "res://addons/go_flora/editor/source_creator.gd"
var fault := ""
var after_write: Callable
func _write_source(path: String) -> Error:
	if fault=="save-error": return ERR_CANT_OPEN
	var e := super._write_source(path)
	if after_write.is_valid(): after_write.call()
	return e
func _load_persisted_source(path: String) -> Resource:
	if fault=="null": return null
	if fault=="wrong-type": return StandardMaterial3D.new()
	var r := super._load_persisted_source(path) as GFVegetationSource
	match fault:
		"uncached": return ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE)
		"schema": r.schema_version=2
		"id": r.source_id="wrong"
		"kind": r.kind=GFVegetationSource.Kind.ALPHA_CARD
		"display": r.display_name="wrong"
		"name": r.resource_name="wrong"
		"variant": r.variant_revision="wrong"
		"transform": r.mesh_transform.origin.x=23
		"material": r.surface_materials[0].roughness=0.9
		"mesh": (r.asset as BoxMesh).size=Vector3(9,9,9)
		"asset": r.asset=load("res://fixtures/authored_plant.tscn")
		"card": r.alpha_card.width_m=4.2
		"texture": r.alpha_card.texture=load("res://fixtures/grass.webp")
		"allow": r.allow_scene_fallback=not r.allow_scene_fallback
		"review": r.reviewed_scene_revision="wrong"
		"local": r.resource_local_to_scene=true
		"path": r.resource_path=""
	return r
