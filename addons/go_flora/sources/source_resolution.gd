@tool
class_name GFSourceResolution
extends RefCounted

enum Status { READY, UNAVAILABLE, UNSUPPORTED, ERROR }
var status: Status = Status.ERROR
var diagnostics := PackedStringArray()
var parts: Array[GFSourcePart] = []
var scene: PackedScene
var revision: String = ""
var provider: String = "go_flora/builtin-v2"
var references := PackedStringArray()
var capabilities: Dictionary = {"static_parts": false, "scene_instances": false, "editor_inert_preview": false}

func fail(value: Status, message: String) -> GFSourceResolution:
	status = value
	diagnostics.append(message)
	return self

func diagnostic() -> String:
	return "" if status == Status.READY else "; ".join(diagnostics)
