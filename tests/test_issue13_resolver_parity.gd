extends SceneTree

## This probe intentionally uses only the pre-Issue-13 resolver contract. The
## runner executes it against pinned main and the candidate, then compares the
## JSON envelopes byte-for-value (except no diagnostic fields are present).

func _initialize() -> void:
	call_deferred("run")

func source_for(path: String, id: String) -> GFVegetationSource:
	var source := GFVegetationSource.new()
	source.source_id = id
	source.kind = GFVegetationSource.Kind.IMPORTED_SCENE
	source.asset = load(path)
	return source

func row(id: String, result: GFSourceResolution) -> Dictionary:
	return {
		"id": id,
		"status": result.status,
		"revision": result.revision,
		"parts": result.parts.size(),
		"scene": result.scene != null,
		"capabilities": result.capabilities,
	}

func unsupported_scene() -> PackedScene:
	var root_node := Node3D.new()
	var animation := AnimationPlayer.new()
	root_node.add_child(animation)
	animation.owner = root_node
	var packed := PackedScene.new()
	assert(packed.pack(root_node) == OK)
	root_node.free()
	return packed

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var static_scene := source_for("res://fixtures/static_plant.tscn", "parity-static")
	var review := source_for("res://fixtures/authored_plant.tscn", "parity-review")
	var reviewed := source_for("res://fixtures/authored_plant.tscn", "parity-reviewed")
	var review_before := reviewed.resolve()
	reviewed.allow_scene_fallback = true
	reviewed.reviewed_scene_revision = review_before.revision
	var hard := GFVegetationSource.new()
	hard.source_id = "parity-hard"
	hard.kind = GFVegetationSource.Kind.IMPORTED_SCENE
	hard.asset = unsupported_scene()
	var unavailable := GFVegetationSource.new()
	unavailable.source_id = "parity-unavailable"
	unavailable.kind = GFVegetationSource.Kind.IMPORTED_SCENE
	var rows := [
		row("static", static_scene.resolve()),
		row("review", review.resolve()),
		row("reviewed", reviewed.resolve()),
		row("hard", hard.resolve()),
		row("unavailable", unavailable.resolve()),
	]
	var output := FileAccess.open("res://.scratch/issue13_resolver_parity.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(rows, "\t"))
	output.close()
	print("PASS ISSUE13_RESOLVER_PARITY")
	quit()
