@tool
extends RefCounted

# Creator-only persistence checks. No lookup/migration by logical ID.
static func destination_error(path: String) -> String:
	var normalized := path.replace("\\", "/").simplify_path()
	if not GFSourceResolver.project_path(path) or normalized != path or path.contains("::") or path.get_extension() != "tres":
		return "Выберите нормализованный путь Source .tres внутри проекта (res://)."
	if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
		return "Путь занят: %s. Выберите новое имя или откройте существующий Source отдельно. Перезапись из Creator запрещена." % path
	if ResourceLoader.has_cached(path):
		return "Путь занят resource cache: %s. Выберите другое имя; существующий ресурс не заменяется." % path
	return ""

static func snapshot(source: GFVegetationSource) -> Dictionary:
	return _capture(source, {}, true)

static func validation_error(expected: Dictionary, persisted: Resource, path: String) -> String:
	if not persisted is GFVegetationSource:
		return "загрузка не вернула GFVegetationSource"
	if persisted.schema_version != 1:
		return "ожидалась Source schema_version = 1"
	if persisted.resource_local_to_scene:
		return "Source неожиданно resource_local_to_scene=true"
	if persisted.resource_path != path or persisted.is_built_in():
		return "Source не имеет ожидаемого внешнего resource_path"
	if ResourceLoader.get_cached_ref(path) != persisted:
		return "загруженный Source не является ресурсом этого пути в cache"
	return _difference(expected, snapshot(persisted), "Source")

static func _capture(value: Variant, seen: Dictionary, root: bool = false) -> Variant:
	if value is Resource:
		var resource: Resource = value
		var path := resource.resource_path
		if not root and not path.is_empty() and not path.contains("::"):
			# External assets are referenced, never copied/edited by Creator.
			return {"external_path":path, "native_class":resource.get_class()}
		var id := resource.get_instance_id() # traversal only; never persisted identity
		if seen.has(id):
			return {"reference":seen[id]}
		seen[id] = seen.size()
		var fields: Dictionary = {}
		var properties := resource.get_property_list()
		properties.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.name) < str(b.name))
		for property in properties:
			var name: String = property.name
			if (property.usage & PROPERTY_USAGE_STORAGE) == 0 or name in ["script", "resource_path", "resource_scene_unique_id"]:
				continue
			fields[name] = _capture(resource.get(name), seen)
		var script: Script = resource.get_script()
		return {"native_class":resource.get_class(), "script_path":script.resource_path if script != null else "", "fields":fields}
	if value is Array:
		var values: Array = []
		for item in value:
			values.append(_capture(item,seen))
		return values
	if value is Dictionary:
		var values: Dictionary = {}
		var keys: Array = value.keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
		for key in keys:
			values[key] = _capture(value[key],seen)
		return values
	return value

static func _difference(expected: Variant, actual: Variant, field: String) -> String:
	if typeof(expected) != typeof(actual):
		return "тип поля %s отличается от сохранённого draft" % field
	if expected is Dictionary:
		if expected.size() != actual.size():
			return "набор сохраняемых свойств %s отличается" % field
		for key in expected:
			if not actual.has(key):
				return "отсутствует поле %s.%s" % [field,key]
			var reason := _difference(expected[key],actual[key],field+"."+str(key))
			if not reason.is_empty():
				return reason
		return ""
	if expected is Array:
		if expected.size() != actual.size():
			return "размер массива %s отличается" % field
		for index in expected.size():
			var reason := _difference(expected[index],actual[index],field+"[%d]" % index)
			if not reason.is_empty():
				return reason
		return ""
	var equal: bool = expected == actual
	if typeof(expected) == TYPE_FLOAT:
		equal = equal or (is_nan(expected) and is_nan(actual)) or is_equal_approx(expected,actual)
	elif typeof(expected) in [TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4, TYPE_RECT2, TYPE_TRANSFORM2D, TYPE_PLANE, TYPE_QUATERNION, TYPE_AABB, TYPE_BASIS, TYPE_TRANSFORM3D, TYPE_COLOR]:
		equal = equal or expected.is_equal_approx(actual) or str(expected) == str(actual)
	return "" if equal else "значение поля %s отличается от сохранённого draft" % field
