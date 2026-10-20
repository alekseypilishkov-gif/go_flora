extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var scene: Node3D = load("res://.scratch/issue16_saved.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 var layer := scene.get_node("VegetationLayer") as VegetationLayer3D
 layer.rebuild_now()
 var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://.scratch/issue16_expected.json"))
 var d := layer.layer_data
 var rows: Array = []
 for r in d.records:
  rows.append([r.schema_version,r.record_id,r.source_id,r.set_id,r.layer_id,r.source_revision,str(r.local_transform),str(r.local_normal),r.seed,r.flags,str(r.target_path)])
 var ids := d.sets[0].render_only_sources.map(func(s: GFVegetationSource) -> String: return s.source_id)
 for expected_row in expected.records:
  for index in [0,8,9]:
   expected_row[index] = int(expected_row[index])
 var ok := JSON.stringify(rows)==JSON.stringify(expected.records) and JSON.stringify(ids)==JSON.stringify(expected.archive_ids) and d.schema_version==1 and layer._get_configuration_warnings().size()==1 and layer._scene_cache.size()==1
 if not ok:
  print("REOPEN_DETAIL ",JSON.stringify({"rows":rows,"expected":expected.records,"ids":ids,"expected_ids":expected.archive_ids,"schema":d.schema_version,"warnings":Array(layer._get_configuration_warnings()),"scene_cache":layer._scene_cache.size()}))
 print(("PASS " if ok else "FAIL ")+"ISSUE16_REOPEN_RECORDS_ARCHIVE_WARNINGS")
 scene.free()
 quit(0 if ok else 1)
