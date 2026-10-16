@tool
class_name GFSourceResolver
extends RefCounted

const MAX_NODES := 256
const STATIC_TYPES := ["Node3D", "MeshInstance3D"]
const FALLBACK_TYPES := ["Node3D", "MeshInstance3D", "StaticBody3D", "CollisionShape3D"]
const STATIC_PROPERTIES := ["transform", "position", "rotation", "rotation_degrees", "scale", "script", "visible", "mesh", "material_override", "skin", "skeleton", "material_overlay", "editor_description"]

static func project_path(path: String) -> bool:
	return path.begins_with("res://") and path == path.simplify_path() and not path.contains("..")

static func resource_available(path: String) -> bool:
	if not ResourceLoader.exists(path):
		return false
	# In the editor a loaded Resource may outlive its deleted source file.
	# Exported PCKs may contain only remapped/imported payloads.
	return not Engine.is_editor_hint() or FileAccess.file_exists(path)

static func fingerprint(resource: Resource) -> String:
	if resource == null:
		return "missing"
	var path := resource.resource_path.get_slice("::", 0)
	if not project_path(path):
		return str(resource.get_instance_id())
	return _path_fingerprint(path, {})

static func _path_fingerprint(path: String, visited: Dictionary) -> String:
	if visited.has(path):
		return ""
	visited[path] = true
	if not FileAccess.file_exists(path):
		return "missing-or-remapped:" + path
	var hashes: Array = [[path, FileAccess.get_sha256(path)]]
	for dependency in ResourceLoader.get_dependencies(path):
		var dep_path: String = dependency.get_slice("::", dependency.get_slice_count("::") - 1)
		if not project_path(dep_path):
			continue
		if not visited.has(dep_path):
			hashes.append([dep_path, _path_fingerprint(dep_path, visited)])
	return JSON.stringify(hashes).sha256_text()

static func resolve(source: GFVegetationSource) -> GFSourceResolution:
	var result := GFSourceResolution.new()
	result.revision = source.variant_revision
	if source.source_id.strip_edges().is_empty():
		return result.fail(GFSourceResolution.Status.ERROR, "Source needs a stable, non-empty source_id.", GFSourceResolution.BlockingReason.SOURCE_CONTRACT)
	if source.schema_version != 1:
		return result.fail(GFSourceResolution.Status.UNSUPPORTED, "Source schema %d unsupported; records retained." % source.schema_version, GFSourceResolution.BlockingReason.SOURCE_CONTRACT)
	if not source.mesh_transform.is_finite() or absf(source.mesh_transform.basis.determinant()) < 0.00001:
		return result.fail(GFSourceResolution.Status.ERROR, "Source '%s' has an invalid mesh transform." % source.source_id, GFSourceResolution.BlockingReason.SOURCE_CONTRACT)
	if source.kind in [GFVegetationSource.Kind.SCENE_UNSUPPORTED, GFVegetationSource.Kind.GENERATED_UNSUPPORTED]:
		return result.fail(GFSourceResolution.Status.UNSUPPORTED, "Legacy unsupported kind %d retained; explicitly select Imported Scene or Alpha Card." % source.kind, GFSourceResolution.BlockingReason.LEGACY_OR_INVALID_KIND)
	if source.kind != GFVegetationSource.Kind.STATIC_MESH and not source.surface_materials.is_empty():
		return result.fail(GFSourceResolution.Status.UNSUPPORTED, "Surface Materials is for direct Mesh sources. Edit imported scene materials through Godot import/source scene; alpha cards own their generated material.", GFSourceResolution.BlockingReason.SOURCE_CONTRACT)
	if source.kind == GFVegetationSource.Kind.ALPHA_CARD:
		if source.alpha_card == null:
			return result.fail(GFSourceResolution.Status.UNAVAILABLE, "Assign an AlphaCard resource.", GFSourceResolution.BlockingReason.RESOURCE_UNAVAILABLE)
		var reason := source.alpha_card.diagnostic()
		if not reason.is_empty():
			return result.fail(GFSourceResolution.Status.UNAVAILABLE, reason, GFSourceResolution.BlockingReason.RESOURCE_UNAVAILABLE)
		result.references.append(source.alpha_card.texture.resource_path)
		var card := source.alpha_card
		result.revision = source.variant_revision + ":" + JSON.stringify([fingerprint(card.texture), card.mode, card.radial_count, card.width_m, card.height_m,
			card.splay_degrees, str(card.atlas_region_px), card.gutter_px, card.alpha_threshold, str(source.mesh_transform)]).sha256_text()
		_add_part(result, "card", GFAlphaCardBuilder.build(source.alpha_card), source.mesh_transform)
	elif source.kind == GFVegetationSource.Kind.STATIC_MESH:
		if not source.asset is Mesh:
			return result.fail(GFSourceResolution.Status.UNAVAILABLE, "Source '%s': static Mesh is missing or has the wrong resource type." % source.source_id, GFSourceResolution.BlockingReason.RESOURCE_UNAVAILABLE)
		var mesh := source.asset as Mesh
		if not mesh.resource_path.is_empty():
			result.references.append(mesh.resource_path)
		if mesh.get_script() != null:
			return result.fail(GFSourceResolution.Status.UNSUPPORTED, "Scripted Mesh resources require review; static source blocked.", GFSourceResolution.BlockingReason.STATIC_SCRIPT)
		if not mesh.resource_path.is_empty() and not project_path(mesh.resource_path.get_slice("::", 0)):
			return result.fail(GFSourceResolution.Status.UNAVAILABLE, "Mesh reference is outside project.", GFSourceResolution.BlockingReason.RESOURCE_UNAVAILABLE)
		if not source.surface_materials.is_empty() and source.surface_materials.size() != mesh.get_surface_count():
			return result.fail(GFSourceResolution.Status.ERROR, "Material overrides must contain one entry per surface.", GFSourceResolution.BlockingReason.SOURCE_CONTRACT)
		if not source.surface_materials.is_empty():
			mesh = mesh.duplicate() as Mesh
			for i in source.surface_materials.size():
				if source.surface_materials[i] != null:
					mesh.surface_set_material(i, source.surface_materials[i])
		_add_part(result, "mesh", mesh, source.mesh_transform)
	elif source.kind == GFVegetationSource.Kind.IMPORTED_SCENE:
		if not source.asset is PackedScene:
			return result.fail(GFSourceResolution.Status.UNAVAILABLE, "Imported scene missing: assign project GLB/GLTF or PackedScene.", GFSourceResolution.BlockingReason.RESOURCE_UNAVAILABLE)
		if not source.asset.resource_path.is_empty() and (not project_path(source.asset.resource_path) or not resource_available(source.asset.resource_path)):
			return result.fail(GFSourceResolution.Status.UNAVAILABLE, "Scene path missing or outside project: " + source.asset.resource_path, GFSourceResolution.BlockingReason.RESOURCE_UNAVAILABLE)
		result.revision = source.variant_revision + ":" + fingerprint(source.asset)
		result.references.append(source.asset.resource_path)
		_classify(source, result)
		if result.status == GFSourceResolution.Status.UNSUPPORTED:
			return result
	else:
		return result.fail(GFSourceResolution.Status.UNSUPPORTED, "Unknown source kind %d; data retained." % source.kind, GFSourceResolution.BlockingReason.LEGACY_OR_INVALID_KIND)
	if result.parts.is_empty() and result.scene == null:
		return result.fail(GFSourceResolution.Status.UNSUPPORTED, "Source has no eligible mesh surfaces.", GFSourceResolution.BlockingReason.UNSUPPORTED_MESH_FEATURE)
	result.status = GFSourceResolution.Status.READY
	result.capabilities.static_parts = result.scene == null
	return result

static func _add_part(result: GFSourceResolution, id: String, mesh: Mesh, transform: Transform3D) -> void:
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var part := GFSourcePart.new()
	part.part_id = id
	part.mesh = mesh
	part.transform = transform
	part.bounds = transform * mesh.get_aabb()
	result.parts.append(part)

static func _classify(source: GFVegetationSource, result: GFSourceResolution) -> void:
	# SceneState is inspected without instantiate(): unknown scripts never run for a preview.
	var packed := source.asset as PackedScene
	var state := packed.get_state()
	if state.get_base_scene_state() != null or state.get_node_count() == 0 or state.get_node_count() > MAX_NODES:
		result.hard_scene_failure("Empty, inherited or >256-node scene requires review; not instantiated.", GFSourceResolution.BlockingReason.SCENE_STRUCTURE)
		return
	var transforms: Dictionary = {"": source.mesh_transform, ".": source.mesh_transform}
	var semantics := PackedStringArray()
	var safe_fallback := true
	for i in state.get_node_count():
		var path := str(state.get_node_path(i))
		var type := str(state.get_node_type(i))
		if state.get_node_instance(i) != null or state.is_node_instance_placeholder(i):
			result.hard_scene_failure("Nested scene/placeholder at %s requires review; not instantiated." % path, GFSourceResolution.BlockingReason.NESTED_OR_PLACEHOLDER_SCENE)
			return
		if type not in STATIC_TYPES:
			semantics.append("%s: %s" % [path, type])
		if type not in FALLBACK_TYPES:
			safe_fallback = false
			if result.blocking_reason == GFSourceResolution.BlockingReason.NONE:
				result.blocking_reason = GFSourceResolution.BlockingReason.UNSUPPORTED_NODE
		var props: Dictionary = {}
		if not state.get_node_groups(i).is_empty():
			semantics.append(path + ": authored groups")
		for j in state.get_node_property_count(i):
			props[str(state.get_node_property_name(i, j))] = state.get_node_property_value(i, j)
		if props.get("script") != null:
			semantics.append("%s: script" % path)
			var script: Script = props.script
			if script.is_tool():
				safe_fallback = false
				if result.blocking_reason == GFSourceResolution.BlockingReason.NONE:
					result.blocking_reason = GFSourceResolution.BlockingReason.TOOL_SCRIPT
		if type in STATIC_TYPES:
			var script_properties: Array = []
			if props.get("script") is Script:
				for property in (props.script as Script).get_script_property_list():
					script_properties.append(str(property.name))
			for property in props:
				if property in STATIC_PROPERTIES or property.begins_with("surface_material_override/") or property.begins_with("metadata/"):
					continue
				semantics.append("%s: authored property %s" % [path, property])
				if property not in script_properties:
					safe_fallback = false
					if result.blocking_reason == GFSourceResolution.BlockingReason.NONE:
						result.blocking_reason = GFSourceResolution.BlockingReason.UNSUPPORTED_PROPERTY
		if props.get("skin") != null or props.get("skeleton", NodePath()) != NodePath() or props.get("material_overlay") != null:
			semantics.append("%s: skin/skeleton/overlay" % path)
			safe_fallback = false
			if result.blocking_reason == GFSourceResolution.BlockingReason.NONE:
				result.blocking_reason = GFSourceResolution.BlockingReason.UNSUPPORTED_MESH_FEATURE
		for property in ["top_level", "visibility_parent", "visibility_range_end", "visibility_range_begin", "lod_bias", "extra_cull_margin", "custom_aabb", "cast_shadow", "layers", "gi_mode", "ignore_occlusion_culling"]:
			if props.has(property):
				semantics.append("%s: authored %s" % [path, property])
				safe_fallback = false
				if result.blocking_reason == GFSourceResolution.BlockingReason.NONE:
					result.blocking_reason = GFSourceResolution.BlockingReason.UNSUPPORTED_RENDER_FEATURE
		var local: Transform3D = props.get("transform", Transform3D.IDENTITY)
		if props.has("position") or props.has("rotation") or props.has("rotation_degrees") or props.has("scale"):
			if props.has("transform"):
				result.hard_scene_failure("Mixed transform and component aliases at " + path, GFSourceResolution.BlockingReason.SCENE_STRUCTURE)
				return
			var rotation: Vector3 = props.get("rotation", props.get("rotation_degrees", Vector3.ZERO) * PI / 180.0)
			local = Transform3D(Basis.from_euler(rotation).scaled(props.get("scale", Vector3.ONE)), props.get("position", Vector3.ZERO))
		if not local.is_finite() or absf(local.basis.determinant()) < 0.00001:
			result.hard_scene_failure("Non-invertible transform at " + path, GFSourceResolution.BlockingReason.SCENE_STRUCTURE)
			return
		var parent_path := str(state.get_node_path(i, true))
		if not transforms.has(parent_path):
			result.hard_scene_failure("Missing/out-of-order parent transform at " + path, GFSourceResolution.BlockingReason.SCENE_STRUCTURE)
			return
		var accumulated: Transform3D = transforms.get(parent_path, source.mesh_transform) * local
		transforms[path] = accumulated
		if props.get("visible", true) == false:
			semantics.append(path + ": authored hidden node")
			safe_fallback = false
			if result.blocking_reason == GFSourceResolution.BlockingReason.NONE:
				result.blocking_reason = GFSourceResolution.BlockingReason.UNSUPPORTED_PROPERTY
		if type == "MeshInstance3D":
			var mesh: Mesh = props.get("mesh")
			if mesh == null or (mesh is ArrayMesh and mesh.get_blend_shape_count() > 0):
				result.hard_scene_failure("Missing mesh or blend shapes at " + path, GFSourceResolution.BlockingReason.UNSUPPORTED_MESH_FEATURE)
				return
			var owned: Mesh = mesh
			for surface in mesh.get_surface_count():
				var material: Material = props.get("material_override")
				if material == null:
					material = props.get("surface_material_override/%d" % surface)
				if material == null:
					material = mesh.surface_get_material(surface)
				if material != mesh.surface_get_material(surface):
					if owned == mesh:
						owned = mesh.duplicate() as Mesh
					owned.surface_set_material(surface, material)
			_add_part(result, path, owned, accumulated)
	if state.get_connection_count() > 0:
		semantics.append("authored signal connections")
	if semantics.is_empty():
		return
	result.diagnostics.append("Scene semantics: " + "; ".join(semantics))
	if not safe_fallback:
		if result.blocking_reason == GFSourceResolution.BlockingReason.NONE:
			result.blocking_reason = GFSourceResolution.BlockingReason.UNKNOWN
		result.diagnostic_state = GFSourceResolution.DiagnosticState.HARD_UNSUPPORTED
		result.fail(GFSourceResolution.Status.UNSUPPORTED, "Unsupported scene features; fallback allowlist is Node3D/MeshInstance3D/StaticBody3D/CollisionShape3D and reviewed non-tool scripts. Not instantiated.", result.blocking_reason)
		return
	if not source.allow_scene_fallback or source.reviewed_scene_revision != result.revision:
		if not source.reviewed_scene_revision.is_empty() and source.reviewed_scene_revision != result.revision:
			result.diagnostic_state = GFSourceResolution.DiagnosticState.REVISION_MISMATCH
			result.fail(GFSourceResolution.Status.UNSUPPORTED, "Review scene and scripts, then enable fallback and set Reviewed Scene Revision to '%s'. Revision changes require review again." % result.revision, GFSourceResolution.BlockingReason.REVISION_MISMATCH)
		else:
			result.diagnostic_state = GFSourceResolution.DiagnosticState.REVIEW_REQUIRED
			result.fail(GFSourceResolution.Status.UNSUPPORTED, "Review scene and scripts, then enable fallback and set Reviewed Scene Revision to '%s'. Revision changes require review again." % result.revision, GFSourceResolution.BlockingReason.REVIEW_REQUIRED)
		return
	result.scene = packed
	result.capabilities.scene_instances = true
	result.capabilities.editor_inert_preview = true
	result.diagnostic_state = GFSourceResolution.DiagnosticState.REVIEWED_READY
	result.diagnostics.append("Reviewed scene fallback: runtime instances preserve scripts/colliders; expensive, not MultiMesh. Editor uses inert mesh preview only.")
