@tool
class_name GFAlphaCard
extends Resource

enum Mode { SINGLE, CROSSED, RADIAL }
@export var texture: Texture2D:
	set(value):
		texture = value
		emit_changed()
@export var mode: Mode = Mode.CROSSED:
	set(value):
		mode = value
		emit_changed()
@export_range(3, 4, 1) var radial_count: int = 3:
	set(value):
		radial_count = value
		emit_changed()
@export var width_m: float = 0.6:
	set(value):
		width_m = value
		emit_changed()
@export var height_m: float = 1.0:
	set(value):
		height_m = value
		emit_changed()
@export_range(-30, 30, 1) var splay_degrees: float = 0.0:
	set(value):
		splay_degrees = value
		emit_changed()
## Empty rectangle means the entire image. Coordinates are pixels, top-left origin.
@export var atlas_region_px := Rect2i():
	set(value):
		atlas_region_px = value
		emit_changed()
## Inset the UV rectangle by this many pixels. Supply extruded atlas gutters.
@export_range(0, 32, 0.5) var gutter_px: float = 0.5:
	set(value):
		gutter_px = value
		emit_changed()
@export_range(0.01, 0.99, 0.01) var alpha_threshold: float = 0.5:
	set(value):
		alpha_threshold = value
		emit_changed()

func region() -> Rect2:
	if texture == null:
		return Rect2()
	return Rect2(Vector2.ZERO, texture.get_size()) if atlas_region_px == Rect2i() else Rect2(atlas_region_px)

func diagnostic() -> String:
	if texture == null:
		return "Alpha card: assign a project PNG/WebP Texture2D."
	var path := texture.resource_path
	if not GFSourceResolver.project_path(path) or path.get_extension().to_lower() not in ["png", "webp"] or not GFSourceResolver.resource_available(path):
		return "Alpha card: texture must reference an existing project-local PNG/WebP: %s" % path
	if mode not in [Mode.SINGLE, Mode.CROSSED, Mode.RADIAL] or radial_count < 3 or radial_count > 4:
		return "Alpha card: choose single, crossed or radial (3–4 cards)."
	if not is_finite(width_m) or not is_finite(height_m) or width_m <= 0.0 or height_m <= 0.0 or maxf(width_m, height_m) > 1000.0:
		return "Alpha card: width/height must be finite, > 0 and <= 1000 metres."
	if not is_finite(splay_degrees) or absf(splay_degrees) > 30.0 or not is_finite(alpha_threshold) or alpha_threshold <= 0.0 or alpha_threshold >= 1.0:
		return "Alpha card: invalid splay or alpha threshold (0 < threshold < 1)."
	var rect := region()
	if not Rect2(Vector2.ZERO, texture.get_size()).encloses(rect) or rect.size.x <= 0 or rect.size.y <= 0:
		return "Alpha card: atlas region is outside texture dimensions %s." % texture.get_size()
	if not is_finite(gutter_px) or gutter_px < 0.0 or rect.size.x <= 2.0 * gutter_px or rect.size.y <= 2.0 * gutter_px:
		return "Alpha card: gutter consumes the atlas region."
	var image := texture.get_image()
	if image == null or image.is_empty() or image.detect_alpha() == Image.ALPHA_NONE:
		return "Alpha card: image has no transparent texels; check texture/import alpha."
	return ""
