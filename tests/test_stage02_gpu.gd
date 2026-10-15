extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("FAIL GPU probe needs an actual rendering device")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://.scratch/gpu")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.6, 0, 0.1)
	viewport.add_child(environment)
	var instance := MeshInstance3D.new()
	viewport.add_child(instance)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.current = true
	var rows: Array = []
	var ok := true
	for extension in ["png", "webp"]:
		var card := GFAlphaCard.new()
		card.texture = load("res://fixtures/pixel_atlas." + extension)
		card.mode = GFAlphaCard.Mode.SINGLE
		card.width_m = 2
		card.height_m = 2
		card.atlas_region_px = Rect2i(0, 0, 72, 64)
		card.gutter_px = 8
		instance.mesh = GFAlphaCardBuilder.build(card)
		var material := instance.mesh.surface_get_material(0) as StandardMaterial3D
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for distance in [3.0, 12.0, 24.0]:
			camera.position = Vector3(0, 1, distance)
			for i in 5:
				await process_frame
				await RenderingServer.frame_post_draw
			var pixels := viewport.get_texture().get_image()
			var left_pos := Vector2i(camera.unproject_position(Vector3(-0.6, 1, 0)))
			var right_pos := Vector2i(camera.unproject_position(Vector3(0.6, 1, 0)))
			var left := pixels.get_pixelv(left_pos)
			var right := pixels.get_pixelv(right_pos)
			var passed := left.g > 0.75 and left.r < 0.15 and right.r > 0.3 and right.g < 0.12 and right.a > 0.95
			var name_value := "%s_%s_%dm" % [RenderingServer.get_current_rendering_method(), extension, distance]
			pixels.save_png("res://.scratch/gpu/" + name_value + ".png")
			var row := {"id": name_value, "status": "PASS" if passed else "FAIL", "opaque": str(left), "transparent_background": str(right),
				"filter": "linear_with_mipmaps", "mipmaps": card.texture.get_image().has_mipmaps(), "gutter_inset_px": 8,
				"opaque_pixel": str(left_pos), "transparent_pixel": str(right_pos)}
			rows.append(row)
			print(("PASS " if passed else "FAIL ") + "GPU_ALPHA_SCISSOR " + JSON.stringify(row))
			ok = ok and passed
	var result := {"checks": rows, "adapter": RenderingServer.get_video_adapter_name(), "driver": RenderingServer.get_current_rendering_driver_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "display": DisplayServer.get_name(), "engine": Engine.get_version_info(), "scope": "actual GPU pixels; no interactive mouse QA"}
	var output := FileAccess.open("res://.scratch/gpu/results.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "\t"))
	output.close()
	viewport.free()
	await process_frame
	print(("PASS " if ok else "FAIL ") + "GPU_COMPLETE")
	quit(0 if ok else 1)
