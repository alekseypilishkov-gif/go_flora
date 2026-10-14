"""Run real Godot processes; classify logs without making interactive GUI claims."""
import argparse
import json
import os
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--godot", type=Path, required=True)
parser.add_argument("--build-demo", action="store_true")
args = parser.parse_args()
demo_project = ROOT / "stages/01_painter_mvp/demo"
output = ROOT / "stages/01_painter_mvp/evidence/.scratch/runs"
output.mkdir(parents=True, exist_ok=True)
profile = ROOT / "stages/01_painter_mvp/evidence/.scratch/profile"
profile.mkdir(parents=True, exist_ok=True)
project = demo_project if args.build_demo else output.parent / "test_project"
if not args.build_demo:
    # Keep automated scene/cache writes away from the owner's interactive demo.
    shutil.copytree(demo_project, project, dirs_exist_ok=True,
                    ignore=shutil.ignore_patterns(".godot", ".scratch"))
probe_environment = os.environ.copy()
if os.name == "nt":
    probe_environment["APPDATA"] = str(profile)
    probe_environment["LOCALAPPDATA"] = str(profile)

cases = [("version", ["--headless", "--version"]),
         ("editor_import", ["--headless", "--editor", "--import"])]
if args.build_demo:
    cases.append(("create_demo", ["--headless", "--script", "tests/create_demo.gd"]))
else:
    cases += [("core", ["--headless", "--script", "tests/test_stage01.gd"]),
              ("fresh_reopen", ["--headless", "--script", "tests/test_stage01_reopen.gd"])]
    editor_project = output.parent / "editor_project"
    shutil.copytree(project, editor_project, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".godot", ".scratch"))
    config = editor_project / "project.godot"
    config.write_text(config.read_text(encoding="utf-8").replace(
        'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg")',
        'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg", "res://tests/editor_harness/plugin.cfg")'), encoding="utf-8")
    cases.append(("editor_api", ["--headless", "--editor", "--path", str(editor_project), "demo.tscn"]))
results = []
for name, flags in cases:
    command = [str(args.godot.resolve()), "--language", "en", "--path", str(project), *flags]
    try:
        process = subprocess.run(command, capture_output=True, encoding="utf-8", errors="replace", timeout=120, env=probe_environment)
        log = process.stdout + process.stderr
        failed = process.returncode != 0 or "FAIL " in log or "ERROR:" in log or "SCRIPT ERROR" in log
        expected_markers = {"version": "4.7.2.stable.official.ed1daf0bf",
                            "editor_import": "GO_FLORA_PLUGIN_ENABLED",
                            "core": "PASS scene_saved_for_fresh_process",
                            "fresh_reopen": "PASS fresh_process_scene_reopen",
                            "editor_api": "PASS EDITOR_API reenable_one_plugin_no_parse_errors_data_rendered",
                            "create_demo": "PASS"}
        failed = failed or expected_markers[name] not in log
        result = dict(case=name, status="FAIL" if failed else "PASS", exit_code=process.returncode, command=command)
    except (subprocess.TimeoutExpired, OSError) as error:
        log = str(error)
        result = dict(case=name, status="FAIL", command=command, error=log)
    (output / (name + ".log")).write_text(log, encoding="utf-8")
    results.append(result)
    print(name, result["status"], flush=True)
    print(log, flush=True)
(output / "summary.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
raise SystemExit(1 if any(row["status"] == "FAIL" for row in results) else 0)
