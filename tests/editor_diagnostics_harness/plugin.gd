@tool
extends EditorPlugin

var failed := false
var results: Array = []

func _enter_tree() -> void:
	call_deferred("run")

func frames(count: int = 4) -> void:
	for i in count:
		await get_tree().process_frame

func check(ok: bool, id: String) -> void:
	print(("PASS " if ok else "FAIL ") + "ISSUE13_EDITOR " + id)
	results.append({"id": id, "status": "PASS" if ok else "FAIL", "scope": "native Editor API, not mouse GUI"})
	failed = failed or not ok

func source_for(path: String, id: String, name: String) -> GFVegetationSource:
	var source := GFVegetationSource.new()
	source.source_id = id
	source.display_name = name
	source.kind = GFVegetationSource.Kind.IMPORTED_SCENE
	source.asset = load(path)
	return source

func hard_scene() -> PackedScene:
	var root_node := Node3D.new()
	var animation := AnimationPlayer.new()
	root_node.add_child(animation)
	animation.owner = root_node
	var packed := PackedScene.new()
	assert(packed.pack(root_node) == OK)
	root_node.free()
	return packed

func entry_for(source: GFVegetationSource) -> GFPaletteEntry:
	var entry := GFPaletteEntry.new()
	entry.source = source
	return entry

func assert_guidance(guidance: Label, copy: Button, expected: String, copy_visible: bool, id: String) -> void:
	check(guidance.text.contains(expected) and copy.visible == copy_visible, id)

func rect_inside(parent: Control, child: Control) -> bool:
	var child_end := child.position + child.size
	return child.position.x >= 0 and child.position.y >= 0 and child_end.x <= parent.size.x and child_end.y <= parent.size.y

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var scene: Node
	var plugin: EditorPlugin
	for i in 600:
		scene = get_editor_interface().get_edited_scene_root()
		var plugins := get_tree().get_nodes_in_group("go_flora_editor_plugin")
		if scene != null and plugins.size() == 1:
			plugin = plugins[0]
			break
		await frames(1)
	check(scene != null and plugin != null, "installed_enabled")
	if scene == null or plugin == null:
		get_tree().quit(1)
		return
	var layer := scene.get_node("VegetationLayer") as VegetationLayer3D
	var vegetation_set := layer.layer_data.sets[0]
	var previous_entries := vegetation_set.entries.duplicate()
	var standard := source_for("res://fixtures/static_plant.tscn", "ui-standard", "Static READY")
	var review := source_for("res://fixtures/authored_plant.tscn", "ui-review", "Scene Review Required")
	var mismatch := source_for("res://fixtures/authored_plant.tscn", "ui-mismatch", "Revision Mismatch")
	mismatch.allow_scene_fallback = true
	mismatch.reviewed_scene_revision = review.resolve().revision + "-old"
	var reviewed := source_for("res://fixtures/authored_plant.tscn", "ui-reviewed", "Reviewed READY")
	reviewed.allow_scene_fallback = true
	reviewed.reviewed_scene_revision = reviewed.resolve().revision
	var hard := GFVegetationSource.new()
	hard.source_id = "ui-hard"
	hard.display_name = "Hard UNSUPPORTED"
	hard.kind = GFVegetationSource.Kind.IMPORTED_SCENE
	hard.asset = hard_scene()
	vegetation_set.entries.assign([entry_for(standard), entry_for(review), entry_for(mismatch), entry_for(reviewed), entry_for(hard)])
	vegetation_set.emit_changed()
	plugin._edit(layer)
	plugin._show_source_details()
	await frames()
	var dialog := plugin._source_details as AcceptDialog
	var picker := dialog.find_child("SourceDiagnosticsPicker", true, false) as OptionButton
	var guidance := dialog.find_child("SourceDiagnosticsGuidance", true, false) as Label
	var guidance_scroll := dialog.find_child("SourceDiagnosticsGuidanceScroll", true, false) as ScrollContainer
	var details := dialog.find_child("SourceDiagnosticsTechnicalDetails", true, false) as TextEdit
	var toggle := dialog.find_child("SourceDiagnosticsTechnicalToggle", true, false) as Button
	var copy := dialog.find_child("SourceDiagnosticsCopyRevision", true, false) as Button
	var inspect := dialog.find_child("SourceDiagnosticsEditSource", true, false) as Button
	var fields := dialog.find_child("SourceDiagnosticsFields", true, false) as VBoxContainer
	var actions := dialog.find_child("SourceDiagnosticsActions", true, false) as HBoxContainer
	check(picker != null and guidance != null and guidance_scroll != null and details != null and toggle != null and copy != null and inspect != null and fields != null and actions != null, "diagnostics_controls_present")
	if picker != null and guidance != null and guidance_scroll != null and details != null and toggle != null and copy != null and inspect != null and fields != null and actions != null:
		for viewport in [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1920, 1080)]:
			var popup_size: Vector2i = plugin._source_diagnostics_popup_size_for_viewport(viewport)
			check(popup_size.x <= viewport.x - 48 and popup_size.y <= viewport.y - 64 and popup_size.x <= 680 and popup_size.y <= 620, "layout_popup_cap_%dx%d" % [viewport.x, viewport.y])
		var current_popup_size: Vector2i = plugin._source_diagnostics_popup_size()
		check(dialog.size.x <= current_popup_size.x and dialog.size.y <= current_popup_size.y, "layout_window_uses_viewport_cap")
		check(rect_inside(fields, picker) and rect_inside(fields, guidance_scroll) and rect_inside(fields, toggle) and rect_inside(fields, actions), "layout_fixed_controls_inside_dialog_body")
		var ok_button := dialog.get_ok_button()
		check(ok_button != null and ok_button.visible and ok_button.position.y + ok_button.size.y <= dialog.size.y, "layout_ok_reachable")
		check(not details.visible and guidance_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "layout_scroll_body_and_collapsed_technical_default")
		assert_guidance(guidance, copy, "Статический Source готов", false, "static_ready_no_fallback_steps")
		picker.select(1)
		picker.item_selected.emit(1)
		await frames()
		assert_guidance(guidance, copy, "1. Изучите PackedScene", true, "review_required_steps_and_copy")
		copy.pressed.emit()
		check(str(copy.get_meta("go_flora_selected_revision", "")) == review.resolve().revision, "copy_uses_currently_selected_review_source")
		picker.select(2)
		picker.item_selected.emit(2)
		await frames()
		assert_guidance(guidance, copy, "Сцена изменилась", true, "revision_mismatch_current_and_prior_revision")
		check(guidance.text.contains(mismatch.reviewed_scene_revision) and guidance.text.contains(mismatch.resolve().revision), "revision_mismatch_revisions_shown")
		check(guidance.size.x <= guidance_scroll.size.x and rect_inside(fields, actions), "layout_mismatch_sha_wraps_and_actions_reachable")
		picker.select(3)
		picker.item_selected.emit(3)
		await frames()
		assert_guidance(guidance, copy, "инертный Mesh preview", true, "reviewed_ready_inert_preview_runtime_instance")
		picker.select(4)
		picker.item_selected.emit(4)
		await frames()
		assert_guidance(guidance, copy, "Копирование revision не снимает", false, "hard_unsupported_no_false_copy_remedy")
		check(details.text.contains("Diagnostic state: HARD_UNSUPPORTED") and details.text.contains("Blocking reason:"), "typed_state_and_reason_in_technical_details")
		toggle.button_pressed = false
		toggle.toggled.emit(false)
		await frames()
		check(not details.visible, "technical_details_collapsible")
		toggle.button_pressed = true
		toggle.toggled.emit(true)
		await frames()
		check(details.visible and details.size.y <= 112 and rect_inside(fields, actions), "layout_technical_details_bounded_when_expanded")
		picker.select(1)
		picker.item_selected.emit(1)
		inspect.pressed.emit()
		await frames()
		var inspector := get_editor_interface().get_inspector()
		check(inspector.has_method("get_edited_object") and inspector.call("get_edited_object") == review, "inspector_uses_currently_selected_source")
	if is_instance_valid(dialog):
		dialog.hide()
		dialog.queue_free()
	vegetation_set.entries = previous_entries
	vegetation_set.emit_changed()
	await frames()
	var output := FileAccess.open("res://.scratch/issue13_editor_results.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(results, "\t"))
	output.close()
	print("NOT_RUN INTERACTIVE_GUI_QA")
	print(("PASS " if not failed else "FAIL ") + "ISSUE13_EDITOR_COMPLETE")
	get_tree().quit(0 if not failed else 1)
