extends SceneTree
const I=preload("res://tests/editor_identity_harness/lib.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://identity/expected.json"))
	# Godot JSON numbers load as floats; compare the persisted enum/schema as ints.
	expected.legacy.schema=int(expected.legacy.schema)
	expected.legacy.kind=int(expected.legacy.kind)
	for row in expected.sources:
		row.fields.schema=int(row.fields.schema)
		row.fields.kind=int(row.fields.kind)
	var rows: Array=[]
	var failed:=false
	for file in ["shared_a.tscn","shared_b.tscn"]:
		var n=(load("res://identity/"+file) as PackedScene).instantiate()
		var d: GFVegetationLayerData=n.get_node("VegetationLayer").layer_data
		var ok: bool=I.records(d)==expected.records and I.facts(d.sets[0].entries[0].source)==expected.legacy and d.sets[0].entries[0].source.is_built_in()
		for row in expected.sources:
			var s=d.sets[0].source_by_id(row.fields.id)
			ok=ok and s!=null and s.resource_path==row.path and not s.is_built_in() and I.facts(s)==row.fields and d.sets[1].source_by_id(s.source_id)==s
		var text=FileAccess.get_file_as_string("res://identity/"+file)
		ok=ok and text.contains('[ext_resource type="Resource"') and text.contains('path="res://identity/mesh.tres"')
		rows.append({"scene":file,"status":"PASS" if ok else "FAIL","records":I.records(d)})
		print(("PASS " if ok else "FAIL ")+"ISSUE18_REOPEN "+file)
		failed=failed or not ok
		n.free()
	I.write("res://identity/reopen_results.json",rows)
	print("ISSUE18_REOPEN_COMPLETE")
	quit(1 if failed else 0)
