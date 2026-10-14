"""Install original repository addon/tests into the demonstrator. No native dependencies."""
import argparse
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--project", type=Path, default=ROOT / "stages/01_painter_mvp/demo")
args = parser.parse_args()
project = args.project.resolve()
if not project.is_relative_to(ROOT):
    raise SystemExit("Prepared projects must stay inside the GO_FLORA workspace")
project.mkdir(parents=True, exist_ok=True)
shutil.copytree(ROOT / "addons/go_flora", project / "addons/go_flora", dirs_exist_ok=True,
                ignore=shutil.ignore_patterns(".godot", "__pycache__"))
shutil.copyfile(ROOT / "LICENSE", project / "addons/go_flora/LICENSE")
shutil.copytree(ROOT / "tests", project / "tests", dirs_exist_ok=True,
                ignore=shutil.ignore_patterns("__pycache__", ".scratch"))
print("PASS prepared original addon and tests in", project)
