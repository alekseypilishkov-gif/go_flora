"""Issue #9 isolated tests. Never reads or writes the owner's test project."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

from run_stage02_tests import ROOT, prepare, run_case

UPDATE = ROOT / "stages/02_imported_alpha_vegetation/updates/03_erase_palette_remove"
BASE = "f8917186ce7cdbfd1177a2a80610e500280d81d3"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--phase", choices=["core", "regression", "editor", "modal-gpu", "baseline"], default="core")
    parser.add_argument("--label", default="dev")
    parser.add_argument("--headless-editor", action="store_true", help="CI native API only; GPU pixels stay NOT_RUN")
    args = parser.parse_args()
    work = ROOT / ".scratch/qa023" / args.label / args.phase
    output = UPDATE / "evidence/runs" / args.label / args.phase
    if (output / "summary.json").exists():
        raise ValueError("Evidence is immutable; choose a new label")
    output.mkdir(parents=True, exist_ok=True)
    project = prepare(work / "project")
    profile = ROOT / ".scratch/qa023-profiles" / args.label / args.phase
    rows = []

    def case(name, flags, marker, target=project):
        row = run_case(args.godot, target, output, name, flags, marker, profile_path=profile)
        rows.append(row)
        return row["status"] == "PASS"

    if args.phase == "baseline":
        names = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", BASE, "--", "addons/go_flora"], cwd=ROOT, text=True).splitlines()
        for file in (project / "addons/go_flora").rglob("*"):
            if file.is_file() and file.relative_to(project).as_posix() not in names:
                file.unlink()
        for name in names:
            (project / name).write_bytes(subprocess.check_output(["git", "show", BASE + ":" + name], cwd=ROOT))
        # The dedicated profiling script supports both pinned old and new APIs.
    case("version", ["--headless", "--version"], "4.7.2.stable.official.ed1daf0bf")
    imported = case("import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED")
    if imported and args.phase in {"core", "baseline"}:
        if args.phase == "core":
            case("stage023_core", ["--headless", "--script", "tests/test_stage023.gd"], "PASS STAGE023_CORE_COMPLETE")
            case("stage023_catalog", ["--headless", "--script", "tests/test_stage023_catalog.gd"], "PASS STAGE023_CATALOG_COMPLETE")
        case("erase_profile", ["--headless", "--script", "tests/profile_stage023.gd"], "PASS ERASE_PROFILE_COMPLETE")
    if imported and args.phase == "regression":
        for name, script, marker in [
            ("stage01_core", "test_stage01", "PASS scene_saved_for_fresh_process"),
            ("stage01_reopen", "test_stage01_reopen", "PASS fresh_process_scene_reopen"),
            ("stage02_core", "test_stage02", "PASS STAGE02_COMPLETE"),
            ("stage02_reopen", "test_stage02_reopen", "PASS STAGE02_REOPEN"),
            ("ux_core", "test_stage021", "PASS STAGE021_COMPLETE"),
            ("ux_reopen", "test_stage021_reopen", "PASS STAGE021_REOPEN")]:
            case(name, ["--headless", "--script", "tests/" + script + ".gd"], marker)
    if imported and args.phase in {"regression", "editor", "modal-gpu"}:
        harnesses = ["editor_harness", "editor_stage02_harness", "editor_ux_harness", "editor_modal_harness"] if args.phase == "regression" else (["editor_modal_harness"] if args.phase == "modal-gpu" else ["editor_erase_palette_harness"])
        markers = ["PASS EDITOR_API reenable_one_plugin_no_parse_errors_data_rendered", "PASS STAGE02_EDITOR_COMPLETE", "PASS STAGE021_EDITOR_COMPLETE", "PASS STAGE022_EDITOR_COMPLETE"] if args.phase == "regression" else (["PASS STAGE022_EDITOR_COMPLETE"] if args.phase == "modal-gpu" else ["PASS STAGE023_EDITOR_COMPLETE"])
        for harness, marker in zip(harnesses, markers):
            editor = prepare(work / harness)
            config = editor / "project.godot"
            config.write_text(config.read_text(encoding="utf-8").replace(
                'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg")',
                f'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg", "res://tests/{harness}/plugin.cfg")') + ('\n[go_flora_qa]\nmodal_capture=true\n' if args.phase == "modal-gpu" else ''), encoding="utf-8")
            if case(harness + "_import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED", editor):
                gpu = ["--rendering-method", "gl_compatibility", "--position", "-10000,-10000", "--resolution", "1500x1000"] if args.phase in {"editor", "modal-gpu"} and not args.headless_editor else ["--headless"]
                case(harness, [*gpu, "--editor", "demo.tscn"], marker, editor)
                if harness == "editor_modal_harness":
                    case("modal_fresh_process_reopen", ["--headless", "--script", "tests/test_stage022_reopen.gd"], "PASS STAGE022_REOPEN", editor)
                if harness == "editor_erase_palette_harness":
                    case("palette_fresh_process_reopen", [*gpu, "--script", "tests/test_stage023_reopen.gd"], "PASS STAGE023_REOPEN_COMPLETE", editor)
                for file in (editor / ".scratch").glob("*results.json"):
                    (output / (harness + "_" + file.name)).write_bytes(file.read_bytes())
    for file in (project / ".scratch").glob("*.json"):
        (output / file.name).write_bytes(file.read_bytes())
    result = dict(phase=args.phase, source_base=BASE, engine_sha256=hashlib.sha256(args.godot.read_bytes()).hexdigest(), probes=rows, INTERACTIVE_GUI_QA="NOT_RUN")
    (output / "summary.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return int(any(row["status"] == "FAIL" for row in rows))


if __name__ == "__main__":
    raise SystemExit(main())
