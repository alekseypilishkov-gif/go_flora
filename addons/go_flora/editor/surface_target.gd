@tool
class_name GFSurfaceTarget
extends RefCounted

static func cast_ray(world: World3D, start: Vector3, end: Vector3, brush: GFBrush, layer: VegetationLayer3D, scene_root: Node) -> Dictionary:
	if world == null:
		return {}
	var query := PhysicsRayQueryParameters3D.create(start, end, brush.collision_mask)
	query.collide_with_areas = false
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty() or not brush.accepts_hit(hit, layer.global_transform, scene_root):
		return {}
	var collider := hit.collider as Node
	if collider == null or collider.has_meta("go_flora_owned") or layer.is_ancestor_of(collider):
		return {}
	hit["target_path"] = scene_root.get_path_to(collider) if scene_root != null else NodePath()
	return hit

static func from_camera(camera: Camera3D, position: Vector2, brush: GFBrush, layer: VegetationLayer3D, scene_root: Node) -> Dictionary:
	var origin := camera.project_ray_origin(position)
	return cast_ray(camera.get_world_3d(), origin, origin + camera.project_ray_normal(position) * brush.ray_range_m, brush, layer, scene_root)

static func project_sample(point: Vector3, normal: Vector3, world: World3D, brush: GFBrush, layer: VegetationLayer3D, scene_root: Node) -> Dictionary:
	var reach := minf(brush.ray_range_m * 0.5, maxf(1.0, brush.radius_m * 2.0))
	return cast_ray(world, point + normal * reach, point - normal * reach, brush, layer, scene_root)
