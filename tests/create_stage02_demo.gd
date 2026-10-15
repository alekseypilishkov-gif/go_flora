extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func imported(path: String, id: String, title: String) -> GFVegetationSource:
	var source := GFVegetationSource.new()
	source.source_id = id
	source.display_name = title
	source.kind = GFVegetationSource.Kind.IMPORTED_SCENE
	source.asset = load(path)
	return source

func card(path: String, id: String, title: String, mode: GFAlphaCard.Mode) -> GFVegetationSource:
	var source := GFVegetationSource.new()
	source.source_id = id
	source.display_name = title
	source.kind = GFVegetationSource.Kind.ALPHA_CARD
	source.alpha_card = GFAlphaCard.new()
	source.alpha_card.texture = load(path)
	source.alpha_card.mode = mode
	return source

func palette(id: String, title: String, sources: Array[GFVegetationSource], weights: Array, distance: float) -> GFVegetationSet:
	var result := GFVegetationSet.new()
	result.set_id = id
	result.display_name = title
	result.draw_distance_m = distance
	for i in sources.size():
		var entry := GFPaletteEntry.new()
		entry.source = sources[i]
		entry.weight = weights[i]
		result.entries.append(entry)
	return result

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var scene := load("res://demo.tscn").instantiate() as Node3D
	scene.name = "GOFloraImportedAlphaDemo"
	var layer := scene.get_node("VegetationLayer") as VegetationLayer3D
	layer.layer_data = GFVegetationLayerData.new()
	layer.layer_data.layer_id = "stage02-demo"
	var model := imported("res://fixtures/original_plant.glb", "original-glb", "Original GLB · two parts / three surfaces")
	var safe := imported("res://fixtures/static_plant.tscn", "static-scene", "Static scene · material overrides")
	var authored := imported("res://fixtures/authored_plant.tscn", "authored-scene", "Reviewed scene · script + collider (runtime)")
	authored.allow_scene_fallback = true
	authored.reviewed_scene_revision = authored.resolve().revision
	var grass := card("res://fixtures/grass.png", "grass-cross", "PNG grass · crossed", GFAlphaCard.Mode.CROSSED)
	grass.alpha_card.width_m = 0.7
	grass.alpha_card.height_m = 0.8
	var flower := card("res://fixtures/flower.png", "flower-single", "PNG flower · single", GFAlphaCard.Mode.SINGLE)
	flower.alpha_card.width_m = 0.6
	flower.alpha_card.height_m = 0.95
	var radial := card("res://fixtures/grass.webp", "grass-radial", "WebP grass · radial 4", GFAlphaCard.Mode.RADIAL)
	radial.alpha_card.radial_count = 4
	radial.alpha_card.height_m = 0.65
	var atlas := card("res://fixtures/atlas.png", "atlas-flower", "Atlas flower · crossed", GFAlphaCard.Mode.CROSSED)
	atlas.alpha_card.atlas_region_px = Rect2i(140, 8, 128, 128)
	atlas.alpha_card.gutter_px = 2
	atlas.alpha_card.height_m = 0.75
	var set_a := palette("stage02-a", "A · GLB + grass + flower (0 m)", [model, grass, flower, safe], [1, 3, 2, 1], 0)
	var set_b := palette("stage02-b", "B · WebP + atlas (80 m)", [radial, atlas], [3, 1], 80)
	var set_c := palette("stage02-c", "C · reviewed scene fallback", [authored], [1], 0)
	layer.layer_data.sets.assign([set_a, set_b, set_c])
	var brush := GFBrush.new()
	for i in 112:
		var point := Vector3(-7 + (i % 14) * 0.65, 0, -4 + (i / 14) * 0.65)
		var selected := set_a if i % 2 == 0 else set_b
		layer.layer_data.records.append(GFPlacement.make_record({"position": point, "normal": Vector3.UP}, Transform3D.IDENTITY, "stage02-demo", selected, brush, "demo-ground", i, 8))
	var tilted := scene.get_node("RotatedScaledSurface") as Node3D
	var normal := (tilted.transform.basis.inverse().transposed() * Vector3.UP).normalized()
	for i in 24:
		var point: Vector3 = tilted.transform * Vector3(-1.5 + (i % 6) * 0.5, 0, -1 + (i / 6) * 0.5)
		layer.layer_data.records.append(GFPlacement.make_record({"position": point, "normal": normal}, Transform3D.IDENTITY, "stage02-demo", set_a, brush, "demo-tilt", i, 8))
	layer.layer_data.records.append(GFPlacement.make_record({"position": Vector3(-4, 0, 4), "normal": Vector3.UP}, Transform3D.IDENTITY, "stage02-demo", set_c, brush, "demo-authored", 0, 8))
	var label := scene.get_node("SurfaceLegend") as Label3D
	label.text = "GO_FLORA Stage 02 · original GLB + alpha plants\nA: mixed models / PNG · B: WebP / atlas · C: runtime script/collider\nGround and tilted blue: collision · yellow: visual only"
	var packed := PackedScene.new()
	var ok := packed.pack(scene) == OK and ResourceSaver.save(packed, "res://.scratch/stage02_demo.tscn") == OK
	print(("PASS " if ok else "FAIL ") + "STAGE02_DEMO 137 saved logical placements")
	scene.free()
	quit(0 if ok else 1)
