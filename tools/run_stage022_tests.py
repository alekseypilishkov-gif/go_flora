"""Stage 02.2 isolated modal regression and legacy suites; no earlier evidence writes."""
import argparse
import hashlib
import json
import subprocess
import time
from pathlib import Path

from run_stage02_tests import ROOT, prepare, run_case

UPDATE = ROOT / "stages/02_imported_alpha_vegetation/updates/02_resource_picker_modal_fix"
CONFLICT = "Attempting to make child window exclusive, but the parent window already has another exclusive child"
LEGACY_REF = "1c61bf1fcd059cfb4d559eeabac806c684ecfddb"


def prepare_legacy(project):
    """Reconstruct only the old addon in a newly created disposable copy."""
    project = prepare(project)
    target = (project / "addons/go_flora").resolve()
    if not target.is_relative_to((UPDATE / "evidence/.scratch").resolve()):
        raise ValueError("Legacy reproduction must stay inside the new update's scratch")
    names = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", LEGACY_REF, "--", "addons/go_flora"], cwd=ROOT, text=True).splitlines()
    for path in target.rglob("*"):
        if path.is_file() and path.relative_to(project).as_posix() not in names:
            path.unlink()  # Only extra files in this fresh, verified scratch addon.
    for name in names:
        path = project / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(subprocess.check_output(["git", "show", LEGACY_REF + ":" + name], cwd=ROOT))
    return project


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True, type=Path)
    parser.add_argument("--phase", choices=["repro", "regression", "modal"], default="modal")
    parser.add_argument("--gpu-editor", action="store_true", help="Native editor API on GPU, not physical mouse GUI QA")
    args = parser.parse_args()
    output = UPDATE / "evidence/.scratch" / (args.phase + ("-gpu" if args.gpu_editor else "") + "-" + str(time.time_ns()))
    profile = ROOT / ".scratch/qa022-profiles" / output.name.rsplit("-", 1)[-1]

    def case(project, name, flags, marker):
        return run_case(args.godot, project, output, name, flags, marker, profile_path=profile)

    prepare_project = prepare_legacy if args.phase == "repro" else prepare
    project = prepare_project(output / "project")
    rows = [case(project, "version", ["--headless", "--version"], "4.7.2.stable.official.ed1daf0bf"),
            case(project, "import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED")]
    scripts = []
    harnesses = ["editor_modal_harness"]
    if args.phase == "regression":
        scripts = [("stage01_core", "test_stage01.gd", "PASS scene_saved_for_fresh_process"),
                   ("stage01_reopen", "test_stage01_reopen.gd", "PASS fresh_process_scene_reopen"),
                   ("stage02_core", "test_stage02.gd", "PASS STAGE02_COMPLETE"),
                   ("stage02_reopen", "test_stage02_reopen.gd", "PASS STAGE02_REOPEN"),
                   ("ux_core", "test_stage021.gd", "PASS STAGE021_COMPLETE"),
                   ("ux_reopen", "test_stage021_reopen.gd", "PASS STAGE021_REOPEN")]
        harnesses = ["editor_harness", "editor_stage02_harness", "editor_ux_harness"]
    for name, script, marker in scripts:
        rows.append(case(project, name, ["--headless", "--script", "tests/" + script], marker))
    for harness in harnesses:
        editor = prepare_project(output / harness)
        config = editor / "project.godot"
        text = config.read_text(encoding="utf-8").replace(
            'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg")',
            f'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg", "res://tests/{harness}/plugin.cfg")')
        text += '\n[go_flora_qa]\nmodal_repro=' + ("true" if args.phase == "repro" else "false") + '\nmodal_capture=' + ("true" if args.gpu_editor else "false") + '\n'
        config.write_text(text, encoding="utf-8")
        rows.append(case(editor, harness + "_import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED"))
        flags = ["--headless"] if not args.gpu_editor else ["--rendering-method", "gl_compatibility", "--position", "-10000,-10000", "--resolution", "1500x1000"]
        marker = {"editor_harness": "PASS EDITOR_API reenable_one_plugin_no_parse_errors_data_rendered", "editor_stage02_harness": "PASS STAGE02_EDITOR_COMPLETE",
                  "editor_ux_harness": "PASS STAGE021_EDITOR_COMPLETE", "editor_modal_harness": "PASS STAGE022_EDITOR_COMPLETE"}[harness]
        if args.phase == "repro":
            marker = "REPRO STAGE022_COMPLETE"
        row = case(editor, harness, [*flags, "--editor", "demo.tscn"], marker)
        if args.phase == "repro":
            log = (output / (harness + ".log")).read_text(encoding="utf-8")
            row["legacy_picker_observed"] = "FAIL" if CONFLICT in log else "NOT_REPRODUCED"
            row["reproduction_probe"] = "PASS" if CONFLICT in log and marker in log else "FAIL"
        rows.append(row)
        if args.phase == "modal":
            rows.append(case(editor, "modal_fresh_process_reopen", ["--headless", "--script", "tests/test_stage022_reopen.gd"], "PASS STAGE022_REOPEN"))
    summary = dict(phase=args.phase, engine_sha256=hashlib.sha256(args.godot.read_bytes()).hexdigest(), probes=rows,
                   INTERACTIVE_GUI_QA="NOT_RUN", OWNER_REPORTED_GUI_FAIL="0.2.1-dev PNG Quick Load; Issue #8")
    if args.phase == "repro":
        summary["legacy_addon_ref"] = LEGACY_REF
    (output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print("RESULT", output.relative_to(ROOT), flush=True)
    return int(any((r.get("reproduction_probe", r["status"])) == "FAIL" for r in rows))


if __name__ == "__main__":
    raise SystemExit(main())
