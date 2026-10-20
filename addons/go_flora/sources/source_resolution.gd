@tool
class_name GFSourceResolution
extends RefCounted

enum Status { READY, UNAVAILABLE, UNSUPPORTED, ERROR }
## UI-only classification. This deliberately does not replace Status and is not
## serialized with GFVegetationSource or placement data.
enum DiagnosticState { STANDARD, REVIEW_REQUIRED, REVISION_MISMATCH, REVIEWED_READY, HARD_UNSUPPORTED }
## Category of the concrete resolver branch that prevented resolution. UI must
## use this enum rather than trying to interpret localized diagnostic strings.
enum BlockingReason {
	NONE,
	SOURCE_CONTRACT,
	RESOURCE_UNAVAILABLE,
	LEGACY_OR_INVALID_KIND,
	STATIC_SCRIPT,
	SCENE_STRUCTURE,
	NESTED_OR_PLACEHOLDER_SCENE,
	UNSUPPORTED_NODE,
	TOOL_SCRIPT,
	UNSUPPORTED_PROPERTY,
	UNSUPPORTED_RENDER_FEATURE,
	UNSUPPORTED_MESH_FEATURE,
	REVIEW_REQUIRED,
	REVISION_MISMATCH,
	UNKNOWN,
}
var status: Status = Status.ERROR
var diagnostic_state: DiagnosticState = DiagnosticState.STANDARD
var blocking_reason: BlockingReason = BlockingReason.NONE
var diagnostics := PackedStringArray()
var parts: Array[GFSourcePart] = []
var scene: PackedScene
var revision: String = ""
var provider: String = "go_flora/builtin-v2"
var references := PackedStringArray()
var capabilities: Dictionary = {"static_parts": false, "scene_instances": false, "editor_inert_preview": false}

func fail(value: Status, message: String, reason: BlockingReason = BlockingReason.UNKNOWN) -> GFSourceResolution:
	status = value
	blocking_reason = reason
	diagnostics.append(message)
	return self

func hard_scene_failure(message: String, reason: BlockingReason) -> GFSourceResolution:
	diagnostic_state = DiagnosticState.HARD_UNSUPPORTED
	return fail(Status.UNSUPPORTED, message, reason)

func blocking_reason_label() -> String:
	match blocking_reason:
		BlockingReason.NONE:
			return "нет"
		BlockingReason.SOURCE_CONTRACT:
			return "контракт Source"
		BlockingReason.RESOURCE_UNAVAILABLE:
			return "ресурс недоступен"
		BlockingReason.LEGACY_OR_INVALID_KIND:
			return "неподдерживаемый тип Source"
		BlockingReason.STATIC_SCRIPT:
			return "скрипт на статическом Mesh"
		BlockingReason.SCENE_STRUCTURE:
			return "структура сцены"
		BlockingReason.NESTED_OR_PLACEHOLDER_SCENE:
			return "вложенная или placeholder-сцена"
		BlockingReason.UNSUPPORTED_NODE:
			return "неразрешённый тип узла"
		BlockingReason.TOOL_SCRIPT:
			return "@tool-скрипт"
		BlockingReason.UNSUPPORTED_PROPERTY:
			return "неразрешённое свойство"
		BlockingReason.UNSUPPORTED_RENDER_FEATURE:
			return "неразрешённая render-функция"
		BlockingReason.UNSUPPORTED_MESH_FEATURE:
			return "неразрешённая mesh-функция"
		BlockingReason.REVIEW_REQUIRED:
			return "требуется ручная проверка"
		BlockingReason.REVISION_MISMATCH:
			return "одобренная ревизия устарела"
		_:
			return "неизвестная причина (fail-closed)"

func diagnostic() -> String:
	return "" if status == Status.READY else "; ".join(diagnostics)
