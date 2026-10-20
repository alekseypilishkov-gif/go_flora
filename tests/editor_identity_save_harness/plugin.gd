@tool
extends EditorPlugin
var rows: Array=[]
var failed:=false
func _enter_tree() -> void:
	call_deferred("run")
func frames(n: int=10) -> void:
	for i in n: await get_tree().process_frame
func check(ok: bool,id: String,facts: Dictionary={}) -> void:
	rows.append({"id":id,"status":"PASS" if ok else "FAIL","facts":facts,"scope":"graphical native Editor API, no physical owner GUI acceptance"})
	print(("PASS " if ok else "FAIL ")+"ISSUE18_GRAPHICS "+id)
	failed=failed or not ok
func run() -> void:
	var scene: Node
	var plugin: EditorPlugin
	for i in 600:
		scene=get_editor_interface().get_edited_scene_root()
		var plugins=get_tree().get_nodes_in_group("go_flora_editor_plugin")
		if scene!=null and plugins.size()==1:
			plugin=plugins[0]
			break
		await frames(1)
	if scene==null or plugin==null:
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://identity")
	var layer=scene.get_node("VegetationLayer") as VegetationLayer3D
	plugin._edit(layer)
	plugin.active_set=layer.layer_data.sets[0]
	plugin._refresh_sets()
	plugin._create_source(false)
	await frames()
	var c: ConfirmationDialog=plugin._creator
	c.source.asset=BoxMesh.new()
	c._save_source("res://identity/graphical_source.tres")
	await frames()
	var saved=load("res://identity/graphical_source.tres") as GFVegetationSource
	check(plugin.active_set.entries[-1].source==saved and saved.resource_path=="res://identity/graphical_source.tres","Creator_external_in_graphical_editor")
	get_editor_interface().set_main_screen_editor("3D")
	await frames(60)
	var path="res://identity/graphical_saved.tscn"
	get_editor_interface().save_scene_as(path)
	await frames(30)
	var text=FileAccess.get_file_as_string(path)
	check(text.contains('path="res://identity/graphical_source.tres"') and text.contains('[ext_resource type="Resource"'),"native_Save_As_keeps_ExtResource")
	var cache: String=get_editor_interface().get_editor_paths().get_cache_dir()
	var thumbnail=cache.path_join("resthumb-"+ProjectSettings.globalize_path(path).md5_text()+".png")
	var image=Image.new()
	var bytes=FileAccess.get_file_as_bytes(thumbnail)
	var ok: bool=not bytes.is_empty() and image.load_png_from_buffer(bytes)==OK and image.get_width()>0 and image.get_height()>0
	check(ok,"native_Save_As_creates_real_thumbnail",{"path":thumbnail,"bytes":bytes.size(),"size":str(image.get_size()),"renderer":RenderingServer.get_video_adapter_name()})
	if ok: image.save_png("res://identity/thumbnail.png")
	var error=get_editor_interface().save_scene()
	await frames(20)
	check(error==OK and FileAccess.file_exists(thumbnail),"native_Save_existing_scene_and_thumbnail")
	var p=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var n=p.instantiate()
	var reopened: VegetationLayer3D=n.get_node("VegetationLayer")
	check(reopened.layer_data.sets[0].source_by_id(saved.source_id)==saved,"native_saved_scene_reopens_canonical")
	n.free()
	var f=FileAccess.open("res://identity/graphics_results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(rows,"  "))
	f.close()
	print("ISSUE18_GRAPHICAL_SAVE_COMPLETE")
	get_tree().quit(1 if failed else 0)
