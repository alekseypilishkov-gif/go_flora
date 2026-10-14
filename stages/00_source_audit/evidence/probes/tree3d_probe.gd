extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	if not ClassDB.class_exists("Tree3D"):
		print("FAIL E5_IMPORT Tree3D class unavailable")
		quit(1)
		return
	var tree = ClassDB.instantiate("Tree3D")
	root.add_child(tree)
	tree.set("seed", 42)
	await process_frame
	var meshes: Array[Mesh] = []
	for child in tree.get_children(true):
		if child is MeshInstance3D and child.mesh != null:
			var detached: Mesh = child.mesh.duplicate(true)
			meshes.append(detached)
			print("E5_MESH surfaces=%s vertices=%s material_override=%s" % [detached.get_surface_count(), detached.surface_get_array_len(0), child.material_override])
	var ok := meshes.size() == 2
	for i in meshes.size():
		ok = ok and meshes[i].get_surface_count() > 0 and meshes[i].surface_get_array_len(0) > 0
		ok = ok and ResourceSaver.save(meshes[i], "res://.scratch/tree_mesh_%s.res" % i) == OK
	tree.free()
	await process_frame
	for mesh in meshes:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = 2
		ok = ok and mesh.surface_get_array_len(0) > 0 and multimesh.mesh == mesh
	print(("PASS" if ok else "FAIL") + " E5_IMPORT_EXTRACT two detached ordinary meshes saved and assigned to MultiMesh after Tree3D freed")
	print("NOT_RUN E5_VISUAL wind/material/collision and repeated editor lifecycle stress")
	quit(0 if ok else 1)
