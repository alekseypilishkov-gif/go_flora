@tool
class_name GFConfigurationWarnings
extends RefCounted

## Presentation only: never serialized and never used to decide render eligibility.
enum Problem { MISSING_SET, MISSING_SOURCE, SOURCE_NOT_READY, FALLBACK_ROOT_INVALID }
const MAX_SOURCE_WARNINGS := 8
const MAX_FIELD_LENGTH := 64
const MAX_WARNING_LENGTH := 512
const MAX_PAINTER_LENGTH := 800

static func record_issue(groups: Dictionary, record: GFInstanceRecord, source: GFVegetationSource,
		resolution: GFSourceResolution, problem: Problem) -> void:
	var key := JSON.stringify([record.set_id, record.source_id, problem])
	if not groups.has(key):
		groups[key] = {"set_id": record.set_id, "source_id": record.source_id,
			"name": source.display_name if source != null else "(источник отсутствует)",
			"category": category(resolution, problem), "count": 0}
	groups[key].count += 1

static func category(resolution: GFSourceResolution, problem: Problem) -> String:
	match problem:
		Problem.MISSING_SET:
			return "MISSING_SET: набор не найден"
		Problem.MISSING_SOURCE:
			return "MISSING_SOURCE: ссылка на Source отсутствует"
		Problem.FALLBACK_ROOT_INVALID:
			return "FALLBACK_ROOT_INVALID: корень Runtime Scene Instance не Node3D"
		_:
			return "%s / %s / %s: %s" % [GFSourceResolution.Status.keys()[resolution.status],
				GFSourceResolution.DiagnosticState.keys()[resolution.diagnostic_state],
				GFSourceResolution.BlockingReason.keys()[resolution.blocking_reason], resolution.blocking_reason_label()]

static func format(groups: Dictionary) -> PackedStringArray:
	var warnings := PackedStringArray()
	var keys := groups.keys()
	keys.sort()
	var omitted_records := 0
	for index in keys.size():
		var issue: Dictionary = groups[keys[index]]
		if index >= MAX_SOURCE_WARNINGS:
			omitted_records += issue.count
			continue
		warnings.append(compact("Набор %s · Source \"%s\" (%s). %s. Затронуто записей: %d; логические записи сохранены." % [
			compact(issue.set_id, MAX_FIELD_LENGTH), compact(issue.name, MAX_FIELD_LENGTH),
			compact(issue.source_id, MAX_FIELD_LENGTH), issue.category, issue.count], MAX_WARNING_LENGTH))
	if keys.size() > MAX_SOURCE_WARNINGS:
		warnings.append("Ещё %d групп Set/Source с проблемами; затронуто записей: %d. Проверьте ссылки и Source Diagnostics; записи сохранены." % [
			keys.size() - MAX_SOURCE_WARNINGS, omitted_records])
	return warnings

static func painter_context(vegetation_set: GFVegetationSet, mix: bool, selected_id: String, reason: String) -> String:
	if reason.is_empty():
		return ""
	# reason is opaque existing Painter validation, never parsed for severity.
	var context := "MIX by weights" if mix else "Selected Source (%s)" % compact(selected_id, MAX_FIELD_LENGTH)
	return compact("%s · набор %s: %s" % [context,
		compact(vegetation_set.set_id, MAX_FIELD_LENGTH) if vegetation_set != null else "(не выбран)", reason], MAX_PAINTER_LENGTH)

static func compact(value: String, limit: int) -> String:
	var single_line := value.replace("\r", " ").replace("\n", " ").replace("\t", " ").strip_edges()
	return single_line if single_line.length() <= limit else single_line.left(limit - 1) + "…"
