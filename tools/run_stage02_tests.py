"""Isolated Stage 01 regression and Stage 02 native probes (never owner's project)."""
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / "stages/02_imported_alpha_vegetation"


def prepare(project):
    project.mkdir(parents=True, exist_ok=True)
    shutil.copytree(ROOT / "stages/01_painter_mvp/demo", project, dirs_exist_ok=True,
                    ignore=shutil.ignore_patterns(".godot", ".scratch", "addons", "tests"))
    shutil.copytree(ROOT / "addons/go_flora", project / "addons/go_flora", dirs_exist_ok=True)
    shutil.copytree(ROOT / "tests", project / "tests", dirs_exist_ok=True,
                    ignore=shutil.ignore_patterns("__pycache__", ".scratch"))
    fixtures = STAGE / "demo/fixtures"
    if fixtures.exists():
        shutil.copytree(fixtures, project / "fixtures", dirs_exist_ok=True)
    return project


def run_case(godot, project, output, name, flags, marker):
    output.mkdir(parents=True, exist_ok=True)
    profile = output / ".scratch/profile"
    profile.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    if os.name == "nt":
        env.update(APPDATA=str(profile), LOCALAPPDATA=str(profile))
    command = [str(godot.resolve()), "--language", "en", "--path", str(project), *flags]
    try:
        with (output / f"{name}.log").open("w", encoding="utf-8") as stream:
            process = subprocess.Popen(command, stdout=stream, stderr=subprocess.STDOUT, env=env)
            deadline = time.monotonic() + 180
            while process.poll() is None:
                time.sleep(0.1)
                current = (output / f"{name}.log").read_text(encoding="utf-8", errors="replace")
                if "SCRIPT ERROR" in current or time.monotonic() > deadline:
                    process.terminate()
                    process.wait(timeout=10)
                    break
        log = (output / f"{name}.log").read_text(encoding="utf-8", errors="replace")
        failed = process.returncode != 0 or any(s in log for s in ["FAIL ", "ERROR:", "SCRIPT ERROR"]) or marker not in log
        row = dict(case=name, status="FAIL" if failed else "PASS", exit_code=process.returncode, command=command)
    except (subprocess.TimeoutExpired, OSError) as error:
        log = str(error)
        row = dict(case=name, status="FAIL", command=command)
    (output / f"{name}.log").write_text(log, encoding="utf-8")
    print(name, row["status"], flush=True)
    if row["status"] == "FAIL":
        print(log[-16000:], flush=True)
    return row


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--phase", choices=["baseline", "final", "stage02"], default="stage02")
    parser.add_argument("--label", default="")
    args = parser.parse_args()
    output = STAGE / "evidence/.scratch" / (args.phase + args.label)
    if (output / "summary.json").exists() or list(output.glob("*.log")):
        archive = STAGE / "evidence/.scratch/attempts" / (args.phase + "-" + str(time.time_ns()))
        archive.mkdir(parents=True)
        for path in list(output.glob("*.log")) + list(output.glob("summary.json")):
            shutil.copyfile(path, archive / path.name)
    project = prepare(output / "project")
    rows = []
    cases = [("version", ["--headless", "--version"], "4.7.2.stable.official.ed1daf0bf"),
             ("import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED")]
    if args.phase in {"baseline", "final"}:
        cases += [("stage01_core", ["--headless", "--script", "tests/test_stage01.gd"], "PASS scene_saved_for_fresh_process"),
                  ("stage01_reopen", ["--headless", "--script", "tests/test_stage01_reopen.gd"], "PASS fresh_process_scene_reopen")]
    else:
        cases += [("stage02_core", ["--headless", "--script", "tests/test_stage02.gd"], "PASS STAGE02_COMPLETE"),
                  ("stage02_reopen", ["--headless", "--script", "tests/test_stage02_reopen.gd"], "PASS STAGE02_REOPEN")]
    for name, flags, marker in cases:
        rows.append(run_case(args.godot, project, output, name, flags, marker))
    if args.phase in {"baseline", "final", "stage02"}:
        editor = prepare(output / "editor")
        harness = "editor_stage02_harness" if args.phase == "stage02" else "editor_harness"
        config = editor / "project.godot"
        config.write_text(config.read_text(encoding="utf-8").replace(
            'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg")',
            f'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg", "res://tests/{harness}/plugin.cfg")'), encoding="utf-8")
        rows.append(run_case(args.godot, editor, output, "stage01_editor_import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED"))
        marker = "PASS STAGE02_EDITOR_COMPLETE" if args.phase == "stage02" else "PASS EDITOR_API reenable_one_plugin_no_parse_errors_data_rendered"
        rows.append(run_case(args.godot, editor, output, harness, ["--headless", "--editor", "demo.tscn"], marker))
    result = dict(phase=args.phase, engine_sha256=hashlib.sha256(args.godot.read_bytes()).hexdigest(), probes=rows,
                  INTERACTIVE_GUI_QA="NOT_RUN", scope="headless automatic / native Editor API")
    (output / "summary.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return int(any(r["status"] == "FAIL" for r in rows))


if __name__ == "__main__":
    raise SystemExit(main())
