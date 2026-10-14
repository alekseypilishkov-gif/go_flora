@tool
extends EditorPlugin

var last_hit: Dictionary = {}

func _enter_tree() -> void:
	set_input_event_forwarding_always_enabled()
	call_deferred("probe")

func probe() -> void:
	var fixture := Node3D.new()
	fixture.set_meta("probe_count", 0)
	var history := get_undo_redo()
	history.create_action("Stage 00 isolated metadata probe", UndoRedo.MERGE_DISABLE, fixture)
	history.add_do_method(fixture, "set_meta", "probe_count", 1)
	history.add_undo_method(fixture, "set_meta", "probe_count", 0)
	history.commit_action()
	var undo := history.get_history_undo_redo(history.get_object_history_id(fixture))
	var ok: bool = fixture.get_meta("probe_count") == 1
	undo.undo()
	ok = ok and fixture.get_meta("probe_count") == 0
	undo.redo()
	ok = ok and fixture.get_meta("probe_count") == 1
	print(("PASS" if ok else "FAIL") + " E3_EDITOR EditorUndoRedoManager do/undo/redo on isolated object")
	undo.clear_history()
	fixture.free()
	print("PASS E1_EDITOR_REGISTER EditorPlugin loaded and 3D input forwarding registered")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.own_world_3d = true
	add_child(viewport)
	var mesh := MeshInstance3D.new()
	mesh.mesh = PlaneMesh.new()
	viewport.add_child(mesh)
	mesh.create_trimesh_collision()
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.look_at_from_position(Vector3(0, 3, 3), Vector3.ZERO)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(128, 128)
	_forward_3d_gui_input(camera, event)
	var input_ok: bool = not last_hit.is_empty() and last_hit.position.length() < 0.01
	print(("PASS" if input_ok else "FAIL") + " E1_EDITOR_SYNTHETIC directly invoked 3D callback with camera-projected event hits collision-backed PlaneMesh")
	viewport.queue_free()
	print("NOT_RUN E1_EDITOR_MOUSE real editor viewport mouse delivery and picking require interactive check")

func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var origin := camera.project_ray_origin(event.position)
		var end := origin + camera.project_ray_normal(event.position) * 1000.0
		last_hit = camera.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, end))
	return EditorPlugin.AFTER_GUI_INPUT_PASS
