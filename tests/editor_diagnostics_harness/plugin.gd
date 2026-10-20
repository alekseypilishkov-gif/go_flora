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

func immediately_after(previous: Control, following: Control) -> bool:
	return following.position.y >= previous.position.y + previous.size.y and following.position.y - (previous.position.y + previous.size.y) <= 12.0

func owning_dock(control: Node) -> EditorDock:
	while control != null:
		if control is EditorDock:
			return control
		control = control.get_parent()
	return null

func source_data_snapshot(sources: Array[GFVegetationSource]) -> String:
	var values: Array = []
	for source in sources:
		# Capture persisted Source fields, excluding lazy resolver caches.
		values.append([source.schema_version, source.source_id, source.display_name, source.kind,
			source.asset.get_instance_id(), source.surface_materials, source.mesh_transform,
			source.variant_revision, source.alpha_card, source.allow_scene_fallback, source.reviewed_scene_revision])
	return var_to_str(values)

func check_inspector_navigation(plugin: EditorPlugin, layer: VegetationLayer3D, vegetation_set: GFVegetationSet) -> void:
	var first := source_for("res://fixtures/authored_plant.tscn", "ui-navigation-first", "authored_plant")
	first.allow_scene_fallback = true
	first.reviewed_scene_revision = first.resolve().revision
	var second := source_for("res://fixtures/authored_plant.tscn", "ui-navigation-second", "authored_plant")
	var sources: Array[GFVegetationSource] = [first, second]
	vegetation_set.entries.assign([entry_for(first), entry_for(second)])
	vegetation_set.emit_changed()
	var source_state := source_data_snapshot(sources)
	var records := var_to_str(layer.layer_data.records)
	var inspector := get_editor_interface().get_inspector()
	var flora := plugin._dock_scroll as Control
	var flora_dock := owning_dock(flora)
	var inspector_dock := owning_dock(inspector)
	check(flora_dock != null and inspector_dock != null, "navigation_public_editor_docks_found")
	if flora_dock == null or inspector_dock == null:
		return
	var flora_parent := flora_dock.get_parent()
	var inspector_parent := inspector_dock.get_parent()
	check(first != second and first.source_id != second.source_id and first.display_name == second.display_name,
		"navigation_same_name_distinct_objects_and_ids")
	for index in [1, 0, 1]:
		# Public dock activation exercises return navigation without changing layout.
		# Physical Ctrl+Alt+G remains an owner GUI check.
		flora_dock.make_visible()
		await frames(8)
		check(flora.is_visible_in_tree(), "navigation_return_to_GOFLORA_%d" % index)
		plugin._show_source_details()
		await frames()
		var dialog := plugin._source_details as AcceptDialog
		var picker := dialog.find_child("SourceDiagnosticsPicker", true, false) as OptionButton
		var inspect := dialog.find_child("SourceDiagnosticsEditSource", true, false) as Button
		var copy := dialog.find_child("SourceDiagnosticsCopyRevision", true, false) as Button
		check(dialog.visible and picker.item_count == 2 and picker.get_item_text(0) == picker.get_item_text(1),
			"navigation_reopened_duplicate_name_selector_%d" % index)
		picker.select(1 - index)
		picker.item_selected.emit(1 - index)
		picker.select(index)
		picker.item_selected.emit(index)
		check(str(copy.get_meta("go_flora_selected_revision", "")) == sources[index].resolve().revision,
			"navigation_copy_binding_before_inspect_%d" % index)
		# Close with layout refreshes still deferred, exercising the popup lifecycle.
		inspect.pressed.emit()
		check(not dialog.visible and dialog.is_queued_for_deletion(), "navigation_dialog_dismissed_immediately_%d" % index)
		await frames(12)
		check(not is_instance_valid(dialog) and not is_instance_valid(plugin._source_details) and not plugin._source_ui_open(),
			"navigation_dialog_freed_no_modal_left_%d" % index)
		check(inspector.get_edited_object() == sources[index]
			and (inspector.get_edited_object() as GFVegetationSource).source_id == sources[index].source_id,
			"navigation_exact_selected_object_and_id_%d" % index)
		check(inspector.is_visible_in_tree(), "navigation_Inspector_automatically_visible_%d" % index)
		# Permit the pre-fix regression probe to continue after a failed dismissal.
		if is_instance_valid(dialog):
			dialog.hide()
			dialog.queue_free()
		await frames()
	flora_dock.make_visible()
	await frames()
	check(flora.is_visible_in_tree(), "navigation_return_to_GOFLORA_after_cycles")
	for close_signal in ["canceled", "confirmed"]:
		plugin._show_source_details()
		await frames()
		var dialog := plugin._source_details as AcceptDialog
		dialog.hide()
		dialog.emit_signal(close_signal)
		await frames()
		check(not is_instance_valid(dialog) and not plugin._source_ui_open(), "navigation_reopen_%s_frees_dialog" % close_signal)
	check(owning_dock(flora) == flora_dock and owning_dock(inspector) == inspector_dock
		and flora_dock.get_parent() == flora_parent and inspector_dock.get_parent() == inspector_parent,
		"navigation_dock_topology_unchanged")
	check(source_data_snapshot(sources) == source_state, "navigation_source_data_unchanged")
	check(var_to_str(layer.layer_data.records) == records, "navigation_records_unchanged")

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
		var layout_test_size: Vector2i = plugin._source_diagnostics_popup_size_for_viewport(Vector2i(1280, 720))
		dialog.size = layout_test_size
		picker.item_selected.emit(0)
		await frames(6)
		check(dialog.size == layout_test_size, "layout_1280x720_virtual_window_size")
		assert_guidance(guidance, copy, "Статический Source готов", false, "static_ready_no_fallback_steps")
		check(guidance_scroll.size_flags_vertical == Control.SIZE_SHRINK_BEGIN and immediately_after(guidance_scroll, toggle), "layout_static_guidance_is_content_sized_and_toggle_adjacent")
		picker.select(1)
		picker.item_selected.emit(1)
		await frames(6)
		assert_guidance(guidance, copy, "1. Изучите PackedScene", true, "review_required_steps_and_copy")
		check(guidance_scroll.size.y <= dialog.size.y * 0.38 + 1.0 and immediately_after(guidance_scroll, toggle), "layout_long_review_guidance_capped_and_toggle_adjacent")
		copy.pressed.emit()
		check(str(copy.get_meta("go_flora_selected_revision", "")) == review.resolve().revision, "copy_uses_currently_selected_review_source")
		picker.select(2)
		picker.item_selected.emit(2)
		await frames(6)
		assert_guidance(guidance, copy, "Сцена изменилась", true, "revision_mismatch_current_and_prior_revision")
		check(guidance.text.contains(mismatch.reviewed_scene_revision) and guidance.text.contains(mismatch.resolve().revision), "revision_mismatch_revisions_shown")
		var long_guidance_height := guidance_scroll.size.y
		check(guidance.size.x <= guidance_scroll.size.x and guidance_scroll.size.y <= dialog.size.y * 0.38 + 1.0 and immediately_after(guidance_scroll, toggle) and rect_inside(fields, actions), "layout_mismatch_sha_wraps_and_actions_reachable")
		toggle.button_pressed = true
		toggle.toggled.emit(true)
		await frames()
		check(details.visible and details.size.y > 112 and rect_inside(fields, actions), "layout_long_guidance_expanded_details_use_remaining_space")
		picker.select(3)
		picker.item_selected.emit(3)
		await frames(6)
		assert_guidance(guidance, copy, "инертный Mesh preview", true, "reviewed_ready_inert_preview_runtime_instance")
		check(guidance_scroll.size.y < long_guidance_height and immediately_after(guidance_scroll, toggle) and details.visible and details.size.y > 112, "layout_short_guidance_expanded_details_use_remaining_space")
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
		check(details.visible and details.size.y > 112 and immediately_after(guidance_scroll, toggle) and rect_inside(fields, actions), "layout_technical_details_expand_into_remaining_space")
		picker.select(1)
		picker.item_selected.emit(1)
		inspect.pressed.emit()
		await frames()
		var inspector := get_editor_interface().get_inspector()
		check(inspector.has_method("get_edited_object") and inspector.call("get_edited_object") == review, "inspector_uses_currently_selected_source")
	if is_instance_valid(dialog):
		dialog.hide()
		dialog.queue_free()
	await frames()
	await check_inspector_navigation(plugin, layer, vegetation_set)
	vegetation_set.entries = previous_entries
	vegetation_set.emit_changed()
	await frames()
	var output := FileAccess.open("res://.scratch/issue13_editor_results.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(results, "\t"))
	output.close()
	print("NOT_RUN INTERACTIVE_GUI_QA")
	print(("PASS " if not failed else "FAIL ") + "ISSUE13_EDITOR_COMPLETE")
	get_tree().quit(0 if not failed else 1)
