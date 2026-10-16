"""Issue #13 isolated contract/UI regressions; never touches TEST_FLORA."""
import argparse
import hashlib
import json
import shutil
import subprocess
import time
from pathlib import Path

from run_stage02_tests import ROOT, prepare, run_case

BASE = "fecf4fc9dd3e04aa79bf0d7b390dc24b3ab6511b"
UPDATE = ROOT / "stages/02_imported_alpha_vegetation/updates/04_source_diagnostics_guidance"


def replace_addon_with_base(project: Path) -> None:
    """Replace only a disposable prepared project's addon with the pinned base."""
    target = (project / "addons/go_flora").resolve()
    work_root = (ROOT / ".scratch/qa013").resolve()
    if not target.is_relative_to(work_root):
        raise ValueError("Baseline replacement must stay inside .scratch/qa013")
    names = subprocess.check_output(
        ["git", "ls-tree", "-r", "--name-only", BASE, "--", "addons/go_flora"], cwd=ROOT, text=True
    ).splitlines()
    shutil.rmtree(target)
    for name in names:
        path = project / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(subprocess.check_output(["git", "show", f"{BASE}:{name}"], cwd=ROOT))


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--label", default="dev")
    args = parser.parse_args()
    output = UPDATE / "evidence/runs" / args.label
    if output.exists():
        raise ValueError("Evidence is immutable; choose a new label")
    output.mkdir(parents=True, exist_ok=True)
    work = ROOT / ".scratch/qa013" / (args.label + "-" + str(time.time_ns()))
    profile = ROOT / ".scratch/qa013-profiles" / work.name
    rows = []

    def case(project: Path, name: str, flags: list[str], marker: str) -> bool:
        row = run_case(args.godot, project, output, name, flags, marker, profile_path=profile / name)
        rows.append(row)
        return row["status"] == "PASS"

    candidate = prepare(work / "candidate")
    baseline = prepare(work / "baseline")
    replace_addon_with_base(baseline)
    case(candidate, "candidate_version", ["--headless", "--version"], "4.7.2.stable.official.ed1daf0bf")
    candidate_imported = case(candidate, "candidate_import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED")
    baseline_imported = case(baseline, "baseline_import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED")
    if candidate_imported and baseline_imported:
        case(baseline, "resolver_parity_baseline", ["--headless", "--script", "tests/test_issue13_resolver_parity.gd"], "PASS ISSUE13_RESOLVER_PARITY")
        case(candidate, "resolver_parity_candidate", ["--headless", "--script", "tests/test_issue13_resolver_parity.gd"], "PASS ISSUE13_RESOLVER_PARITY")
        base_rows = read_json(baseline / ".scratch/issue13_resolver_parity.json")
        candidate_rows = read_json(candidate / ".scratch/issue13_resolver_parity.json")
        identical = base_rows == candidate_rows
        rows.append(dict(case="resolver_legacy_contract_parity", status="PASS" if identical else "FAIL", base=BASE,
                         compared_fields=["status", "revision", "parts", "scene", "capabilities"],
                         detail="pinned baseline == candidate" if identical else {"baseline": base_rows, "candidate": candidate_rows}))
    if candidate_imported:
        case(candidate, "diagnostic_contract", ["--headless", "--script", "tests/test_issue13_diagnostics.gd"], "PASS ISSUE13_DIAGNOSTICS_COMPLETE")
        for name, script, marker in [
            ("stage01_core", "test_stage01.gd", "PASS scene_saved_for_fresh_process"),
            ("stage01_reopen", "test_stage01_reopen.gd", "PASS fresh_process_scene_reopen"),
            ("stage02_core", "test_stage02.gd", "PASS STAGE02_COMPLETE"),
            ("stage02_reopen", "test_stage02_reopen.gd", "PASS STAGE02_REOPEN"),
            ("stage021_core", "test_stage021.gd", "PASS STAGE021_COMPLETE"),
            ("stage021_reopen", "test_stage021_reopen.gd", "PASS STAGE021_REOPEN"),
            ("stage023_core", "test_stage023.gd", "PASS STAGE023_CORE_COMPLETE"),
            ("stage023_catalog", "test_stage023_catalog.gd", "PASS STAGE023_CATALOG_COMPLETE"),
        ]:
            case(candidate, name, ["--headless", "--script", "tests/" + script], marker)
    if candidate_imported:
        editor = prepare(work / "editor-diagnostics")
        config = editor / "project.godot"
        config.write_text(config.read_text(encoding="utf-8").replace(
            'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg")',
            'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg", "res://tests/editor_diagnostics_harness/plugin.cfg")'), encoding="utf-8")
        if case(editor, "editor_diagnostics_import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED"):
            case(editor, "editor_diagnostics", ["--headless", "--editor", "demo.tscn"], "PASS ISSUE13_EDITOR_COMPLETE")
        modal = prepare(work / "editor-modal")
        config = modal / "project.godot"
        config.write_text(config.read_text(encoding="utf-8").replace(
            'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg")',
            'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg", "res://tests/editor_modal_harness/plugin.cfg")'), encoding="utf-8")
        if case(modal, "editor_modal_import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED"):
            case(modal, "editor_modal", ["--headless", "--editor", "demo.tscn"], "PASS STAGE022_EDITOR_COMPLETE")
            case(modal, "editor_modal_reopen", ["--headless", "--script", "tests/test_stage022_reopen.gd"], "PASS STAGE022_REOPEN")
    for name in ["issue13_diagnostics_results.json", "issue13_resolver_parity.json"]:
        source = candidate / ".scratch" / name
        if source.exists():
            shutil.copyfile(source, output / name)
    editor_result = work / "editor-diagnostics/.scratch/issue13_editor_results.json"
    if editor_result.exists():
        shutil.copyfile(editor_result, output / editor_result.name)
    summary = dict(
        issue=13,
        base=BASE,
        engine_sha256=hashlib.sha256(args.godot.read_bytes()).hexdigest(),
        probes=rows,
        INTERACTIVE_GUI_QA="NOT_RUN",
        scope="isolated headless and native Editor API; no TEST_FLORA access",
    )
    (output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print("RESULT", output.relative_to(ROOT))
    return int(any(row["status"] == "FAIL" for row in rows))


if __name__ == "__main__":
    raise SystemExit(main())
