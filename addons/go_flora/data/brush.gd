@tool
class_name GFBrush
extends Resource

@export var radius_m: float = 1.0
@export var density_per_m2: float = 6.0
@export var spacing_ratio: float = 0.5
@export var seed: int = 42
@export var yaw_min_degrees: float = 0.0
@export var yaw_max_degrees: float = 360.0
@export var scale_min: float = 0.8
@export var scale_max: float = 1.2
@export var align_normal: float = 1.0
@export var slope_min_degrees: float = 0.0
@export var slope_max_degrees: float = 60.0
@export var height_min_m: float = -1000.0
@export var height_max_m: float = 1000.0
@export var height_layer_relative: bool = false
@export var collision_mask: int = 1
@export var ray_range_m: float = 1000.0
@export var max_candidates: int = 2000
@export var include_target: NodePath
@export var exclude_target: NodePath

func diagnostic() -> String:
	for value in [radius_m, density_per_m2, spacing_ratio, yaw_min_degrees, yaw_max_degrees, scale_min, scale_max, align_normal, slope_min_degrees, slope_max_degrees, height_min_m, height_max_m, ray_range_m]:
		if not is_finite(value):
			return "Brush values must be finite."
	if density_per_m2 < 0.0:
		return "Density cannot be negative."
	if radius_m <= 0.0 or radius_m > 100.0 or ray_range_m <= 0.0 or ray_range_m > 10000.0:
		return "Radius must be (0,100] m and ray range (0,10000] m."
	if spacing_ratio < 0.1 or spacing_ratio > 2.0 or max_candidates < 1 or max_candidates > 20000:
		return "Spacing ratio must be [0.1,2]; stroke sample budget [1,20000]."
	if scale_min <= 0.0 or scale_max < scale_min or scale_max > 100.0 or yaw_max_degrees < yaw_min_degrees:
		return "Invalid yaw or positive scale range."
	if align_normal < 0.0 or align_normal > 1.0 or slope_min_degrees < 0.0 or slope_max_degrees > 180.0 or slope_max_degrees < slope_min_degrees:
		return "Invalid normal alignment or slope range."
	if height_max_m < height_min_m or collision_mask <= 0:
		return "Invalid height range or empty collision mask."
	return ""

func accepts_hit(hit: Dictionary, layer_transform: Transform3D, scene_root: Node = null) -> bool:
	if not hit.has("position") or not hit.has("normal"):
		return false
	var position: Vector3 = hit.position
	var normal: Vector3 = hit.normal
	if not position.is_finite() or not normal.is_finite() or normal.length_squared() < 0.5:
		return false
	var slope := rad_to_deg(acos(clampf(normal.normalized().dot(Vector3.UP), -1.0, 1.0)))
	var height: float = (layer_transform.affine_inverse() * position).y if height_layer_relative else position.y
	if slope < slope_min_degrees or slope > slope_max_degrees or height < height_min_m or height > height_max_m:
		return false
	if scene_root != null:
		var collider: Node = hit.get("collider") as Node
		if not include_target.is_empty():
			var included := scene_root.get_node_or_null(include_target)
			if included == null or collider == null or (included != collider and not included.is_ancestor_of(collider)):
				return false
		if not exclude_target.is_empty():
			var excluded := scene_root.get_node_or_null(exclude_target)
			if excluded != null and collider != null and (excluded == collider or excluded.is_ancestor_of(collider)):
				return false
	return true
