extends RefCounted

static func capture(data: GFVegetationLayerData, tree: SceneTree, filename: String) -> Color:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(128, 128)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	viewport.add_child(environment)
	var layer := VegetationLayer3D.new()
	layer.layer_data = data
	viewport.add_child(layer)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0.5, 4)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3
	camera.current = true
	viewport.add_child(camera)
	for i in 6:
		await tree.process_frame
		RenderingServer.force_draw(false)
	var pixels := viewport.get_texture().get_image()
	pixels.save_png(filename)
	var color := pixels.get_pixel(64, 64)
	viewport.free()
	return color
