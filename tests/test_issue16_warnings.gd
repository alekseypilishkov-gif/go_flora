extends SceneTree
var results: Array = []
var failures := 0
class FixedSource extends GFVegetationSource:
 var fixed := GFSourceResolution.new()
 func resolve() -> GFSourceResolution:
  return fixed
func _initialize() -> void:
 call_deferred("run")
func check(ok: bool, id: String) -> void:
 print(("PASS " if ok else "FAIL ")+"ISSUE16 "+id)
 results.append({"id":id,"status":"PASS" if ok else "FAIL"})
 failures += 0 if ok else 1
func scene_source(id: String, reviewed: bool = false) -> GFVegetationSource:
 var s := GFVegetationSource.new()
 s.source_id = id
 s.display_name = "authored_plant"
 s.kind = GFVegetationSource.Kind.IMPORTED_SCENE
 s.asset = load("res://fixtures/authored_plant.tscn")
 if reviewed:
  s.allow_scene_fallback = true
  s.reviewed_scene_revision = s.resolve().revision
 return s
func mesh_source(id: String) -> GFVegetationSource:
 var s := GFVegetationSource.new()
 s.source_id = id
 s.display_name = "Test mesh"
 s.asset = BoxMesh.new()
 return s
func entry(s: GFVegetationSource) -> GFPaletteEntry:
 var e := GFPaletteEntry.new()
 e.source = s
 return e
func new_data() -> GFVegetationLayerData:
 var d := GFVegetationLayerData.new()
 d.layer_id = "warning-layer"
 var a := GFVegetationSet.new()
 a.set_id = "set-a"
 var b := GFVegetationSet.new()
 b.set_id = "set-b"
 d.sets.assign([a,b])
 return d
func record(d: GFVegetationLayerData, set_id: String, source_id: String) -> GFInstanceRecord:
 var r := GFInstanceRecord.new()
 r.record_id = "record-%d" % d.records.size()
 r.layer_id = d.layer_id
 r.set_id = set_id
 r.source_id = source_id
 r.local_transform.origin = Vector3(d.records.size() % 10, 0, 0)
 d.records.append(r)
 return r
func snapshot(d: GFVegetationLayerData) -> Array:
 var rows: Array = []
 for r in d.records:
  rows.append(null if r == null else [r.schema_version,r.record_id,r.source_id,r.set_id,r.layer_id,r.source_revision,str(r.local_transform),str(r.local_normal),r.seed,r.flags,str(r.target_path)])
 return rows
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://.scratch")
 var layer := VegetationLayer3D.new()
 root.add_child(layer)
 var d := new_data()
 var reviewed := scene_source("reviewed",true)
 var review := scene_source("review-required")
 var hard := scene_source("hard")
 var hard_root := Node3D.new()
 var animation := AnimationPlayer.new()
 hard_root.add_child(animation)
 animation.owner = hard_root
 var packed := PackedScene.new()
 packed.pack(hard_root)
 hard_root.free()
 hard.asset = packed
 d.sets[0].render_only_sources.assign([reviewed,review,hard])
 layer.layer_data = d
 layer.rebuild_now()
 check(layer._get_configuration_warnings().is_empty(),"A_empty_layer_archives_no_warning")
 check(not layer.render_diagnostics.is_empty() and d.sets[0].render_only_sources.size()==3,"A_full_debug_and_archive_preserved")
 d.sets[0].entries.assign([entry(reviewed)])
 record(d,"set-a",reviewed.source_id)
 record(d,"set-a",reviewed.source_id)
 var before := snapshot(d)
 layer.rebuild_now()
 check(layer._get_configuration_warnings().is_empty() and layer._scene_cache.size()==2,"B_reviewed_runtime_scene_no_INFO_warning")
 check(not reviewed.resolve().diagnostics.is_empty() and snapshot(d)==before,"B_source_details_and_records_preserved")
 var good := mesh_source("good")
 d.records.clear()
 d.sets[0].entries.assign([entry(good)])
 record(d,"set-a",good.source_id)
 layer.rebuild_now()
 check(layer._get_configuration_warnings().is_empty() and layer.batch_count()>0,"C_unused_hard_and_review_archives_do_not_affect_valid_record")
 check(d.sets[0].render_only_sources.has(hard) and not d.sets[0].placement_entries().any(func(e: GFPaletteEntry) -> bool: return e.source == hard),"C_archive_never_deleted_or_paintable")
 d = new_data()
 var missing := mesh_source("unavailable")
 missing.asset = null
 var unsupported := mesh_source("unsupported")
 unsupported.kind = GFVegetationSource.Kind.SCENE_UNSUPPORTED
 var error_source := mesh_source("error")
 error_source.mesh_transform = Transform3D(Basis.from_scale(Vector3.ZERO),Vector3.ZERO)
 d.sets[0].render_only_sources.assign([missing,unsupported])
 d.sets[1].render_only_sources.assign([error_source,hard])
 for i in 3: record(d,"set-a",missing.source_id)
 for i in 2: record(d,"set-a",unsupported.source_id)
 record(d,"set-b",error_source.source_id)
 record(d,"set-b",hard.source_id)
 for i in 7: record(d,"set-a","missing-reference")
 for i in 5: record(d,"missing-set","lost-source")
 before = snapshot(d)
 layer.layer_data = d
 layer.rebuild_now()
 var warnings := layer._get_configuration_warnings()
 var text := "\n".join(warnings)
 check(warnings.size()==6 and snapshot(d)==before,"D_one_warning_per_Source_Set_not_per_record")
 check(text.contains("set-a") and text.contains("unavailable") and text.contains("Test mesh") and text.contains("UNAVAILABLE") and text.contains("записей: 3"),"D_unavailable_identity_category_count")
 check(text.contains("UNSUPPORTED") and text.contains("ERROR") and text.contains("HARD_UNSUPPORTED") and text.contains("MISSING_SET") and text.contains("MISSING_SOURCE"),"D_all_failure_categories_visible")
 d = new_data()
 var ready_entry := entry(good)
 var bad_entry := entry(review)
 d.sets[0].entries.assign([ready_entry,bad_entry])
 layer.layer_data = d
 layer.rebuild_now()
 check(not d.sets[0].painting_diagnostic().is_empty() and d.sets[0].painting_diagnostic(good.source_id).is_empty(),"E_Mix_blocked_Selected_ready_allowed")
 check(layer._get_configuration_warnings().is_empty(),"E_Painter_failure_does_not_mark_whole_empty_layer_broken")
 bad_entry.weight = 0
 check(d.sets[0].painting_diagnostic().is_empty(),"E_zero_weight_excludes_unreviewed_from_Mix")
 bad_entry.weight = 1
 bad_entry.enabled = false
 check(d.sets[0].painting_diagnostic().is_empty(),"E_disabled_source_excluded_from_Mix")
 d.sets[0].entries.clear()
 layer.rebuild_now()
 check(layer._get_configuration_warnings().is_empty(),"E_empty_palette_not_a_global_warning")
 d = new_data()
 missing.display_name = "Очень длинное имя\n".repeat(500)
 d.sets[0].render_only_sources.assign([missing])
 d.sets[1].render_only_sources.assign([missing])
 for i in 20000: record(d,"set-a" if i%2==0 else "set-b",missing.source_id)
 before = snapshot(d)
 layer.layer_data = d
 layer.rebuild_now()
 warnings = layer._get_configuration_warnings()
 check(warnings.size()==2 and " ".join(warnings).contains("записей: 10000"),"F_20000_records_shared_source_aggregated_per_set")
 check(Array(warnings).all(func(w: String) -> bool: return w.length()<=512 and not w.contains("\n")) and snapshot(d)==before,"F_long_names_bounded_records_unchanged")
 d = new_data()
 for i in 40:
  var s := mesh_source("missing-%03d" % i)
  s.asset = null
  d.sets[0].render_only_sources.append(s)
  record(d,"set-a",s.source_id)
  record(d,"set-a",s.source_id)
 layer.layer_data = d
 layer.rebuild_now()
 warnings = layer._get_configuration_warnings()
 check(warnings.size()==9 and " ".join(warnings).contains("Ещё 32") and " ".join(warnings).contains("записей: 64") and " ".join(warnings).length()<4608,"F_source_group_cap_reports_omitted_counts")
 var fixed := FixedSource.new()
 fixed.source_id = "typed"
 fixed.fixed.status = GFSourceResolution.Status.UNSUPPORTED
 fixed.fixed.blocking_reason = GFSourceResolution.BlockingReason.UNSUPPORTED_NODE
 fixed.fixed.diagnostics = PackedStringArray(["Everything READY; informational only"])
 d = new_data()
 d.sets[0].entries.assign([entry(fixed)])
 record(d,"set-a",fixed.source_id)
 layer.layer_data = d
 layer.rebuild_now()
 check(not layer._get_configuration_warnings().is_empty(),"typed_status_does_not_trust_benign_diagnostic_text")
 fixed.fixed.status = GFSourceResolution.Status.READY
 fixed.fixed.diagnostics = PackedStringArray(["UNAVAILABLE UNSUPPORTED dangerous words"])
 var part := GFSourcePart.new()
 part.mesh = BoxMesh.new()
 fixed.fixed.parts.assign([part])
 layer.rebuild_now()
 check(layer._get_configuration_warnings().is_empty() and layer.batch_count()>0,"typed_READY_does_not_parse_failure_words")
 d.records.append(d.records[0])
 layer.rebuild_now()
 check(not layer._get_configuration_warnings().is_empty() and layer.batch_count()==0,"corrupted_duplicate_records_not_hidden")
 d.records.pop_back()
 d.schema_version = 99
 layer.rebuild_now()
 check(not layer._get_configuration_warnings().is_empty() and d.records.size()==1,"future_schema_not_hidden_records_retained")
 d.schema_version = 1
 d.records[0].local_transform.origin.x = NAN
 layer.rebuild_now()
 check(not layer._get_configuration_warnings().is_empty(),"corrupt_transform_not_hidden")
 d = new_data()
 missing.display_name = "Unavailable QA"
 d.sets[0].render_only_sources.assign([missing,reviewed])
 record(d,"set-a",missing.source_id)
 record(d,"set-a",reviewed.source_id)
 layer.layer_data = d
 layer.rebuild_now()
 var save_root := Node3D.new()
 root.add_child(save_root)
 root.remove_child(layer)
 save_root.add_child(layer)
 layer.name = "VegetationLayer"
 layer.owner = save_root
 var save := PackedScene.new()
 check(save.pack(save_root)==OK and ResourceSaver.save(save,"res://.scratch/issue16_saved.tscn")==OK,"save_disposable_scene")
 var saved_text := FileAccess.get_file_as_string("res://.scratch/issue16_saved.tscn")
 check(not saved_text.contains("configuration_warnings ="),"warnings_channel_not_serialized")
 var expected := FileAccess.open("res://.scratch/issue16_expected.json",FileAccess.WRITE)
 expected.store_string(JSON.stringify({"records":snapshot(d),"archive_ids":d.sets[0].render_only_sources.map(func(s: GFVegetationSource) -> String: return s.source_id)}))
 expected.close()
 save_root.free()
 var file := FileAccess.open("res://.scratch/issue16_core.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(results,"  "))
 file.close()
 print(("PASS " if failures==0 else "FAIL ")+"ISSUE16_CORE_COMPLETE")
 quit(0 if failures==0 else 1)
