extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var scene := load("res://demo.tscn").instantiate() as Node3D
	root.add_child(scene)
	for i in 12:
		await process_frame
		await RenderingServer.frame_post_draw
	var layer := scene.get_node("VegetationLayer") as VegetationLayer3D
	var pixels := root.get_texture().get_image()
	var ok := DisplayServer.get_name() != "headless" and layer.layer_data.records.size() == 137 and layer.batch_count() > 0 and pixels.save_png("res://.scratch/demo_gpu.png") == OK
	var camera := scene.get_node("Camera") as Camera3D
	camera.look_at_from_position(Vector3(1, 3.2, 4), Vector3(-2, 0.5, -1))
	for i in 5:
		await process_frame
		await RenderingServer.frame_post_draw
	ok = ok and root.get_texture().get_image().save_png("res://.scratch/demo_gpu_close.png") == OK
	print(("PASS " if ok else "FAIL ") + "DEMO_GPU 137 records, original GLB + alpha plants, actual viewport capture; interactive GUI NOT_RUN")
	print("GPU_ADAPTER ", RenderingServer.get_video_adapter_name(), " ", RenderingServer.get_current_rendering_driver_name())
	scene.free()
	await process_frame
	quit(0 if ok else 1)
