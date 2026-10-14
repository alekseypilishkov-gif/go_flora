extends SceneTree

func _initialize() -> void:
	var scene := Node3D.new()
	scene.name = "GOFloraDemo"
	var source_a := GFVegetationSource.new()
	source_a.source_id = "primitive-cone-v1"
	source_a.display_name = "Green cone bush"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.45
	cone.height = 1.5
	cone.radial_segments = 8
	cone.material = colored(Color(0.12, 0.65, 0.32))
	source_a.asset = cone
	source_a.mesh_transform.origin = Vector3(0, 0.75, 0)
	var source_b := GFVegetationSource.new()
	source_b.source_id = "primitive-box-v1"
	source_b.display_name = "Orange block shrub"
	var box := BoxMesh.new()
	box.size = Vector3(0.65, 0.8, 0.65)
	box.material = colored(Color(0.95, 0.42, 0.09))
	source_b.asset = box
	source_b.mesh_transform.origin = Vector3(0, 0.4, 0)
	var set_a := make_set("set-a", "A · near vegetation", source_a, source_b, 10.0)
	var set_b := make_set("set-b", "B · far vegetation", source_b, source_a, 80.0)
	var layer := VegetationLayer3D.new()
	layer.name = "VegetationLayer"
	layer.layer_data.layer_id = "demo-layer"
	layer.layer_data.sets.assign([set_a, set_b])
	scene.add_child(layer)
	add_surface(scene, "Ground", Vector3.ZERO, Vector2(18, 18), Color(0.24, 0.3, 0.37), true)
	var transformed := add_surface(scene, "RotatedScaledSurface", Vector3(5, 1.5, -3), Vector2(5, 5), Color(0.25, 0.45, 0.65), true)
	transformed.rotation_degrees = Vector3(12, 15, 22)
	transformed.scale = Vector3(1.3, 0.9, 0.8)
	add_surface(scene, "VisualOnly_NoCollision", Vector3(-12, 1, 3), Vector2(3, 3), Color(0.85, 0.72, 0.18), false)
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.shadow_enabled = true
	scene.add_child(light)
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(14, 12, 16)
	camera.basis = Basis.looking_at(-camera.position, Vector3.UP)
	camera.current = true
	camera.set_script(load("res://runtime_camera.gd"))
	scene.add_child(camera)
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.08, 0.11, 0.16)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.8, 0.85, 1.0)
	environment.environment.ambient_light_energy = 0.5
	scene.add_child(environment)
	var label := Label3D.new()
	label.name = "SurfaceLegend"
	label.position = Vector3(0, 4, -7)
	label.text = "GO_FLORA Stage 01\nGround + tilted blue surface: collision\nYellow platform: visual only\nSelect VegetationLayer; use GO_FLORA dock"
	label.font_size = 40
	label.pixel_size = 0.015
	scene.add_child(label)
	set_owners(scene, scene)
	var packed := PackedScene.new()
	var result := packed.pack(scene)
	if result == OK:
		result = ResourceSaver.save(packed, "res://demo.tscn")
	scene.free()
	print("PASS original demo scene generated" if result == OK else "FAIL demo generation")
	quit(0 if result == OK else 1)

func colored(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material

func make_set(id: String, title: String, first: GFVegetationSource, second: GFVegetationSource, distance: float) -> GFVegetationSet:
	var result := GFVegetationSet.new()
	result.set_id = id
	result.display_name = title
	result.draw_distance_m = distance
	var a := GFPaletteEntry.new()
	a.source = first
	a.weight = 3.0
	var b := GFPaletteEntry.new()
	b.source = second
	b.weight = 1.0
	result.entries.assign([a, b])
	return result

func add_surface(parent: Node, name_value: String, position: Vector3, size: Vector2, color: Color, collision: bool) -> Node3D:
	var node: Node3D = StaticBody3D.new() if collision else Node3D.new()
	node.name = name_value
	node.position = position
	parent.add_child(node)
	var mesh := MeshInstance3D.new()
	mesh.name = "SurfaceMesh"
	var plane := PlaneMesh.new()
	plane.size = size
	plane.material = colored(color)
	mesh.mesh = plane
	node.add_child(mesh)
	if collision:
		var shape := CollisionShape3D.new()
		shape.name = "SurfaceCollision"
		var box := BoxShape3D.new()
		box.size = Vector3(size.x, 0.2, size.y)
		shape.shape = box
		shape.position.y = -0.1
		node.add_child(shape)
	return node

func set_owners(node: Node, root_node: Node) -> void:
	for child in node.get_children():
		child.owner = root_node
		set_owners(child, root_node)
