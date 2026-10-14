extends SceneTree

func _initialize() -> void:
	var scene := load("res://.scratch/records.tscn") as PackedScene
	if scene == null:
		print("FAIL E3_REOPEN missing PackedScene")
		quit(1)
		return
	var fixture := scene.instantiate()
	var ok: bool = fixture.schema_version == 1 and fixture.records.size() == 2
	if ok:
		ok = fixture.records[0].id == "i-001" and fixture.records[1].seed == 43
		ok = ok and fixture.records[0].transform.origin == Vector3(1, 0, 1)
		ok = ok and fixture.records[0].normal == Vector3.UP and fixture.records[0].cell == Vector2i.ZERO
	print(("PASS" if ok else "FAIL") + " E3_REOPEN separate Godot process: typed logical data survived scene reload")
	fixture.free()
	quit(0 if ok else 1)
