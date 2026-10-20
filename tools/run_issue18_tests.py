"""Issue #18 isolation, Creator, fresh-process and unchanged historical regressions."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
sys.dont_write_bytecode = True
from run_stage02_tests import ROOT, prepare
UPDATE = ROOT / "stages/02_imported_alpha_vegetation/updates/06_source_identity_fix"


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--godot", type=Path, required=True)
    p.add_argument("--label", required=True)
    p.add_argument("--phase", choices=["targeted", "regressions", "all", "graphics"], default="targeted")
    a = p.parse_args()
    output = UPDATE / "evidence/runs" / a.label
    if output.exists():
        raise ValueError("Immutable evidence: choose another label")
    output.mkdir(parents=True)
    work = ROOT / ".scratch/qa018" / (a.label + "-" + str(time.time_ns()))
    work.mkdir(parents=True)
    engine = a.godot.resolve()
    if os.name == "nt":
        # Portable Godot ignores APPDATA when _sc_ is beside the executable.
        # Give this run its own binary directory and editor_data, never the caller's.
        engine_dir = work / "engine"
        engine_dir.mkdir()
        engine = engine_dir / "godot.exe"
        shutil.copyfile(a.godot, engine)
        (engine_dir / "_sc_").touch()
    rows = []

    def case(project, name, flags, marker, allowed_error=""):
        profile = work / "profiles" / name
        profile.mkdir(parents=True)
        env = os.environ.copy()
        env.update(APPDATA=str(profile), LOCALAPPDATA=str(profile))
        # Linux CI profiles remain local to the disposable job as well.
        env.update(XDG_CONFIG_HOME=str(profile / "config"), XDG_CACHE_HOME=str(profile / "cache"), XDG_DATA_HOME=str(profile / "data"))
        command = [str(engine), "--language", "en", "--path", str(project), *flags]
        options = {}
        if os.name == "nt" and "--headless" not in flags:
            startup = subprocess.STARTUPINFO()
            startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startup.wShowWindow = 0
            options["startupinfo"] = startup
        log_path = output / (name + ".log")
        try:
            with log_path.open("w", encoding="utf-8") as stream:
                process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=stream, stderr=subprocess.STDOUT, **options)
                deadline = time.monotonic() + 180
                while process.poll() is None:
                    time.sleep(0.1)
                    current = log_path.read_text(encoding="utf-8", errors="replace")
                    if "SCRIPT ERROR" in current or time.monotonic() > deadline:
                        process.terminate()
                        process.wait(timeout=10)
                        break
            log = log_path.read_text(encoding="utf-8", errors="replace")
            errors = [line for line in log.splitlines() if "ERROR:" in line and (not allowed_error or allowed_error not in line)]
            ok = process.returncode == 0 and marker in log and "SCRIPT ERROR" not in log and "FAIL " not in log and not errors
            row = dict(case=name, status="PASS" if ok else "FAIL", exit_code=process.returncode, command=command,
                       profile=str(profile), unexpected_errors=errors, expected_error=allowed_error)
        except Exception as error:
            ok = False
            row = dict(case=name, status="FAIL", command=command, error=str(error))
            log = str(error)
        rows.append(row)
        print(name, row["status"], flush=True)
        if not ok:
            print(log[-6500:], flush=True)
        return ok

    def editor(name, harness, marker, flags=None, allowed_error=""):
        project = prepare(work / name)
        config = project / "project.godot"
        config.write_text(config.read_text().replace('enabled=PackedStringArray("res://addons/go_flora/plugin.cfg")',
            f'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg", "res://tests/{harness}/plugin.cfg")'))
        if case(project, name + "_import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED"):
            success = case(project, name, [*(flags or ["--headless"]), "--editor", "demo.tscn"], marker, allowed_error)
            for directory in [project / "identity", project / ".scratch"]:
                if directory.exists():
                    target = output / name
                    target.mkdir(exist_ok=True)
                    for path in directory.glob("*"):
                        if path.is_file() and path.suffix in {".json", ".tscn", ".tres", ".png"}:
                            shutil.copyfile(path, target / path.name)
            return project, success
        return project, False

    candidate = prepare(work / "candidate")
    case(candidate, "version", ["--headless", "--version"], "4.7.2.stable.official.ed1daf0bf")
    if a.phase in {"targeted", "all"}:
        project, success = editor("identity", "editor_identity_harness", "ISSUE18_CANONICAL_COMPLETE",
                                  allowed_error="Cannot save file 'res://identity/missing_directory/error.tres'")
        if success:
            case(project, "identity_reopen", ["--headless", "--script", "tests/test_issue18_reopen.gd"], "ISSUE18_REOPEN_COMPLETE")
            shutil.copyfile(project / "identity/reopen_results.json", output / "identity/reopen_results.json")
    if a.phase in {"regressions", "all"}:
        if case(candidate, "regression_import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED"):
            for name, script, marker in [
                ("stage01", "test_stage01.gd", "PASS scene_saved_for_fresh_process"),
                ("stage01_reopen", "test_stage01_reopen.gd", "PASS fresh_process_scene_reopen"),
                ("stage02", "test_stage02.gd", "PASS STAGE02_COMPLETE"),
                ("stage02_reopen", "test_stage02_reopen.gd", "PASS STAGE02_REOPEN"),
                ("stage021", "test_stage021.gd", "PASS STAGE021_COMPLETE"),
                ("stage021_reopen", "test_stage021_reopen.gd", "PASS STAGE021_REOPEN"),
                ("stage023", "test_stage023.gd", "PASS STAGE023_CORE_COMPLETE"),
                ("stage023_catalog", "test_stage023_catalog.gd", "PASS STAGE023_CATALOG_COMPLETE"),
                ("issue13", "test_issue13_diagnostics.gd", "PASS ISSUE13_DIAGNOSTICS_COMPLETE"),
                ("issue16", "test_issue16_warnings.gd", "PASS ISSUE16_CORE_COMPLETE"),
                ("issue16_reopen", "test_issue16_reopen.gd", "PASS ISSUE16_REOPEN_RECORDS_ARCHIVE_WARNINGS")]:
                case(candidate, name, ["--headless", "--script", "tests/" + script], marker)
        for name, harness, marker in [
            ("stage01_editor", "editor_harness", "PASS EDITOR_API reenable_one_plugin_no_parse_errors_data_rendered"),
            ("stage02_editor", "editor_stage02_harness", "PASS STAGE02_EDITOR_COMPLETE"),
            ("stage021_editor", "editor_ux_harness", "PASS STAGE021_EDITOR_COMPLETE"),
            ("stage022_editor", "editor_modal_harness", "PASS STAGE022_EDITOR_COMPLETE"),
            ("stage023_editor", "editor_erase_palette_harness", "PASS STAGE023_EDITOR_COMPLETE"),
            ("issue13_editor", "editor_diagnostics_harness", "PASS ISSUE13_EDITOR_COMPLETE"),
            ("issue16_editor", "editor_warnings_harness", "PASS ISSUE16_EDITOR_COMPLETE")]:
            project, success = editor(name, harness, marker)
            if name == "stage022_editor" and success:
                case(project, "stage022_reopen", ["--headless", "--script", "tests/test_stage022_reopen.gd"], "PASS STAGE022_REOPEN")
    if a.phase == "graphics":
        editor("graphical_save", "editor_identity_save_harness", "ISSUE18_GRAPHICAL_SAVE_COMPLETE", ["--rendering-method", "gl_compatibility"])
    (output / "summary.json").write_text(json.dumps(dict(probes=rows, engine_sha256=hashlib.sha256(engine.read_bytes()).hexdigest(),
        engine=str(engine), portable_editor_cache_isolated=os.name=="nt",
        INTERACTIVE_GUI_QA="NOT_RUN", scope="Isolated automatic headless/native Editor API; graphics is a separate renderer gate"), indent=2) + "\n")
    return int(any(r["status"] == "FAIL" for r in rows))


if __name__ == "__main__":
    raise SystemExit(main())
