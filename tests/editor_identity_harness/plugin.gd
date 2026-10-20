@tool
extends EditorPlugin
const I=preload("res://tests/editor_identity_harness/lib.gd")
const Injected=preload("res://tests/editor_identity_harness/injected.gd")
var rows: Array=[]
var failed:=false
var plugin: EditorPlugin
var layer: VegetationLayer3D
var scene: Node
var d: GFVegetationLayerData
func _enter_tree() -> void:
	call_deferred("run")
func frames(n: int=8) -> void:
	for i in n: await get_tree().process_frame
func check(ok: bool,id: String,facts: Dictionary={}) -> void:
	rows.append({"id":id,"status":"PASS" if ok else "FAIL","facts":facts})
	print(("PASS " if ok else "FAIL ")+"ISSUE18 "+id)
	failed=failed or not ok
func activate(set: GFVegetationSet) -> void:
	plugin._edit(layer)
	plugin.active_set=set
	plugin._refresh_sets()
func injected(tag: String, fault: String="") -> ConfirmationDialog:
	var c=Injected.new()
	get_editor_interface().get_base_control().add_child(c)
	c.setup(tag in ["png","webp"])
	I.configure(c.source,tag)
	c.fault=fault
	c.source_saved.connect(plugin._add_created_source.bind(layer,d.sets[0]),CONNECT_ONE_SHOT)
	return c
func run() -> void:
	for i in 600:
		scene=get_editor_interface().get_edited_scene_root()
		var plugins=get_tree().get_nodes_in_group("go_flora_editor_plugin")
		if scene!=null and plugins.size()==1:
			plugin=plugins[0]
			break
		await frames(1)
	if scene==null or plugin==null:
		check(false,"installed")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://identity")
	layer=scene.get_node("VegetationLayer") as VegetationLayer3D
	d=GFVegetationLayerData.new()
	d.layer_id="identity-layer"
	for index in 2:
		var s=GFVegetationSet.new()
		s.set_id="set-%d" % index
		d.sets.append(s)
	var legacy=GFVegetationSource.new()
	I.configure(legacy,"reviewed")
	legacy.source_id="legacy-id"
	d.sets[0].entries.assign([I.entry(legacy)])
	d.sets[1].render_only_sources.assign([legacy])
	I.record(d,legacy,"set-0")
	var external_legacy=GFVegetationSource.new()
	I.configure(external_legacy,"review-required")
	external_legacy.source_id=legacy.source_id
	ResourceSaver.save(external_legacy,"res://identity/legacy_independent.tres")
	layer.layer_data=d
	activate(d.sets[0])
	var legacy_before=I.facts(legacy)
	var created: Array=[]
	var expected: Array=[]
	for tag in ["mesh","mesh-second","glb","packed","png","webp","review-required","reviewed","hard"]:
		activate(d.sets[0])
		plugin._create_source(tag in ["png","webp"])
		await frames()
		var c: ConfirmationDialog=plugin._creator
		I.configure(c.source,tag)
		var draft: GFVegetationSource=c.source
		var before=I.facts(draft)
		var emitted: Array=[]
		c.source_saved.connect(func(s: GFVegetationSource) -> void: emitted.append(s))
		var path: String="res://identity/"+tag+".tres"
		c._save_source(path)
		await frames()
		var canonical=load(path) as GFVegetationSource
		var ok: bool=emitted.size()==1 and emitted[0]==canonical and emitted[0]!=draft and canonical.resource_path==path
		check(ok,"Creator_canonical_"+tag,{"path":canonical.resource_path,"emitted_is_draft":emitted.size()==1 and emitted[0]==draft})
		check(I.facts(canonical)==before,"all_persisted_fields_"+tag,{"expected":before,"actual":I.facts(canonical)})
		check(d.sets[0].entries[-1].source==canonical and get_editor_interface().get_inspector().get_edited_object()==canonical,"palette_and_Inspector_exact_"+tag)
		d.sets[1].entries.append(I.entry(canonical))
		I.record(d,canonical,"set-0")
		I.record(d,canonical,"set-1")
		created.append(canonical)
		expected.append({"path":path,"fields":before.duplicate(true)})
	check(created[0].display_name==created[1].display_name and created[0].source_id!=created[1].source_id and created[0]!=created[1],"same_display_name_distinct_objects_and_ids")
	var before_records=I.records(d)
	var manager=plugin.get_undo_redo()
	var history=manager.get_history_undo_redo(manager.get_object_history_id(layer))
	history.undo()
	check(d.sets[0].source_by_id(created[-1].source_id)==null and I.records(d)==before_records,"append_Undo_records_unchanged")
	history.redo()
	check(d.sets[0].source_by_id(created[-1].source_id)==created[-1] and I.records(d)==before_records,"append_Redo_same_canonical")
	plugin.request_palette_removal(d.sets[0],d.sets[0].entries[1])
	await frames()
	plugin._remove_dialog.confirmed.emit()
	await frames()
	check(d.sets[0].render_only_sources.has(created[0]) and I.records(d)==before_records,"removal_keeps_external_archive_and_records")
	history.undo()
	await frames()
	check(d.sets[0].entries[1].source==created[0] and I.records(d)==before_records,"removal_Undo_same_source")
	for action in ["cancel","esc","x"]:
		var c=injected("mesh")
		var emitted: Array=[]
		c.source_saved.connect(func(s: GFVegetationSource) -> void: emitted.append(s))
		var entry_count=d.sets[0].entries.size()
		var save_window=weakref(c._save)
		if action=="cancel":
			c._request_save()
			await frames()
			c._save.canceled.emit()
			await frames()
			check(c.visible and not c._saved and emitted.is_empty(),"Save_Dialog_Cancel_restores_draft")
			c.close_creator()
		elif action=="esc": c.canceled.emit()
		else: c.notification(Window.NOTIFICATION_WM_CLOSE_REQUEST)
		await frames()
		check(emitted.is_empty() and d.sets[0].entries.size()==entry_count and not is_instance_valid(save_window.get_ref()),"close_"+action+"_no_publish_or_orphan_Save")
	# Disk and cache destinations, including unnormalized aliases.
	var occupied="res://identity/mesh.tres"
	var occupied_sha=FileAccess.get_sha256(occupied)
	var cached=Resource.new()
	cached.resource_path="res://identity/cache_only.tres"
	var wrong=StandardMaterial3D.new()
	ResourceSaver.save(wrong,"res://identity/wrong_type.tres")
	for path in [occupied,"res://identity/./mesh.tres","res://identity/nested/../mesh.tres","res://identity\\mesh.tres","res://identity/wrong_type.tres","res://identity/cache_only.tres","user://bad.tres","res://identity/bad.res"]:
		var c=injected("mesh")
		var emitted: Array=[]
		c.source_saved.connect(func(s: GFVegetationSource) -> void: emitted.append(s))
		var entries=d.sets[0].entries.size()
		var wrong_sha=FileAccess.get_sha256("res://identity/wrong_type.tres")
		c._save_source(path)
		check(emitted.is_empty() and not c._saved and d.sets[0].entries.size()==entries and FileAccess.get_sha256(occupied)==occupied_sha and FileAccess.get_sha256("res://identity/wrong_type.tres")==wrong_sha and not FileAccess.file_exists("res://identity/cache_only.tres"),"occupied_or_invalid_path_refused",{"path":path,"message":c._info.text})
		c.close_creator()
		await frames()
	for fault in ["save-error","null","wrong-type","uncached","schema","id","kind","display","name","variant","transform","material","mesh","asset","card","texture","allow","review","local","path"]:
		var tag: String="png" if fault in ["card","texture"] else "packed" if fault=="asset" else "mesh"
		var c=injected(tag,fault)
		var emitted: Array=[]
		c.source_saved.connect(func(s: GFVegetationSource) -> void: emitted.append(s))
		var path: String="res://identity/fault-"+fault+".tres"
		var entries=d.sets[0].entries.size()
		c._save_source(path)
		var file_ok: bool=not FileAccess.file_exists(path) if fault=="save-error" else FileAccess.file_exists(path) and c._info.text.contains(path)
		check(emitted.is_empty() and not c._saved and d.sets[0].entries.size()==entries and file_ok,"fault_"+fault+"_no_publish_file_retained",{"message":c._info.text})
		c.close_creator()
		await frames()
	var c=injected("mesh")
	c._save_source("res://identity/missing_directory/error.tres")
	check(not c._saved and not FileAccess.file_exists("res://identity/missing_directory/error.tres"),"actual_Save_Error_no_publish")
	c.close_creator()
	await frames()
	for change in ["set","layer"]:
		activate(d.sets[0])
		c=injected("mesh")
		var entries=d.sets[0].entries.size()
		var other_entries=d.sets[1].entries.size()
		c.after_write=func() -> void:
			if change=="set": plugin.active_set=d.sets[1]
			else: plugin.active_layer=null
		c._save_source("res://identity/context-"+change+".tres")
		var context_message: String=plugin._status.text
		await frames()
		check(d.sets[0].entries.size()==entries and d.sets[1].entries.size()==other_entries and context_message.contains("Scene/set changed"),"context_"+change+"_saved_not_added_elsewhere",{"message":context_message})
	activate(d.sets[0])
	for extension in ["png","webp"]:
		var s: GFVegetationSource=created[4 if extension=="png" else 5]
		var asset_path: String="res://fixtures/grass."+extension
		var bytes=FileAccess.get_file_as_bytes(asset_path)
		var image=Image.new()
		if extension=="png": image.load_png_from_buffer(bytes)
		else: image.load_webp_from_buffer(bytes)
		image.resize(maxi(1,image.get_width()/2),maxi(1,image.get_height()/2))
		if extension=="png": image.save_png(asset_path)
		else: image.save_webp(asset_path)
		get_editor_interface().get_resource_filesystem().reimport_files(PackedStringArray([asset_path]))
		await frames(40)
		check(s.resolve().status==GFSourceResolution.Status.UNAVAILABLE and s.resource_path=="res://identity/"+extension+".tres" and I.records(d)==before_records,"canonical_"+extension+"_real_reimport_keeps_identity_records")
		var file=FileAccess.open(asset_path,FileAccess.WRITE)
		file.store_buffer(bytes)
		file.close()
		get_editor_interface().get_resource_filesystem().reimport_files(PackedStringArray([asset_path]))
		await frames(40)
		check(s.resolve().status==GFSourceResolution.Status.READY and I.records(d)==before_records,"canonical_"+extension+"_reimport_restore")
	var glb: GFVegetationSource=created[2]
	var glb_bytes=FileAccess.get_file_as_bytes("res://fixtures/original_plant.glb")
	var modified=glb_bytes.duplicate()
	var marker="StemBrown".to_utf8_buffer()
	var old_revision=glb.resolve().revision
	for index in modified.size()-marker.size():
		if modified.slice(index,index+marker.size())==marker:
			modified[index+marker.size()-1]=78
			break
	var file=FileAccess.open("res://fixtures/original_plant.glb",FileAccess.WRITE)
	file.store_buffer(modified)
	file.close()
	get_editor_interface().get_resource_filesystem().reimport_files(PackedStringArray(["res://fixtures/original_plant.glb"]))
	await frames(40)
	check(glb.resolve().revision!=old_revision and glb.resource_path=="res://identity/glb.tres" and I.records(d)==before_records,"canonical_GLB_real_reimport_revision_records")
	file=FileAccess.open("res://fixtures/original_plant.glb",FileAccess.WRITE)
	file.store_buffer(glb_bytes)
	file.close()
	get_editor_interface().get_resource_filesystem().reimport_files(PackedStringArray(["res://fixtures/original_plant.glb"]))
	await frames(40)
	check(glb.resolve().revision==old_revision,"canonical_GLB_restore")
	var reviewed: GFVegetationSource=created[7]
	var scene_text=FileAccess.get_file_as_string("res://fixtures/authored_plant.tscn")
	var review=reviewed.reviewed_scene_revision
	file=FileAccess.open("res://fixtures/authored_plant.tscn",FileAccess.WRITE)
	file.store_string(scene_text+"\n; disposable revision test\n")
	file.close()
	plugin._resources_reimported(PackedStringArray(["res://fixtures/authored_plant.tscn"]))
	await frames()
	check(reviewed.resolve().diagnostic_state==GFSourceResolution.DiagnosticState.REVISION_MISMATCH and reviewed.allow_scene_fallback and reviewed.reviewed_scene_revision==review and I.records(d)==before_records,"canonical_revision_does_not_renew_approval")
	file=FileAccess.open("res://fixtures/authored_plant.tscn",FileAccess.WRITE)
	file.store_string(scene_text)
	file.close()
	plugin._resources_reimported(PackedStringArray(["res://fixtures/authored_plant.tscn"]))
	await frames()
	check(reviewed.resolve().diagnostic_state==GFSourceResolution.DiagnosticState.REVIEWED_READY,"canonical_revision_restore")
	var removed=DirAccess.remove_absolute("res://fixtures/authored_plant.tscn")
	check(removed==OK and reviewed.resolve().status==GFSourceResolution.Status.UNAVAILABLE and reviewed.allow_scene_fallback and reviewed.reviewed_scene_revision==review and I.records(d)==before_records,"canonical_missing_asset_no_approval_or_record_rewrite")
	file=FileAccess.open("res://fixtures/authored_plant.tscn",FileAccess.WRITE)
	file.store_string(scene_text)
	file.close()
	plugin._resources_reimported(PackedStringArray(["res://fixtures/authored_plant.tscn"]))
	await frames()
	check(reviewed.resolve().diagnostic_state==GFSourceResolution.DiagnosticState.REVIEWED_READY,"canonical_missing_asset_restore")
	check(created[8].resolve().diagnostic_state==GFSourceResolution.DiagnosticState.HARD_UNSUPPORTED,"Creator_keeps_hard_unsupported_blocked")
	check(I.facts(legacy)==legacy_before and not (load("res://identity/legacy_independent.tres") as GFVegetationSource).allow_scene_fallback and I.records(d)==before_records,"legacy_no_migration_review_transfer_or_record_change")
	check(I.save_scene(scene,"res://identity/shared_a.tscn")==OK and I.save_scene(scene,"res://identity/shared_b.tscn")==OK,"two_scenes_saved")
	for s in created:
		s.display_name="updated "+s.source_id
		ResourceSaver.save(s,s.resource_path)
	for row in expected:
		row.fields.name="updated "+row.fields.id
	I.write("res://identity/expected.json",{"sources":expected,"records":before_records,"legacy":legacy_before})
	I.write("res://identity/results.json",rows)
	print("ISSUE18_CANONICAL_COMPLETE")
	get_tree().quit(1 if failed else 0)
