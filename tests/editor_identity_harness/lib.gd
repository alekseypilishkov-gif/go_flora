extends RefCounted
static func configure(s: GFVegetationSource, tag: String) -> void:
	s.source_id = "new-"+tag
	s.display_name = "authored_plant"
	s.resource_name = "Authored "+tag
	s.mesh_transform = Transform3D(Basis.from_euler(Vector3(0,0.27,0)).scaled(Vector3(0.8,1.2,0.9)),Vector3(0.1,0.2,0.3))
	if tag in ["mesh","mesh-second"]:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.7,1.3,0.8)
		s.asset = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.2,0.7,0.3)
		material.roughness = 0.42
		s.surface_materials.assign([material])
	elif tag in ["png","webp"]:
		s.kind = GFVegetationSource.Kind.ALPHA_CARD
		s.alpha_card = GFAlphaCard.new()
		s.alpha_card.texture = load("res://fixtures/grass."+tag)
		s.alpha_card.width_m = 0.73
		s.alpha_card.height_m = 1.23
		s.alpha_card.mode = GFAlphaCard.Mode.RADIAL
		s.alpha_card.radial_count = 4
		s.alpha_card.splay_degrees = 7.5
		s.alpha_card.gutter_px = 0.5
		s.alpha_card.alpha_threshold = 0.43
		s.alpha_card.atlas_region_px = Rect2i(Vector2i.ZERO,Vector2i(s.alpha_card.texture.get_size()))
	else:
		s.kind = GFVegetationSource.Kind.IMPORTED_SCENE
		s.asset = load("res://fixtures/"+("original_plant.glb" if tag=="glb" else "static_plant.tscn" if tag=="packed" else "authored_plant.tscn"))
		if tag=="hard":
			var root := Node3D.new()
			var animation := AnimationPlayer.new()
			root.add_child(animation)
			animation.owner=root
			var packed := PackedScene.new()
			packed.pack(root)
			root.free()
			ResourceSaver.save(packed,"res://identity/hard_asset.tscn")
			s.asset=load("res://identity/hard_asset.tscn")
		if tag=="reviewed":
			s.reviewed_scene_revision = s.resolve().revision
			s.allow_scene_fallback = true
static func facts(s: GFVegetationSource) -> Dictionary:
	var material: StandardMaterial3D = s.surface_materials[0] if not s.surface_materials.is_empty() else null
	var c := s.alpha_card
	return {"schema":s.schema_version,"id":s.source_id,"name":s.display_name,"resource_name":s.resource_name,"kind":s.kind,
		"transform":str(s.mesh_transform),"variant":s.variant_revision,"allow":s.allow_scene_fallback,"review":s.reviewed_scene_revision,
		"asset_class":s.asset.get_class() if s.asset!=null else "","asset_external_path":s.asset.resource_path if s.asset!=null and not s.asset.is_built_in() else "",
		"mesh_size":str((s.asset as BoxMesh).size) if s.asset is BoxMesh else "",
		"material_color":str(material.albedo_color) if material!=null else "","roughness":str(material.roughness) if material!=null else "",
		"card":{} if c==null else {"texture":c.texture.resource_path,"mode":str(c.mode),"count":str(c.radial_count),"width":str(c.width_m),"height":str(c.height_m),"splay":str(c.splay_degrees),"region":str(c.atlas_region_px),"gutter":str(c.gutter_px),"threshold":str(c.alpha_threshold)}}
static func entry(s: GFVegetationSource) -> GFPaletteEntry:
	var e := GFPaletteEntry.new()
	e.source=s
	return e
static func record(d: GFVegetationLayerData, s: GFVegetationSource, set_id: String) -> void:
	var r := GFInstanceRecord.new()
	r.record_id="keep-%d" % d.records.size()
	r.layer_id=d.layer_id
	r.source_id=s.source_id
	r.source_revision=s.placement_revision()
	r.set_id=set_id
	r.local_transform=Transform3D(Basis.from_euler(Vector3(0,0.3,0)),Vector3(d.records.size(),0,0))
	r.seed=33+d.records.size()
	d.records.append(r)
static func records(d: GFVegetationLayerData) -> Array:
	var rows: Array=[]
	for r in d.records:
		rows.append([str(r.schema_version),r.record_id,r.source_id,r.set_id,r.layer_id,r.source_revision,str(r.local_transform),str(r.local_normal),str(r.seed),str(r.flags),str(r.target_path)])
	return rows
static func save_scene(scene: Node, path: String) -> Error:
	var p := PackedScene.new()
	var e := p.pack(scene)
	return e if e!=OK else ResourceSaver.save(p,path)
static func write(path: String, data: Variant) -> void:
	var f := FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"  "))
	f.close()
