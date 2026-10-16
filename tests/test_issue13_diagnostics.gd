extends SceneTree

var failures := 0
var results: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + id + (" " + detail if not detail.is_empty() else ""))
	results.append({"id": id, "status": "PASS" if ok else "FAIL", "detail": detail})
	if not ok:
		failures += 1

func source_for(path: String, id: String) -> GFVegetationSource:
	var source := GFVegetationSource.new()
	source.source_id = id
	source.kind = GFVegetationSource.Kind.IMPORTED_SCENE
	source.asset = load(path)
	return source

func pack_root(child: Node) -> PackedScene:
	var root_node := Node3D.new()
	root_node.add_child(child)
	child.owner = root_node
	var packed := PackedScene.new()
	assert(packed.pack(root_node) == OK)
	root_node.free()
	return packed

func source_for_scene(scene: PackedScene, id: String) -> GFVegetationSource:
	var source := GFVegetationSource.new()
	source.source_id = id
	source.kind = GFVegetationSource.Kind.IMPORTED_SCENE
	source.asset = scene
	return source

func hard_check(source: GFVegetationSource, reason: GFSourceResolution.BlockingReason, id: String) -> void:
	var result := source.resolve()
	check(result.status == GFSourceResolution.Status.UNSUPPORTED
		and result.diagnostic_state == GFSourceResolution.DiagnosticState.HARD_UNSUPPORTED
		and result.blocking_reason == reason
		and result.scene == null and not result.capabilities.scene_instances, id, result.diagnostic())

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var standard := source_for("res://fixtures/static_plant.tscn", "diagnostic-standard")
	var standard_result := standard.resolve()
	check(standard_result.status == GFSourceResolution.Status.READY
		and standard_result.diagnostic_state == GFSourceResolution.DiagnosticState.STANDARD
		and standard_result.blocking_reason == GFSourceResolution.BlockingReason.NONE
		and standard_result.scene == null and standard_result.capabilities.static_parts, "diagnostic_standard_static_ready")

	var review_required := source_for("res://fixtures/authored_plant.tscn", "diagnostic-review")
	var review_result := review_required.resolve()
	check(review_result.status == GFSourceResolution.Status.UNSUPPORTED
		and review_result.diagnostic_state == GFSourceResolution.DiagnosticState.REVIEW_REQUIRED
		and review_result.blocking_reason == GFSourceResolution.BlockingReason.REVIEW_REQUIRED
		and review_result.scene == null and not review_result.capabilities.scene_instances, "diagnostic_review_required")

	var mismatch := source_for("res://fixtures/authored_plant.tscn", "diagnostic-mismatch")
	mismatch.allow_scene_fallback = true
	mismatch.reviewed_scene_revision = review_result.revision + "-previous"
	var mismatch_result := mismatch.resolve()
	check(mismatch_result.status == GFSourceResolution.Status.UNSUPPORTED
		and mismatch_result.diagnostic_state == GFSourceResolution.DiagnosticState.REVISION_MISMATCH
		and mismatch_result.blocking_reason == GFSourceResolution.BlockingReason.REVISION_MISMATCH
		and mismatch_result.revision == review_result.revision and mismatch_result.scene == null, "diagnostic_revision_mismatch")

	var reviewed := source_for("res://fixtures/authored_plant.tscn", "diagnostic-reviewed")
	var reviewed_before := reviewed.resolve()
	reviewed.allow_scene_fallback = true
	reviewed.reviewed_scene_revision = reviewed_before.revision
	var reviewed_result := reviewed.resolve()
	check(reviewed_result.status == GFSourceResolution.Status.READY
		and reviewed_result.diagnostic_state == GFSourceResolution.DiagnosticState.REVIEWED_READY
		and reviewed_result.blocking_reason == GFSourceResolution.BlockingReason.NONE
		and reviewed_result.scene != null and reviewed_result.capabilities.scene_instances and reviewed_result.capabilities.editor_inert_preview, "diagnostic_reviewed_ready")

	var unsupported_node := source_for_scene(pack_root(AnimationPlayer.new()), "diagnostic-unsupported-node")
	hard_check(unsupported_node, GFSourceResolution.BlockingReason.UNSUPPORTED_NODE, "diagnostic_hard_unsupported_node")

	var tool_file := FileAccess.open("res://.scratch/issue13_tool.gd", FileAccess.WRITE)
	tool_file.store_string("@tool\nextends MeshInstance3D\n")
	tool_file.close()
	var scripted_mesh := MeshInstance3D.new()
	scripted_mesh.mesh = BoxMesh.new()
	scripted_mesh.set_script(load("res://.scratch/issue13_tool.gd"))
	hard_check(source_for_scene(pack_root(scripted_mesh), "diagnostic-tool-script"), GFSourceResolution.BlockingReason.TOOL_SCRIPT, "diagnostic_hard_tool_script")

	var nested_root := Node3D.new()
	var nested_mesh := MeshInstance3D.new()
	nested_mesh.mesh = BoxMesh.new()
	nested_root.add_child(nested_mesh)
	nested_mesh.owner = nested_root
	var nested_scene := PackedScene.new()
	assert(nested_scene.pack(nested_root) == OK)
	nested_root.free()
	var nested_path := "res://.scratch/issue13_nested.tscn"
	assert(ResourceSaver.save(nested_scene, nested_path) == OK)
	var nested_instance := (load(nested_path) as PackedScene).instantiate()
	hard_check(source_for_scene(pack_root(nested_instance), "diagnostic-nested"), GFSourceResolution.BlockingReason.NESTED_OR_PLACEHOLDER_SCENE, "diagnostic_hard_nested_scene")

	var hidden_mesh := MeshInstance3D.new()
	hidden_mesh.mesh = BoxMesh.new()
	hidden_mesh.visible = false
	hard_check(source_for_scene(pack_root(hidden_mesh), "diagnostic-hidden-property"), GFSourceResolution.BlockingReason.UNSUPPORTED_PROPERTY, "diagnostic_hard_unsupported_property")

	var unavailable := GFVegetationSource.new()
	unavailable.source_id = "diagnostic-unavailable"
	unavailable.kind = GFVegetationSource.Kind.IMPORTED_SCENE
	var unavailable_result := unavailable.resolve()
	check(unavailable_result.status == GFSourceResolution.Status.UNAVAILABLE
		and unavailable_result.diagnostic_state == GFSourceResolution.DiagnosticState.STANDARD
		and unavailable_result.blocking_reason == GFSourceResolution.BlockingReason.RESOURCE_UNAVAILABLE, "diagnostic_unavailable_no_review")
	var error_source := GFVegetationSource.new()
	error_source.kind = GFVegetationSource.Kind.IMPORTED_SCENE
	var error_result := error_source.resolve()
	check(error_result.status == GFSourceResolution.Status.ERROR
		and error_result.diagnostic_state == GFSourceResolution.DiagnosticState.STANDARD
		and error_result.blocking_reason == GFSourceResolution.BlockingReason.SOURCE_CONTRACT, "diagnostic_error_no_review")

	var output := FileAccess.open("res://.scratch/issue13_diagnostics_results.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(results, "\t"))
	output.close()
	print(("PASS " if failures == 0 else "FAIL ") + "ISSUE13_DIAGNOSTICS_COMPLETE")
	quit(0 if failures == 0 else 1)
