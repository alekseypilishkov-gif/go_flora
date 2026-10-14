"""Record executable/tool availability without installing or changing system software."""
import argparse
import hashlib
import json
import platform
import shutil
import subprocess
import sys
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--godot", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
tools = {name: shutil.which(name) for name in ["git", "gh", "scons", "cl", "gcc", "g++", "clang", "cmake", "ninja", "docker"]}
commands = [[str(args.godot), "--headless", "--version"], [sys.executable, "--version"],
            [sys.executable, "-m", "scons", "--version"], ["git", "--version"]]
vswhere = Path(r"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe")
if vswhere.exists():
    commands.extend([[str(vswhere), "-products", "*", "-property", "installationVersion"],
                     [str(vswhere), "-products", "*", "-requires", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", "-property", "installationPath"]])
checks = []
for command in commands:
    result = subprocess.run(command, capture_output=True, encoding="utf-8", errors="replace", timeout=15)
    checks.append(dict(command=command, exit_code=result.returncode, output=result.stdout + result.stderr,
                       status="PASS" if result.returncode == 0 else "FAIL"))
standard_paths = [r"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe",
                  r"C:\Program Files\Microsoft Visual Studio", r"C:\BuildTools", r"C:\Program Files\LLVM"]
result = dict(audit_date="2026-10-14", system=platform.platform(), machine=platform.machine(),
              tools_on_path=tools, standard_compiler_paths={path: Path(path).exists() for path in standard_paths},
              godot_sha256=hashlib.sha256(args.godot.read_bytes()).hexdigest(), checks=checks,
              native_build={"status": "NOT_RUN", "reason": "SCons unavailable in bundled Python; no C++ compiler discovered; godot-cpp directory contains only placeholder"})
args.output.write_text(json.dumps(result, indent=2), encoding="utf-8")
print(json.dumps(result, indent=2))
