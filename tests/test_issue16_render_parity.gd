extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func source(id: String, scene_path: String = "") -> GFVegetationSource:
 var s := GFVegetationSource.new()
 s.source_id = id
 if scene_path.is_empty():
  s.asset = BoxMesh.new()
 else:
  s.kind = GFVegetationSource.Kind.IMPORTED_SCENE
  s.asset = load(scene_path)
  if id=="reviewed":
   s.allow_scene_fallback = true
   s.reviewed_scene_revision = s.resolve().revision
 return s
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://.scratch")
 var d := GFVegetationLayerData.new()
 d.layer_id = "parity-layer"
 var a := GFVegetationSet.new()
 a.set_id = "set-a"
 var b := GFVegetationSet.new()
 b.set_id = "set-b"
 b.draw_distance_m = 25
 var mesh := source("mesh")
 var imported := source("static-scene","res://fixtures/static_plant.tscn")
 var reviewed := source("reviewed","res://fixtures/authored_plant.tscn")
 var unavailable := source("unavailable")
 unavailable.asset = null
 var archived := source("archived-review","res://fixtures/authored_plant.tscn")
 a.render_only_sources.assign([mesh,imported,reviewed,unavailable,archived])
 b.render_only_sources.assign([mesh])
 d.sets.assign([a,b])
 for id in ["mesh","static-scene","reviewed","unavailable","mesh"]:
  var r := GFInstanceRecord.new()
  r.record_id = "parity-record-%d" % d.records.size()
  r.layer_id = d.layer_id
  r.source_id = id
  r.set_id = "set-b" if d.records.size()==4 else "set-a"
  r.local_transform = Transform3D(Basis.from_euler(Vector3(0,0.3,0)),Vector3(d.records.size()*2,0,0))
  d.records.append(r)
 var layer := VegetationLayer3D.new()
 layer.layer_data = d
 root.add_child(layer)
 layer.rebuild_now()
 var batches: Array = []
 for set_id in layer.batches_by_set:
  for batch in layer.batches_by_set[set_id]:
   if batch is MultiMeshInstance3D:
    var transforms: Array = []
    for i in batch.multimesh.instance_count: transforms.append(str(batch.multimesh.get_instance_transform(i)))
    batches.append({"set":set_id,"cell":str(batch.get_meta("cell_key")),"part":str(batch.get_meta("part_id")),"records":Array(batch.get_meta("record_ids")),"position":str(batch.position),"visible":batch.visible,"distance":batch.visibility_range_end,"bounds":str(batch.multimesh.custom_aabb),"surfaces":batch.multimesh.mesh.get_surface_count(),"transforms":transforms})
 batches.sort_custom(func(x: Dictionary,y: Dictionary) -> bool: return JSON.stringify(x)<JSON.stringify(y))
 var scenes: Array = []
 for instance in layer._scene_cache.values():
  scenes.append({"record":instance.get_meta("record_id"),"transform":str(instance.transform),"ready":instance.get_meta("authored_ready",false),"meshes":instance.find_children("*","MeshInstance3D",true,false).size(),"colliders":instance.find_children("*","StaticBody3D",true,false).size()})
 var result := {"batches":batches,"scenes":scenes,"diagnostics":Array(layer.render_diagnostics),"record_slots":layer._preview_slots.keys(),"records":d.records.size()}
 var file := FileAccess.open("res://.scratch/issue16_render_snapshot.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(result,"  "))
 file.close()
 layer.free()
 print("PASS ISSUE16_RENDER_SNAPSHOT")
 quit()
