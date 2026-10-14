"""Reproducible Stage 00 probes; outputs stay under ignored .scratch/."""
import argparse
import json
import os
import shutil
import subprocess
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent


def run(godot, project, name, args, outputs):
    command = [str(godot), "--language", "en", "--path", str(project), *args]
    probe_environment = os.environ.copy()
    profile = HERE / ".scratch" / "profile"
    profile.mkdir(parents=True, exist_ok=True)
    if os.name == "nt":
        probe_environment["APPDATA"] = str(profile)
        probe_environment["LOCALAPPDATA"] = str(profile)
    try:
        result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=90, env=probe_environment)
        log = result.stdout + result.stderr
        status = "FAIL" if result.returncode or "FAIL " in log or "SCRIPT ERROR" in log or "ERROR:" in log else "PASS"
        entry = dict(id=name, status=status, exit_code=result.returncode, command=command)
    except (subprocess.TimeoutExpired, OSError) as error:
        log = str(error)
        entry = dict(id=name, status="FAIL", command=command, error=log)
    (outputs / (name + ".log")).write_text(log, encoding="utf-8")
    print(name, entry["status"])
    print(log)
    return entry


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--tree3d-archive", type=Path)
    parser.add_argument("--render", choices=["gl_compatibility", "mobile", "forward_plus"])
    args = parser.parse_args()
    project = HERE / "probes"
    outputs = HERE / ".scratch" / "runs"
    outputs.mkdir(parents=True, exist_ok=True)
    results = []
    if args.render:
        results.append(run(args.godot, project, "alpha_" + args.render,
                           ["--rendering-method", args.render, "--script", "alpha_probe.gd"], outputs))
    else:
        results.append(run(args.godot, project, "editor", ["--headless", "--editor", "--quit-after", "15"], outputs))
        for name in ["runtime", "reopen", "alpha"]:
            results.append(run(args.godot, project, name, ["--headless", "--script", name + "_probe.gd"], outputs))
        if args.tree3d_archive:
            tree_project = HERE / ".scratch" / "tree3d-import"
            tree_project.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(project / "project.godot", tree_project / "project.godot")
            # Do not enable the unrelated editor plugin in the isolated extension project.
            text = (tree_project / "project.godot").read_text(encoding="utf-8")
            (tree_project / "project.godot").write_text(text.split("[editor_plugins]")[0], encoding="utf-8")
            shutil.copyfile(project / "tree3d_probe.gd", tree_project / "tree3d_probe.gd")
            with zipfile.ZipFile(args.tree3d_archive) as archive:
                for item in archive.infolist():
                    normalized = item.filename.replace("\\", "/")
                    offset = normalized.find("Tree3D/")
                    if offset < 0 or item.is_dir():
                        continue
                    target = tree_project / "addons" / normalized[offset:]
                    if not target.resolve().is_relative_to(tree_project.resolve()):
                        raise ValueError("Unsafe archive path")
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(archive.read(item))
            results.append(run(args.godot, tree_project, "tree3d_editor", ["--headless", "--editor", "--quit-after", "15"], outputs))
            results.append(run(args.godot, tree_project, "tree3d", ["--headless", "--script", "tree3d_probe.gd"], outputs))
    summary = outputs / ("summary_" + (args.render or "headless") + ".json")
    summary.write_text(json.dumps(results, indent=2), encoding="utf-8")
    return 1 if any(item["status"] == "FAIL" for item in results) else 0


if __name__ == "__main__":
    raise SystemExit(main())
