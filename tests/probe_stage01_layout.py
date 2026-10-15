import json
import os
import shutil
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
project = root / "stages/01_painter_mvp/evidence/.scratch/layout_probe"
project.mkdir(parents=True, exist_ok=True)
for name in ["project.godot", "demo.tscn", "runtime_camera.gd", "runtime_camera.gd.uid"]:
    shutil.copyfile(root / "stages/01_painter_mvp/demo" / name, project / name)
shutil.copytree(root / "addons/go_flora", project / "addons/go_flora", dirs_exist_ok=True)
if os.environ.get("GO_FLORA_PROBE_SLOT"):
    painter_path = project / "addons/go_flora/editor/plugin.gd"
    painter_path.write_text(painter_path.read_text(encoding="utf-8").replace("DOCK_SLOT_RIGHT_UL", os.environ["GO_FLORA_PROBE_SLOT"]), encoding="utf-8")
probe = project / "addons/layout_probe"
probe.mkdir(parents=True, exist_ok=True)
(probe / "plugin.cfg").write_text('[plugin]\nname="Layout probe"\ndescription="Isolated native control geometry inspection, not GUI acceptance"\nauthor="GO_FLORA"\nversion="0.0.0"\nscript="plugin.gd"\n', encoding="utf-8")
(probe / "plugin.gd").write_text('''@tool
extends EditorPlugin

func _enter_tree() -> void:
	call_deferred("probe_layout")

func geometry(control: Control) -> Dictionary:
	return {"class": control.get_class(), "name": str(control.name), "size": str(control.size), "minimum": str(control.get_combined_minimum_size()), "rect": str(control.get_global_rect())}

func probe_layout() -> void:
	for i in 120:
		await get_tree().process_frame
	var plugins := get_tree().get_nodes_in_group("go_flora_editor_plugin")
	if plugins.size() != 1:
		push_error("Production plugin not found")
		get_tree().quit(1)
		return
	var production: EditorPlugin = plugins[0]
	var dock: Control = production._dock_scroll if production.get("_dock_scroll") != null else production._dock
	var rows: Array = []
	var current: Node = dock
	while current != null:
		if current is Control:
			rows.append(geometry(current))
		current = current.get_parent()
	var filesystem: Control = EditorInterface.get_file_system_dock()
	var children: Array = []
	for child in dock.get_children():
		if child is Control:
			children.append(geometry(child))
	var before := {"dock_ancestors": rows, "dock_children": children, "filesystem": geometry(filesystem), "base": geometry(EditorInterface.get_base_control())}
	EditorInterface.set_plugin_enabled("go_flora", false)
	for i in 10:
		await get_tree().process_frame
	var result := {"scope": "Headless native Control geometry; not real GUI acceptance", "enabled": before,
		"disabled": {"filesystem": geometry(filesystem), "base": geometry(EditorInterface.get_base_control())}}
	var out := FileAccess.open("res://layout_probe.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(result, "\\t"))
	out.close()
	print("LAYOUT_PROBE ", JSON.stringify(result))
	get_tree().quit()
''', encoding="utf-8")
config = project / "project.godot"
config.write_text(config.read_text(encoding="utf-8").replace('"res://addons/go_flora/plugin.cfg")', '"res://addons/go_flora/plugin.cfg", "res://addons/layout_probe/plugin.cfg")'), encoding="utf-8")
env = os.environ.copy()
env["APPDATA"] = str(project / ".scratch/profile")
env["LOCALAPPDATA"] = env["APPDATA"]
command = [str(root / ".scratch/godot-portable/godot.exe"), "--language", "en", "--headless", "--editor", "--path", str(project), "--resolution", "1152x900", "demo.tscn"]
process = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=90, env=env)
(project / "probe.log").write_text(process.stdout + process.stderr, encoding="utf-8")
print("Exit", process.returncode)
if process.returncode != 0 or "LAYOUT_PROBE " not in process.stdout or "ERROR:" in process.stdout + process.stderr:
    print(process.stdout + process.stderr)
    raise SystemExit(1)
if (project / "layout_probe.json").exists():
    result = json.loads((project / "layout_probe.json").read_text(encoding="utf-8"))
    print(json.dumps({"dock": result["enabled"]["dock_ancestors"][0], "root_content": result["enabled"]["dock_ancestors"][-2], "filesystem": result["enabled"]["filesystem"]}, indent=2))
else:
    print(process.stdout + process.stderr)
