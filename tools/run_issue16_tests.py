"""Issue #16 isolated warnings/regression probes; never opens TEST_FLORA."""
import argparse
import hashlib
import json
import shutil
import subprocess
import time
from pathlib import Path
from run_stage02_tests import ROOT, prepare, run_case
BASE = "ce3391049e4427625c70b6ffe145b2aaa7ab91dc"
UPDATE = ROOT / "stages/02_imported_alpha_vegetation/updates/05_configuration_warning_filter"
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--label", required=True)
    parser.add_argument("--phase", choices=["core", "targeted", "all"], default="all")
    args = parser.parse_args()
    output = UPDATE / "evidence/runs" / args.label
    if output.exists():
        raise ValueError("Immutable evidence: choose a new label")
    output.mkdir(parents=True)
    work = ROOT / ".scratch/qa016" / (args.label + "-" + str(time.time_ns()))
    rows = []
    def case(project, name, flags, marker):
        row = run_case(args.godot, project, output, name, flags, marker,
                       profile_path=work / "profiles" / name)
        rows.append(row)
        return row["status"] == "PASS"
    candidate = prepare(work / "candidate")
    case(candidate, "version", ["--headless", "--version"], "4.7.2.stable.official.ed1daf0bf")
    imported = case(candidate, "import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED")
    if imported:
        core = case(candidate, "warnings_core", ["--headless", "--script", "tests/test_issue16_warnings.gd"], "PASS ISSUE16_CORE_COMPLETE")
        if core:
            case(candidate, "warnings_reopen", ["--headless", "--script", "tests/test_issue16_reopen.gd"], "PASS ISSUE16_REOPEN_RECORDS_ARCHIVE_WARNINGS")
    if args.phase != "core" and imported:
        baseline = prepare(work / "baseline")
        target = (baseline / "addons/go_flora").resolve()
        if not target.is_relative_to((ROOT / ".scratch/qa016").resolve()):
            raise ValueError("Baseline must remain disposable")
        shutil.rmtree(target)
        names = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", BASE, "--", "addons/go_flora"], cwd=ROOT, text=True).splitlines()
        for name in names:
            path = baseline / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(subprocess.check_output(["git", "show", f"{BASE}:{name}"], cwd=ROOT))
        if case(baseline, "baseline_import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED"):
            left = case(baseline, "renderer_baseline", ["--headless", "--script", "tests/test_issue16_render_parity.gd"], "PASS ISSUE16_RENDER_SNAPSHOT")
            right = case(candidate, "renderer_candidate", ["--headless", "--script", "tests/test_issue16_render_parity.gd"], "PASS ISSUE16_RENDER_SNAPSHOT")
            if left and right:
                a = json.loads((baseline / ".scratch/issue16_render_snapshot.json").read_text())
                b = json.loads((candidate / ".scratch/issue16_render_snapshot.json").read_text())
                rows.append(dict(case="renderer_legacy_contract_parity", status="PASS" if a==b else "FAIL", base=BASE))
                (output / "renderer_baseline.json").write_text(json.dumps(a, indent=2)+"\n")
                (output / "renderer_candidate.json").write_text(json.dumps(b, indent=2)+"\n")
        harnesses = [("warnings_editor", "editor_warnings_harness", "PASS ISSUE16_EDITOR_COMPLETE")]
        if args.phase == "all":
            harnesses += [("diagnostics_editor", "editor_diagnostics_harness", "PASS ISSUE13_EDITOR_COMPLETE"), ("modal_editor", "editor_modal_harness", "PASS STAGE022_EDITOR_COMPLETE"), ("erase_palette_editor", "editor_erase_palette_harness", "PASS STAGE023_EDITOR_COMPLETE")]
        for name, harness, marker in harnesses:
            project = prepare(work / name)
            config = project / "project.godot"
            config.write_text(config.read_text().replace('enabled=PackedStringArray("res://addons/go_flora/plugin.cfg")', f'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg", "res://tests/{harness}/plugin.cfg")'))
            if case(project, name+"_import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED"):
                case(project, name, ["--headless", "--editor", "demo.tscn"], marker)
            for result in (project / ".scratch").glob("*results.json"):
                shutil.copyfile(result, output / (name+"_"+result.name))
    if args.phase == "all" and imported:
        for name, script, marker in [
            ("stage01", "test_stage01.gd", "PASS scene_saved_for_fresh_process"),
            ("stage01_reopen", "test_stage01_reopen.gd", "PASS fresh_process_scene_reopen"),
            ("stage02", "test_stage02.gd", "PASS STAGE02_COMPLETE"),
            ("stage02_reopen", "test_stage02_reopen.gd", "PASS STAGE02_REOPEN"),
            ("stage021", "test_stage021.gd", "PASS STAGE021_COMPLETE"),
            ("stage021_reopen", "test_stage021_reopen.gd", "PASS STAGE021_REOPEN"),
            ("stage023", "test_stage023.gd", "PASS STAGE023_CORE_COMPLETE"),
            ("stage023_catalog", "test_stage023_catalog.gd", "PASS STAGE023_CATALOG_COMPLETE"),
            ("diagnostic_states", "test_issue13_diagnostics.gd", "PASS ISSUE13_DIAGNOSTICS_COMPLETE")]:
            case(candidate, name, ["--headless", "--script", "tests/"+script], marker)
    core_result = candidate / ".scratch/issue16_core.json"
    if core_result.exists():
        shutil.copyfile(core_result, output / core_result.name)
    (output / "summary.json").write_text(json.dumps(dict(base=BASE,phase=args.phase,engine_sha256=hashlib.sha256(args.godot.read_bytes()).hexdigest(),probes=rows,INTERACTIVE_GUI_QA="NOT_RUN",scope="isolated headless/native Editor API; no TEST_FLORA"), indent=2)+"\n")
    print("RESULT", output.relative_to(ROOT))
    return int(any(r["status"]=="FAIL" for r in rows))
if __name__ == "__main__":
    raise SystemExit(main())
