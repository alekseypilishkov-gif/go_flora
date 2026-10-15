@tool
extends EditorPlugin

var failed := false
var results: Array = []

func _enter_tree() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	print(("PASS " if ok else "FAIL ") + "STAGE02_EDITOR " + id)
	results.append({"id": id, "status": "PASS" if ok else "FAIL", "scope": "native Editor API; not interactive GUI"})
	failed = failed or not ok

func plane(point: Vector3, normal: Vector3) -> Dictionary:
	return {"position": point, "normal": normal}

func pending(plugin: EditorPlugin, layer: VegetationLayer3D, mode: GFStroke.Mode) -> bool:
	plugin.active_layer = layer
	plugin.active_set = layer.layer_data.sets[0]
	plugin._stroke_layer = layer
	plugin._stroke_transform = layer.global_transform
	plugin._stroke = GFStroke.new()
	if not plugin._stroke.begin(layer.layer_data, layer.global_transform, plugin.active_set, plugin.brush, 8, mode):
		return false
	plugin._stroke.feed({"position": Vector3.ZERO, "normal": Vector3.UP}, plane)
	plugin._stroke.finish_delta()
	layer.set_stroke_preview(plugin._stroke.delta.added, {})
	return true

func run() -> void:
	var scene: Node
	var plugin: EditorPlugin
	for i in 600:
		scene = get_editor_interface().get_edited_scene_root()
		var plugins := get_tree().get_nodes_in_group("go_flora_editor_plugin")
		if scene != null and plugins.size() == 1:
			plugin = plugins[0]
			break
		await get_tree().process_frame
	check(scene != null and plugin != null, "installed_enabled")
	if scene == null or plugin == null:
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var layer := scene.get_node("VegetationLayer") as VegetationLayer3D
	var sources: Array[GFVegetationSource] = []
	for path in ["res://fixtures/original_plant.glb", "res://fixtures/static_plant.tscn", "res://fixtures/authored_plant.tscn"]:
		var source := GFVegetationSource.new()
		source.source_id = path.get_file()
		source.kind = GFVegetationSource.Kind.IMPORTED_SCENE
		source.asset = load(path)
		if path.contains("authored"):
			source.allow_scene_fallback = true
			source.reviewed_scene_revision = source.resolve().revision
		sources.append(source)
	var card := GFVegetationSource.new()
	card.source_id = "editor-card"
	card.kind = GFVegetationSource.Kind.ALPHA_CARD
	card.alpha_card = GFAlphaCard.new()
	card.alpha_card.texture = load("res://fixtures/grass.png")
	sources.append(card)
	var set_a := layer.layer_data.sets[0]
	var set_b := layer.layer_data.sets[1]
	var b_distance := set_b.draw_distance_m
	var manager := plugin.get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(layer))
	for source in sources:
		history.clear_history()
		layer.layer_data.records.clear()
		var entry := GFPaletteEntry.new()
		entry.source = source
		set_a.entries.assign([entry])
		set_a.emit_changed()
		plugin._edit(layer)
		plugin.active_set = set_a
		plugin._refresh_sets()
		check(pending(plugin, layer, GFStroke.Mode.PAINT), "paint_begin_" + source.source_id)
		plugin.commit_stroke()
		var painted_ids := layer.layer_data.records.map(func(record: GFInstanceRecord) -> String: return record.record_id)
		history.undo()
		check(painted_ids.size() > 1 and layer.layer_data.records.is_empty(), "native_paint_one_undo_" + source.source_id)
		history.redo()
		check(layer.layer_data.records.map(func(record: GFInstanceRecord) -> String: return record.record_id) == painted_ids, "native_paint_redo_exact_IDs_" + source.source_id)
		history.undo()
		check(pending(plugin, layer, GFStroke.Mode.SINGLE), "single_begin_" + source.source_id)
		layer.rebuild_now()
		check(layer.batch_count() > 0 and layer.layer_data.records.is_empty() and layer._scene_cache.is_empty(), "inert_editor_preview_" + source.source_id)
		plugin.cancel_stroke()
		layer.rebuild_now()
		check(layer.batch_count() == 0, "cancel_removes_all_parts_" + source.source_id)
		pending(plugin, layer, GFStroke.Mode.SINGLE)
		plugin.commit_stroke()
		layer.rebuild_now()
		var record: GFInstanceRecord = layer.layer_data.records[0]
		var record_id := record.record_id
		var transform := record.local_transform
		check(layer.layer_data.records.size() == 1, "single_one_record_" + source.source_id)
		history.undo()
		layer.rebuild_now()
		check(layer.layer_data.records.is_empty() and layer.batch_count() == 0, "native_undo_all_parts_" + source.source_id)
		history.redo()
		layer.rebuild_now()
		check(layer.layer_data.records.size() == 1 and layer.layer_data.records[0].record_id == record_id, "native_redo_ID_" + source.source_id)
		plugin._set_distance.value = 21
		check(layer.batches_by_set[set_a.set_id].all(func(batch: GeometryInstance3D) -> bool: return batch.visibility_range_end == 21)
			and set_b.draw_distance_m == b_distance and layer.layer_data.records[0].local_transform == transform, "existing_distance_A_B_stable_" + source.source_id)
		history.undo()
		pending(plugin, layer, GFStroke.Mode.ERASE)
		plugin.commit_stroke()
		layer.rebuild_now()
		check(layer.layer_data.records.is_empty() and layer.batch_count() == 0, "native_erase_all_parts_" + source.source_id)
		history.undo()
		check(layer.layer_data.records[0].record_id == record_id and layer.layer_data.records[0].local_transform == transform, "native_erase_undo_" + source.source_id)
		var asset: Resource = source.alpha_card.texture if source.alpha_card != null else source.asset
		plugin._resources_reimported(PackedStringArray([asset.resource_path]))
		await get_tree().process_frame
		layer.rebuild_now()
		check(layer.layer_data.records[0].record_id == record_id and layer.layer_data.records[0].local_transform == transform and layer.batch_count() > 0, "reimport_callback_records_retained_" + source.source_id)
	# Real file change + Godot reimport in this disposable project (not just callback).
	var original_png := FileAccess.get_file_as_bytes("res://fixtures/grass.png")
	var image := Image.load_from_file("res://fixtures/grass.png")
	image.resize(64, 128)
	image.save_png("res://fixtures/grass.png")
	var before_mesh := card.resolve().parts[0].mesh
	var retained_id := layer.layer_data.records[0].record_id
	get_editor_interface().get_resource_filesystem().reimport_files(PackedStringArray(["res://fixtures/grass.png"]))
	for i in 30:
		await get_tree().process_frame
	layer.rebuild_now()
	check(card.alpha_card.texture.get_width() == 64 and card.resolve().parts[0].mesh != before_mesh and layer.layer_data.records[0].record_id == retained_id,
		"actual_PNG_file_reimport_invalidates_card_keeps_ID")
	var restore := FileAccess.open("res://fixtures/grass.png", FileAccess.WRITE)
	restore.store_buffer(original_png)
	restore.close()
	get_editor_interface().get_resource_filesystem().reimport_files(PackedStringArray(["res://fixtures/grass.png"]))
	for i in 10:
		await get_tree().process_frame
	var saved_entries := set_a.entries.duplicate()
	var saved_records := layer.layer_data.records.duplicate()
	var glb_source := sources[0]
	var glb_entry := GFPaletteEntry.new()
	glb_entry.source = glb_source
	set_a.entries.assign([glb_entry])
	set_a.emit_changed()
	var glb_record := GFPlacement.make_record({"position": Vector3(2, 0, 1), "normal": Vector3.UP}, Transform3D.IDENTITY,
		layer.layer_data.layer_id, set_a, plugin.brush, "glb-reimport", 0, 8)
	layer.layer_data.records.assign([glb_record])
	var glb_revision := glb_source.resolve().revision
	var glb_transform := glb_record.local_transform
	var glb_bytes := FileAccess.get_file_as_bytes("res://fixtures/original_plant.glb")
	var changed_bytes := glb_bytes.duplicate()
	var marker := "StemBrown".to_utf8_buffer()
	for i in changed_bytes.size() - marker.size():
		if changed_bytes.slice(i, i + marker.size()) == marker:
			changed_bytes[i + marker.size() - 1] = 78
			break
	var changed_glb := FileAccess.open("res://fixtures/original_plant.glb", FileAccess.WRITE)
	changed_glb.store_buffer(changed_bytes)
	changed_glb.close()
	get_editor_interface().get_resource_filesystem().reimport_files(PackedStringArray(["res://fixtures/original_plant.glb"]))
	for i in 20:
		await get_tree().process_frame
	layer.rebuild_now()
	check(glb_source.resolve().revision != glb_revision and glb_source.resolve().parts.size() == 2 and layer.layer_data.records[0].record_id == glb_record.record_id
		and layer.layer_data.records[0].local_transform == glb_transform, "actual_GLB_file_reimport_new_revision_positions_retained")
	changed_glb = FileAccess.open("res://fixtures/original_plant.glb", FileAccess.WRITE)
	changed_glb.store_buffer(glb_bytes)
	changed_glb.close()
	get_editor_interface().get_resource_filesystem().reimport_files(PackedStringArray(["res://fixtures/original_plant.glb"]))
	for i in 10:
		await get_tree().process_frame
	set_a.entries = saved_entries
	layer.layer_data.records = saved_records
	# Deleted files are detected even while a Resource reference is still loaded.
	var deleted_path := "res://.scratch/missing_scene.tscn"
	ResourceSaver.save(sources[1].asset, deleted_path)
	var missing := GFVegetationSource.new()
	missing.source_id = "missing-on-disk"
	missing.kind = GFVegetationSource.Kind.IMPORTED_SCENE
	missing.asset = load(deleted_path)
	DirAccess.remove_absolute(deleted_path)
	check(missing.resolve().status == GFSourceResolution.Status.UNAVAILABLE and missing.diagnostic().contains("missing"), "deleted_scene_file_actionable_diagnostic")
	DirAccess.remove_absolute("res://fixtures/grass.png")
	card.invalidate()
	check(card.resolve().status == GFSourceResolution.Status.UNAVAILABLE and layer.layer_data.records[0].record_id == retained_id, "deleted_texture_file_records_retained")
	restore = FileAccess.open("res://fixtures/grass.png", FileAccess.WRITE)
	restore.store_buffer(original_png)
	restore.close()
	get_editor_interface().get_resource_filesystem().reimport_files(PackedStringArray(["res://fixtures/grass.png"]))
	for i in 10:
		await get_tree().process_frame
	# Creation UI is exercised as native Controls, no synthetic mouse claim.
	plugin._show_source_details()
	check(plugin._source_details.find_children("*", "TextEdit", true, false)[0].text.contains("Revision:"), "source_diagnostics_selectable_revision")
	plugin._source_details.queue_free()
	plugin._create_source(true)
	var creator: ConfirmationDialog = plugin._creator
	creator.source.alpha_card.texture = load("res://fixtures/grass.webp")
	creator.source.display_name = "QA user grass"
	creator._refresh()
	check(not creator.get_ok_button().disabled and not creator.dialog_hide_on_ok and creator._preview.texture is AtlasTexture, "creator_WebP_UV_preview_validation")
	var count := set_a.entries.size()
	creator._save_source("res://.scratch/created_source.tres")
	await get_tree().process_frame
	check(ResourceLoader.exists("res://.scratch/created_source.tres") and set_a.entries.size() == count + 1, "creator_saved_reusable_source_added_palette")
	history.undo()
	check(set_a.entries.size() == count, "creator_add_palette_scene_undo")
	history.redo()
	check(set_a.entries.size() == count + 1, "creator_add_palette_scene_redo")
	var output := FileAccess.open("res://.scratch/editor_stage02_results.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(results, "\t"))
	output.close()
	print("NOT_RUN INTERACTIVE_GUI_QA")
	print(("PASS " if not failed else "FAIL ") + "STAGE02_EDITOR_COMPLETE")
	get_tree().quit(1 if failed else 0)
