@tool
extends EditorPlugin
var results: Array = []
var failures := 0
func _enter_tree() -> void:
 call_deferred("run")
func frames(count: int = 8) -> void:
 for i in count: await get_tree().process_frame
func check(ok: bool, id: String) -> void:
 print(("PASS " if ok else "FAIL ")+"ISSUE16_EDITOR "+id)
 results.append({"id":id,"status":"PASS" if ok else "FAIL","scope":"native Editor API; not physical GUI"})
 failures += 0 if ok else 1
func entry(s: GFVegetationSource) -> GFPaletteEntry:
 var e := GFPaletteEntry.new()
 e.source = s
 return e
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://.scratch")
 var scene: Node
 var plugin: EditorPlugin
 for i in 600:
  scene = get_editor_interface().get_edited_scene_root()
  var plugins := get_tree().get_nodes_in_group("go_flora_editor_plugin")
  if scene != null and plugins.size()==1:
   plugin = plugins[0]
   break
  await frames(1)
 check(scene != null and plugin != null,"installed")
 if scene == null or plugin == null:
  get_tree().quit(1)
  return
 var layer := scene.get_node("VegetationLayer") as VegetationLayer3D
 var d := GFVegetationLayerData.new()
 d.layer_id = "editor-warning-layer"
 var a := GFVegetationSet.new()
 a.set_id = "set-a"
 var b := GFVegetationSet.new()
 b.set_id = "set-b"
 d.sets.assign([a,b])
 var good := GFVegetationSource.new()
 good.source_id = "ready"
 good.asset = BoxMesh.new()
 var bad := GFVegetationSource.new()
 bad.source_id = "review"
 bad.display_name = "authored_plant"
 bad.kind = GFVegetationSource.Kind.IMPORTED_SCENE
 bad.asset = load("res://fixtures/authored_plant.tscn")
 var good_entry := entry(good)
 var bad_entry := entry(bad)
 a.entries.assign([good_entry,bad_entry])
 b.render_only_sources.assign([bad])
 layer.layer_data = d
 plugin._edit(layer)
 plugin.active_set = a
 plugin._refresh_sets()
 plugin._choose_source_mode(0)
 await frames()
 check(layer._get_configuration_warnings().is_empty(),"A_C_no_node_warning_unused_archive_or_empty_records")
 check(not plugin.brush_source_diagnostic().is_empty() and plugin._status.text.contains("MIX by weights") and plugin._status.text.length()<=800,"E_Mix_only_context_and_bounded_status")
 plugin._select_palette_source(good.source_id)
 await frames()
 check(plugin.brush_source_diagnostic().is_empty() and plugin._source_diagnostic_cache.is_empty(),"E_Selected_ready_not_globally_blocked")
 plugin._choose_source_mode(0)
 bad_entry.weight = 0
 await frames()
 check(plugin.brush_source_diagnostic().is_empty() and plugin._source_diagnostic_cache.is_empty() and plugin._status.text.contains("готовы"),"E_weight_zero_clears_stale_status_without_restart")
 bad_entry.weight = 1
 await frames()
 check(not plugin._source_diagnostic_cache.is_empty(),"E_weight_restores_Mix_warning")
 bad_entry.enabled = false
 await frames()
 check(plugin._source_diagnostic_cache.is_empty() and plugin._status.text.contains("готовы"),"E_disabled_clears_status")
 bad_entry.enabled = true
 await frames()
 var r := GFInstanceRecord.new()
 r.record_id = "retained-warning-record"
 r.layer_id = d.layer_id
 r.set_id = a.set_id
 r.source_id = bad.source_id
 d.records.assign([r])
 d.emit_changed()
 await frames()
 check(layer._get_configuration_warnings().size()==1 and layer._get_configuration_warnings()[0].contains("REVIEW_REQUIRED"),"D_record_failure_appears_live")
 var transform := r.local_transform
 var manager := plugin.get_undo_redo()
 var history := manager.get_history_undo_redo(manager.get_object_history_id(layer))
 manager.clear_history(manager.get_object_history_id(layer),false)
 plugin.request_palette_removal(a,bad_entry)
 await frames()
 check(is_instance_valid(plugin._remove_dialog),"palette_remove_confirmation")
 if is_instance_valid(plugin._remove_dialog):
  plugin._remove_dialog.confirmed.emit()
 await frames()
 check(a.source_by_id(bad.source_id)==null and a.render_only_sources.has(bad) and d.records.size()==1 and layer._get_configuration_warnings().size()==1,"remove_keeps_archive_records_and_real_warning")
 history.undo()
 await frames()
 check(a.source_by_id(bad.source_id)==bad and d.records[0]==r and layer._get_configuration_warnings().size()==1,"Undo_restores_same_entry_warning")
 history.redo()
 await frames()
 check(a.source_by_id(bad.source_id)==null and a.render_only_sources.has(bad) and d.records[0]==r,"Redo_keeps_exact_record_archive")
 bad.reviewed_scene_revision = bad.resolve().revision
 bad.allow_scene_fallback = true
 await frames()
 check(layer._get_configuration_warnings().is_empty() and layer.batch_count()>0 and not bad.resolve().diagnostics.is_empty(),"B_live_review_ready_removes_INFO_warning_keeps_preview_and_details")
 bad.reviewed_scene_revision = "stale-review"
 await frames()
 check(layer._get_configuration_warnings().size()==1 and layer._get_configuration_warnings()[0].contains("REVISION_MISMATCH"),"revision_change_restores_real_warning")
 check(d.records[0].record_id=="retained-warning-record" and d.records[0].local_transform==transform,"review_changes_preserve_ID_transform")
 var card := GFVegetationSource.new()
 card.source_id = "reimport-card"
 card.kind = GFVegetationSource.Kind.ALPHA_CARD
 card.alpha_card = GFAlphaCard.new()
 card.alpha_card.texture = load("res://fixtures/grass.png")
 var size := card.alpha_card.texture.get_size()
 card.alpha_card.atlas_region_px = Rect2i(Vector2i.ZERO,Vector2i(size))
 a.entries.assign([entry(card)])
 r.source_id = card.source_id
 a.emit_changed()
 d.emit_changed()
 plugin.active_set = a
 plugin._refresh_sets()
 plugin._choose_source_mode(0)
 await frames()
 check(layer._get_configuration_warnings().is_empty(),"reimport_before_ready")
 var original := FileAccess.get_file_as_bytes("res://fixtures/grass.png")
 var image := Image.new()
 image.load_png_from_buffer(original)
 image.resize(maxi(1,int(size.x)/2),maxi(1,int(size.y)/2))
 image.save_png("res://fixtures/grass.png")
 get_editor_interface().get_resource_filesystem().reimport_files(PackedStringArray(["res://fixtures/grass.png"]))
 await frames(40)
 layer.rebuild_now()
 plugin._sync_palette()
 check(layer._get_configuration_warnings().size()==1 and card.resolve().status==GFSourceResolution.Status.UNAVAILABLE and not plugin._source_diagnostic_cache.is_empty(),"actual_reimport_invalid_atlas_restores_record_and_Mix_warning")
 var restore := FileAccess.open("res://fixtures/grass.png",FileAccess.WRITE)
 restore.store_buffer(original)
 restore.close()
 get_editor_interface().get_resource_filesystem().reimport_files(PackedStringArray(["res://fixtures/grass.png"]))
 await frames(40)
 layer.rebuild_now()
 plugin._sync_palette()
 check(layer._get_configuration_warnings().is_empty() and card.resolve().status==GFSourceResolution.Status.READY and plugin._source_diagnostic_cache.is_empty(),"actual_reimport_repair_clears_warnings")
 check(d.records.size()==1 and d.records[0].record_id=="retained-warning-record" and d.records[0].local_transform==transform and b.render_only_sources.has(bad),"reimport_all_records_and_other_set_archive_preserved")
 var file := FileAccess.open("res://.scratch/issue16_editor_results.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(results,"  "))
 file.close()
 print(("PASS " if failures==0 else "FAIL ")+"ISSUE16_EDITOR_COMPLETE")
 get_tree().quit(0 if failures==0 else 1)
