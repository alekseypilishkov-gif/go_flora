import json
import os
import re
import shutil
import subprocess
import uuid
from pathlib import Path

root = Path(__file__).resolve().parents[1]
stage = root / "stages/01_painter_mvp"
project = stage / "evidence/.scratch" / ("width_baseline_" + uuid.uuid4().hex)
shutil.copytree(stage / "evidence/.scratch/editor_project", project,
                ignore=shutil.ignore_patterns(".godot", ".scratch"))
baseline = "51b137434c143b21f02a53430a00687f37c76395"
old = subprocess.run(["git", "show", baseline + ":addons/go_flora/editor/plugin.gd"],
                     cwd=root, capture_output=True, encoding="utf-8", check=True).stdout
(project / "addons/go_flora/editor/plugin.gd").write_text(old, encoding="utf-8")
environment = os.environ.copy()
environment["APPDATA"] = str(project / ".scratch/profile")
environment["LOCALAPPDATA"] = environment["APPDATA"]
command = [str(root / ".scratch/godot-portable/godot.exe"), "--language", "en", "--headless", "--editor", "--path", str(project), "demo.tscn"]
process = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=90, env=environment)
log = process.stdout + process.stderr
expected = ["FAIL EDITOR_API dock_shares_Scene_Import_tab_group", "FAIL EDITOR_API dynamic_status_and_counts_do_not_resize_dock", "FAIL EDITOR_API active_set_distance_visible_in_dock"]
output = stage / "updates/02_dock_width_distance/evidence"
output.mkdir(parents=True, exist_ok=True)
clean = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", log)
(output / "baseline_expected_fail.log").write_text("\n".join(line.rstrip() for line in clean.splitlines()).rstrip() + "\n", encoding="utf-8", newline="\n")
(output / "baseline_command.json").write_text(json.dumps({"baseline": baseline, "command": command, "exit_code": process.returncode, "expected_failures": expected}, indent=2) + "\n", encoding="utf-8")
assert process.returncode == 1 and all(marker in log for marker in expected), log
assert "ERROR:" not in log and "SCRIPT ERROR" not in log, log
assert sum(line.startswith("FAIL EDITOR_API") for line in log.splitlines()) == 3, log
print("PASS baseline exits 1 with exactly the three expected layout/distance failures")
print("\n".join(line for line in log.splitlines() if line.startswith("DOCK_WIDTH")))
