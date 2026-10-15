"""Launch the existing Godot editor with an isolated profile for real GUI acceptance."""
import argparse
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--godot", type=Path, required=True)
args = parser.parse_args()
project = ROOT / "stages/01_painter_mvp/demo"
profile = ROOT / "stages/01_painter_mvp/evidence/.scratch/gui_profile"
profile.mkdir(parents=True, exist_ok=True)
editor_environment = os.environ.copy()
editor_environment["APPDATA"] = str(profile)
editor_environment["LOCALAPPDATA"] = str(profile)
log = open(profile / "editor_gui.log", "wb")
command = [str(args.godot.resolve()), "--language", "en", "--editor", "--path", str(project),
           "--rendering-method", "gl_compatibility", "--position", "80,50", "--resolution", "1500x900", "demo.tscn"]
process = subprocess.Popen(command, env=editor_environment, stdout=log, stderr=log)
print("Godot GUI PID", process.pid, flush=True)
raise SystemExit(process.wait())
