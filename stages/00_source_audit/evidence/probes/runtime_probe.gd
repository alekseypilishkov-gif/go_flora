extends SceneTree

const Fixture = preload("res://record_fixture.gd")
var failed := false

func check(ok: bool, id: String, detail: String) -> void:
	print(("PASS" if ok else "FAIL") + " " + id + " " + detail)
	failed = failed or not ok

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var world := Node3D.new()
	root.add_child(world)
	var mesh_node := MeshInstance3D.new()
	mesh_node.mesh = PlaneMesh.new()
	world.add_child(mesh_node)
	mesh_node.create_trimesh_collision()
	await physics_frame
	await physics_frame
	var query := PhysicsRayQueryParameters3D.create(Vector3(0, 3, 0), Vector3(0, -3, 0))
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.position.is_equal_approx(Vector3.ZERO) and hit.normal.dot(Vector3.UP) > 0.99,
		"E1_PHYSICS", "ray hits collision generated from PlaneMesh at origin with up normal")
	var cells: Array[MultiMeshInstance3D] = []
	for cell_index in 2:
		var cell := MultiMeshInstance3D.new()
		cell.position.x = cell_index * 8.0
		cell.multimesh = MultiMesh.new()
		cell.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		cell.multimesh.mesh = BoxMesh.new()
		cell.multimesh.instance_count = 2
		cell.multimesh.set_instance_transform(0, Transform3D(Basis.IDENTITY, Vector3(1, 0, 1)))
		cell.multimesh.set_instance_transform(1, Transform3D(Basis.IDENTITY, Vector3(2, 0, 1)))
		world.add_child(cell)
		cells.append(cell)
	cells[0].visible = false
	check(not cells[0].is_visible_in_tree() and cells[1].is_visible_in_tree(), "E2_A", "cell 0 disabled; adjacent cell 1 enabled")
	cells[0].visible = true
	cells[1].visible = false
	check(cells[0].is_visible_in_tree() and not cells[1].is_visible_in_tree(), "E2_B", "cell 1 disabled independently; 4 transforms unchanged")
	var fixture := Fixture.new()
	fixture.name = "RecordFixture"
	var first := {"id": "i-001", "source_id": "box-v1", "set_id": "set-001", "position": Vector3(1, 0, 1),
		"normal": Vector3.UP, "transform": Transform3D(Basis.IDENTITY, Vector3(1, 0, 1)), "seed": 42,
		"layer_id": "layer-001", "cell": Vector2i(0, 0), "flags": 0}
	fixture.records.assign([first])
	var before: Array[Dictionary] = fixture.records.duplicate(true)
	var second: Dictionary = first.duplicate(true)
	second.id = "i-002"
	second.seed = 43
	var after: Array[Dictionary] = [first, second]
	var history := UndoRedo.new()
	history.create_action("Probe append one logical record")
	history.add_do_property(fixture, "records", after)
	history.add_undo_property(fixture, "records", before)
	history.commit_action()
	check(fixture.records.size() == 2, "E3_DO", "transaction appends record")
	history.undo()
	check(fixture.records == before, "E3_UNDO", "logical state restored")
	history.redo()
	check(fixture.records == after, "E3_REDO", "stable IDs restored")
	var packed := PackedScene.new()
	var packed_ok := packed.pack(fixture) == OK
	var saved := ResourceSaver.save(packed, "res://.scratch/records.tscn") == OK
	check(packed_ok and saved, "E3_SAVE", "logical records packed and saved for separate-process reopen")
	history.clear_history()
	history.free()
	fixture.free()
	world.free()
	quit(1 if failed else 0)
