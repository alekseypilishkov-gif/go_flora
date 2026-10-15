"""Validate the plugin ZIP in a standalone project, including update preservation."""
import argparse
import hashlib
import json
import os
import subprocess
import sys
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--godot", type=Path, required=True)
parser.add_argument("--archive", type=Path)
args = parser.parse_args()
archive = args.archive or max((ROOT / "stages/01_painter_mvp/.scratch/packages").glob("*.zip"), key=lambda path: path.stat().st_mtime_ns)
project = ROOT / "stages/01_painter_mvp/evidence/.scratch/package_tests" / uuid.uuid4().hex
project.mkdir(parents=True)
config = project / "project.godot"
config.write_text('config_version=5\n\n[application]\nconfig/name="GO_FLORA standalone ZIP check"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding="utf-8")
command = [sys.executable, str(ROOT / "tools/install_stage01_test_project.py"), "--project", str(project), "--archive", str(archive)]
first = subprocess.run(command, capture_output=True, text=True, check=True)
scene = project / "go_flora_stage01_demo/demo.tscn"
scene.write_text(scene.read_text(encoding="utf-8").rstrip() + "\n; owner-preservation-regression\n", encoding="utf-8")
before = hashlib.sha256(scene.read_bytes()).hexdigest()
second = subprocess.run(command, capture_output=True, text=True, check=True)
assert hashlib.sha256(scene.read_bytes()).hexdigest() == before, "Addon update overwrote the owner's scene"
assert json.loads(second.stdout)["scene_created"] is False
print("PASS package_install_and_update_preserves_owner_scene", flush=True)
environment = os.environ.copy()
if os.name == "nt":
    environment["APPDATA"] = str(project / ".scratch/profile")
    environment["LOCALAPPDATA"] = environment["APPDATA"]
results = [{"case": "package_install_and_update_preserves_owner_scene", "status": "PASS"}]
for name, flags in [("package_editor_import", ["--editor", "--import"]), ("package_scene_smoke", ["--quit-after", "10"])]:
    native_command = [str(args.godot.resolve()), "--language", "en", "--headless", "--path", str(project), *flags]
    process = subprocess.run(native_command, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=90, env=environment)
    log = process.stdout + process.stderr
    failed = process.returncode != 0 or "ERROR:" in log or "SCRIPT ERROR" in log
    if name == "package_editor_import":
        failed = failed or "GO_FLORA_PLUGIN_ENABLED" not in log
    (project / (name + ".log")).write_text(log, encoding="utf-8")
    results.append({"case": name, "status": "FAIL" if failed else "PASS", "command": native_command, "exit_code": process.returncode})
    print(name, results[-1]["status"], flush=True)
    if failed:
        print(log)
(project / "validation.json").write_text(json.dumps({"results": results, "scope": "Standalone ZIP native smoke, not real GUI acceptance"}, indent=2) + "\n", encoding="utf-8")
raise SystemExit(1 if any(row["status"] == "FAIL" for row in results) else 0)
