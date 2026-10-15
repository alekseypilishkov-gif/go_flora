"""Prepare a separate demo; no owner's project or previous stage evidence writes."""
import argparse
import shutil
from pathlib import Path

from run_stage02_tests import ROOT, STAGE, prepare, run_case

parser = argparse.ArgumentParser()
parser.add_argument("--godot", required=True, type=Path)
parser.add_argument("--build-demo", action="store_true", help="Rebuild the checked-in original demo scene")
args = parser.parse_args()
demo = STAGE / "demo"
if args.build_demo:
    output = STAGE / "evidence/.scratch/demo_build"
    project = prepare(output / "project")
    rows = [run_case(args.godot, project, output, "import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED"),
            run_case(args.godot, project, output, "create_demo", ["--headless", "--script", "tests/create_stage02_demo.gd"], "PASS STAGE02_DEMO")]
    if any(r["status"] == "FAIL" for r in rows):
        raise SystemExit(1)
    shutil.copyfile(project / ".scratch/stage02_demo.tscn", demo / "demo.tscn")
shutil.copytree(ROOT / "addons/go_flora", demo / "addons/go_flora", dirs_exist_ok=True)
shutil.copyfile(ROOT / "stages/01_painter_mvp/demo/runtime_camera.gd", demo / "runtime_camera.gd")
print("PASS prepared isolated Stage 02 demo:", demo / "project.godot")
