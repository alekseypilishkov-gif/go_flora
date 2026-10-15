"""Render the original demo once; this is not an interactive mouse acceptance."""
import argparse
import json
import shutil
from pathlib import Path

from run_stage02_tests import STAGE, prepare, run_case

parser = argparse.ArgumentParser()
parser.add_argument("--godot", required=True, type=Path)
args = parser.parse_args()
output = STAGE / "evidence/.scratch/demo_gpu"
project = prepare(output / "project")
for name in ["demo.tscn", "project.godot", "runtime_camera.gd"]:
    shutil.copyfile(STAGE / "demo" / name, project / name)
rows = [run_case(args.godot, project, output, "import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED"),
        run_case(args.godot, project, output, "capture", ["--rendering-method", "gl_compatibility", "--position", "-10000,-10000", "--resolution", "1280x720", "--script", "tests/capture_stage02_demo.gd"], "PASS DEMO_GPU")]
(output / "summary.json").write_text(json.dumps(rows, indent=2) + "\n", encoding="utf-8")
raise SystemExit(int(any(r["status"] == "FAIL" for r in rows)))
