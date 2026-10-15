extends SceneTree

var failures := 0
var rows: Array = []
var timings: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + "STAGE023 " + id + " " + detail)
	rows.append({"id": id, "status": "PASS" if ok else "FAIL", "detail": detail})
	if not ok:
		failures += 1

func hit(point: Vector3) -> Dictionary:
	return {"position": point, "normal": Vector3.UP}

func data_for(count: int, dense: bool = true) -> GFVegetationLayerData:
	var data := GFVegetationLayerData.new()
	data.layer_id = "erase-test"
	var vegetation_set := GFVegetationSet.new()
	vegetation_set.set_id = "active"
	data.sets.append(vegetation_set)
	for i in count:
		var record := GFInstanceRecord.new()
		record.record_id = "id-%d" % i
		record.layer_id = data.layer_id
		record.set_id = "active"
		record.source_id = "disabled-source"
		record.local_transform.origin = Vector3((i % 10) * 0.01, 0, 0) if dense else Vector3(i * 0.05, 0, 0)
		data.records.append(record)
	return data

func drain(stroke: GFStroke) -> int:
	var ticks := 0
	while stroke.has_pending_work():
		stroke.process_pending()
		ticks += 1
		if stroke._erase_query.work_last_tick > GFEraseQuery.WORK_PER_TICK or ticks > 100000:
			check(false, "bounded_work_or_termination")
			break
	return ticks

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.scratch")
	var brush := GFBrush.new()
	brush.radius_m = 1
	brush.max_candidates = 1 # Paint limit must never truncate Erase.
	for count in [1, 1000, 2001, 5000, 12000]:
		var data := data_for(count)
		var original := data.records.duplicate()
		var serial := data.next_stroke_serial
		var stroke := GFStroke.new()
		var start := Time.get_ticks_usec()
		check(stroke.begin(data, Transform3D.IDENTITY, data.sets[0], brush, 8, GFStroke.Mode.ERASE), "begin_%d" % count)
		stroke.feed(hit(Vector3.ZERO), Callable())
		var ticks := drain(stroke)
		var delta := stroke.finish_delta()
		timings.append({"records": count, "CPU_usec": Time.get_ticks_usec() - start, "ticks": ticks, "candidates": stroke.candidates_used})
		check(delta.removed.size() == count and not stroke.budget_exhausted, "dense_single_click_complete_%d" % count)
		delta.apply_to(data, false)
		check(data.records.is_empty(), "apply_%d" % count)
		delta.apply_to(data, true)
		check(data.records == original and data.next_stroke_serial == serial, "exact_ID_order_reference_serial_undo_%d" % count)
		delta.apply_to(data, false)
		check(data.records.is_empty() and data.next_stroke_serial == serial + 1, "redo_%d" % count)
	var data := data_for(12000, false)
	for i in 3000:
		data.records[i].set_id = "other"
	for i in range(3000, 4000):
		data.records[i].flags = 1
	var original := data.records.duplicate()
	var stroke := GFStroke.new()
	stroke.begin(data, Transform3D.IDENTITY, data.sets[0], brush, 8, GFStroke.Mode.ERASE)
	stroke.feed(hit(Vector3(150, 0, 0)), Callable())
	stroke.feed(hit(Vector3(600, 0, 0)), Callable())
	for i in 30:
		stroke.feed(hit(Vector3(600, 0, 0)), Callable())
	drain(stroke)
	var delta := stroke.finish_delta()
	check(delta.removed.size() == 8000 and stroke.stamp_count == 2, "fast_sweep_stationary_other_set_prefix_locked_complete")
	check(stroke.candidates_used < data.records.size() * 2, "spatial_queries_less_than_two_full_scans_for_450m_sweep", str(stroke.candidates_used))
	delta.apply_to(data, false)
	check(data.records.size() == 4000 and data.records.all(func(r: GFInstanceRecord) -> bool: return r.set_id == "other" or r.flags == 1), "other_sets_locked_untouched")
	delta.apply_to(data, true)
	check(data.records == original, "interleaved_original_order_restore")
	data = data_for(5000, false)
	data.records.reverse()
	original = data.records.duplicate()
	stroke = GFStroke.new()
	stroke.begin(data, Transform3D.IDENTITY, data.sets[0], brush, 8, GFStroke.Mode.ERASE)
	stroke.feed(hit(Vector3.ZERO), Callable())
	stroke.feed(hit(Vector3(250, 0, 0)), Callable())
	drain(stroke)
	delta = stroke.finish_delta()
	check(delta.removed.size() == 5000, "reverse_record_order_does_not_omit_hits")
	delta.apply_to(data, false)
	delta.apply_to(data, true)
	check(data.records == original, "reverse_order_exact_undo_restoration")
	data = data_for(3)
	data.records[0].local_transform.origin = Vector3.ZERO
	data.records[1].local_transform.origin = Vector3(10, 0, 0)
	data.records[2].local_transform.origin = Vector3(5, 0, 0)
	stroke = GFStroke.new()
	stroke.begin(data, Transform3D.IDENTITY, data.sets[0], brush, 8, GFStroke.Mode.ERASE)
	stroke.feed(hit(Vector3.ZERO), Callable())
	stroke.break_path()
	stroke.feed(hit(Vector3(10, 0, 0)), Callable())
	drain(stroke)
	check(stroke.finish_delta().removed.size() == 2, "ineligible_surface_break_never_bridges_gap")
	var transform := Transform3D(Basis.from_euler(Vector3(0.5, 0.8, 0.1)).scaled(Vector3(2, 3, 0.5)), Vector3(10, 5, -4))
	data = data_for(3)
	data.records[1].local_transform.origin = Vector3(0, 0, 8)
	data.records[2].local_transform.origin = Vector3(0, 5, 0)
	stroke = GFStroke.new()
	stroke.begin(data, transform, data.sets[0], brush, 8, GFStroke.Mode.ERASE)
	stroke.feed(hit(transform.origin), Callable())
	drain(stroke)
	check(stroke.finish_delta().removed.size() == 1, "rotated_nonuniform_scaled_layer_exact_world_sphere")
	data = data_for(12000)
	stroke = GFStroke.new()
	stroke.begin(data, Transform3D.IDENTITY, data.sets[0], brush, 8, GFStroke.Mode.ERASE)
	stroke.feed(hit(Vector3.ZERO), Callable())
	check(stroke.has_pending_work() and data.records.size() == 12000, "pending_index_does_not_mutate_saved_records")
	stroke = null
	check(data.records.size() == 12000 and data.next_stroke_serial == 0, "cancel_discards_every_pending_delete")
	brush.radius_m = 0.05
	for count in [0, 1, 10]:
		data = data_for(count)
		stroke = GFStroke.new()
		stroke.begin(data, Transform3D.IDENTITY, data.sets[0], brush, 8, GFStroke.Mode.ERASE)
		stroke.feed(hit(Vector3(-1000, 0, -1000)), Callable())
		stroke.feed(hit(Vector3(1000, 0, 1000)), Callable())
		var ticks := drain(stroke)
		check(ticks < 10, "tiny_brush_long_sparse_diagonal_bounded_ticks_%d" % count, str(ticks))
		check(stroke.finish_delta().removed.size() == (8 if count == 10 else count), "sparse_diagonal_complete_%d" % count)
	var output := FileAccess.open("res://.scratch/stage023_core.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": rows, "timings": timings, "scope": "native core CPU timings, not FPS"}, "\t"))
	output.close()
	print(("PASS " if failures == 0 else "FAIL ") + "STAGE023_CORE_COMPLETE")
	quit(0 if failures == 0 else 1)
