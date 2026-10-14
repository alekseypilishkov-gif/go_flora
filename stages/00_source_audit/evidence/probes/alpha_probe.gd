extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var atlas_image := Image.create(32, 16, false, Image.FORMAT_RGBA8)
	atlas_image.fill(Color(0, 0, 0, 0))
	for y in 16:
		for x in 8:
			atlas_image.set_pixel(x, y, Color(0, 1, 0, 1))
	var ok := atlas_image.save_png("res://.scratch/card.png") == OK
	ok = ok and atlas_image.save_webp("res://.scratch/card.webp", false) == OK
	for path in ["res://.scratch/card.png", "res://.scratch/card.webp"]:
		var loaded := Image.load_from_file(path)
		ok = ok and loaded.get_pixel(2, 2).a == 1.0 and loaded.get_pixel(12, 2).a == 0.0
	var texture := AtlasTexture.new()
	texture.atlas = ImageTexture.create_from_image(atlas_image)
	texture.region = Rect2(0, 0, 16, 16)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.5
	var card := QuadMesh.new()
	card.size = Vector2(2, 2)
	card.center_offset = Vector3(0, 1, 0)
	card.material = material
	ok = ok and is_equal_approx(card.get_aabb().position.y, 0.0)
	ok = ok and ResourceSaver.save(card, "res://.scratch/card.tres") == OK
	print(("PASS" if ok else "FAIL") + " E4_RESOURCE generated PNG/WebP atlas retains alpha; card ground pivot; scissor material saved")
	if DisplayServer.get_name() == "headless":
		print("NOT_RUN E4_RENDER headless dummy renderer cannot validate pixels")
		quit(0 if ok else 1)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var instance := MeshInstance3D.new()
	instance.mesh = card
	viewport.add_child(instance)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(0, 1, 3)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.4
	camera.current = true
	for mode in [BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, BaseMaterial3D.TRANSPARENCY_ALPHA_HASH]:
		material.transparency = mode
		await process_frame
		await RenderingServer.frame_post_draw
		var pixels := viewport.get_texture().get_image()
		var left := pixels.get_pixel(64, 128)
		var right := pixels.get_pixel(192, 128)
		var rendered := left.g > 0.8 and left.r < 0.1 and right.r > 0.3 and right.g < 0.1
		pixels.save_png("res://.scratch/alpha_%s_%s.png" % [RenderingServer.get_current_rendering_method(), mode])
		print(("PASS" if rendered else "FAIL") + " E4_RENDER renderer=%s mode=%s opaque=%s transparent=%s" % [RenderingServer.get_current_rendering_method(), mode, left, right])
		ok = ok and rendered
	viewport.queue_free()
	await process_frame
	quit(0 if ok else 1)
