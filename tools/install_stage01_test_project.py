"""Install an approved local addon ZIP and original QA scene into an existing project."""
import argparse
import datetime
import hashlib
import json
import re
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--project", type=Path, required=True)
parser.add_argument("--archive", type=Path, required=True)
args = parser.parse_args()
project = args.project.resolve()
archive = args.archive.resolve()
config_path = project / "project.godot"
if not config_path.is_file():
    raise SystemExit("Choose an existing Godot project with project.godot")
manifest = json.loads(archive.with_suffix(".json").read_text(encoding="utf-8"))
if hashlib.sha256(archive.read_bytes()).hexdigest() != manifest["sha256"]:
    raise SystemExit("Archive SHA-256 does not match its manifest")
with zipfile.ZipFile(archive) as package:
    if set(package.namelist()) != set(manifest["files"]) or package.testzip() is not None:
        raise SystemExit("Archive member/CRC validation failed")
    for name, digest in manifest["files"].items():
        target = (project / name).resolve()
        if not target.is_relative_to(project / "addons/go_flora") or hashlib.sha256(package.read(name)).hexdigest() != digest:
            raise SystemExit("Archive path/content validation failed")
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    backup = ROOT / "stages/01_painter_mvp/.scratch/install_backups" / (project.name + "-" + stamp)
    backup.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(config_path, backup / "project.godot")
    for name in ["addons/go_flora", "go_flora_stage01_demo"]:
        if (project / name).exists():
            shutil.copytree(project / name, backup / name)
    package.extractall(project)

scene_dir = project / "go_flora_stage01_demo"
scene_dir.mkdir(exist_ok=True)
demo = ROOT / "stages/01_painter_mvp/demo"
scene = (demo / "demo.tscn").read_text(encoding="utf-8")
scene = scene.replace('path="res://runtime_camera.gd"', 'path="res://go_flora_stage01_demo/runtime_camera.gd"')
scene = scene.split('[node name="SurfaceLegend"', 1)[0].rstrip() + "\n"
scene = scene.replace("draw_distance_m = 10.0", "draw_distance_m = 0.0")
scene_created = not (scene_dir / "demo.tscn").exists()
if scene_created:
    scene_dir.joinpath("demo.tscn").write_text(scene, encoding="utf-8")
for name in ["runtime_camera.gd", "runtime_camera.gd.uid"]:
    if not (scene_dir / name).exists():
        shutil.copyfile(demo / name, scene_dir / name)
if not (scene_dir / "inspect_placements.gd").exists():
    shutil.copyfile(ROOT / "tests/manual_inspect.gd", scene_dir / "inspect_placements.gd")
if not (scene_dir / "LICENSE").exists():
    shutil.copyfile(ROOT / "LICENSE", scene_dir / "LICENSE")
guide = """# GO_FLORA — Stage 01 manual QA

Open demo.tscn in Godot 4.7.2. Select Ground and press F to frame the surface, then select VegetationLayer.
Use the GO_FLORA dock (it may share tabs with Inspector). Paint set A to the left of origin and B to the right.
Defaults: radius 1 m, density 6, seed 42. A starts unlimited (0 m), B is 80 m.
Paint/Erase: LMB drag; Single: one click; release commits one undo step; Esc cancels.
Ctrl+Z / Ctrl+Shift+Z undo/redo. Navigate passes editor controls through.
Save, close and reopen the actual editor to verify persistence.
After painting set A, Edit Set in Inspector: change its distance to 20 m; keep B at 80 m.
Move the editor camera near/far. Record count must stay unchanged while old A cells hide, B remains visible.
Runtime F6: key 1 near, key 2 far, WASD movement. This complements editor-camera acceptance.
inspect_placements.gd is an optional read-only EditorScript snapshot (Script Editor > File > Run).

Two original primitive Mesh sources, two weighted sets, ground/tilted collider surfaces, yellow visual-only surface.
No Tree3D, external art, vegetation colliders or Stage 02 features. Original code/assets/docs: MIT (LICENSE).
INTERACTIVE_GUI_QA remains NOT_RUN until the owner performs the actions. No automatic merge or release.
"""
if not (scene_dir / "README.md").exists():
    scene_dir.joinpath("README.md").write_text(guide, encoding="utf-8")

def set_value(text, section, key, value, only_if_absent=False):
    pattern = rf"(?ms)(^\[{re.escape(section)}\][ \t]*\n)(.*?)(?=^\[|\Z)"
    found = re.search(pattern, text)
    if found is None:
        return text.rstrip() + f"\n\n[{section}]\n\n{key}={value}\n"
    body = found.group(2)
    setting = rf"(?m)^{re.escape(key)}=.*$"
    if re.search(setting, body):
        if only_if_absent:
            return text
        body = re.sub(setting, lambda _: key + "=" + value, body)
    else:
        body = body.rstrip() + f"\n{key}={value}\n\n"
    return text[:found.start(2)] + body + text[found.end(2):]

config = config_path.read_text(encoding="utf-8")
plugin = '"res://addons/go_flora/plugin.cfg"'
enabled = re.search(r"(?m)^enabled=(PackedStringArray\([^\n]*\))", config)
if enabled is None:
    enabled_value = f"PackedStringArray({plugin})"
else:
    enabled_value = enabled.group(1)
    if plugin not in enabled_value:
        separator = "" if enabled_value == "PackedStringArray()" else ", "
        enabled_value = enabled_value[:-1] + separator + plugin + ")"
config = set_value(config, "editor_plugins", "enabled", enabled_value)
config = set_value(config, "application", "run/main_scene", '"res://go_flora_stage01_demo/demo.tscn"', only_if_absent=True)
config_path.write_text(config, encoding="utf-8")
installed = {"project": str(project), "archive_sha256": manifest["sha256"], "version": manifest["version"],
             "scene": "res://go_flora_stage01_demo/demo.tscn", "backup": str(backup),
             "scene_created": scene_created, "existing_scene_files_preserved": True,
             "plugin_files_verified": all(hashlib.sha256((project / name).read_bytes()).hexdigest() == digest
                                          for name, digest in manifest["files"].items()),
             "INTERACTIVE_GUI_QA": "NOT_RUN"}
scene_dir.joinpath("installation.json").write_text(json.dumps(installed, indent=2) + "\n", encoding="utf-8")
print(json.dumps(installed, indent=2))
