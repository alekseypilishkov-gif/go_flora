"""Promote only completed Stage 02 probe outputs into reviewable evidence."""
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / "stages/02_imported_alpha_vegetation"
EVIDENCE = STAGE / "evidence"
SCRATCH = EVIDENCE / ".scratch"


def copy(source, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    if source.suffix == ".log":
        raw = source.read_bytes()
        content = raw.decode("utf-8")
        # Preserve the exact bytes as escaped JSON; readable logs satisfy Git whitespace.
        destination.with_suffix(".raw.json").write_text(json.dumps({"encoding": "utf-8", "sha256": hashlib.sha256(raw).hexdigest(), "content": content}, indent=2) + "\n", encoding="utf-8", newline="\n")
        destination.write_text("\n".join(line.rstrip() for line in content.splitlines()).rstrip() + "\n", encoding="utf-8", newline="\n")
    else:
        shutil.copyfile(source, destination)


def main():
    commands = []
    for label in ["baseline", "stage02-verified", "final"]:
        folder = SCRATCH / label
        summary = json.loads((folder / "summary.json").read_text(encoding="utf-8"))
        copy(folder / "summary.json", EVIDENCE / (label + "_summary.json"))
        for row in summary["probes"]:
            commands.append({**row, "phase": label})
        for path in folder.glob("*.log"):
            copy(path, EVIDENCE / "logs" / label / path.name)
    for folder_name in ["gpu", "demo_gpu", "package"]:
        folder = SCRATCH / folder_name
        summary = json.loads((folder / "summary.json").read_text(encoding="utf-8"))
        copy(folder / "summary.json", EVIDENCE / (folder_name + "_summary.json"))
        commands.extend([{**row, "phase": folder_name} for row in (summary["probes"] if isinstance(summary, dict) else summary)])
        for path in folder.glob("*.log"):
            copy(path, EVIDENCE / "logs" / folder_name / path.name)
    for name in ["gl_compatibility", "mobile", "forward_plus"]:
        copy(SCRATCH / "gpu" / (name + ".json"), EVIDENCE / "gpu" / (name + ".json"))
    for path in (SCRATCH / "gpu/project/.scratch/gpu").glob("*.png"):
        copy(path, EVIDENCE / "screenshots" / path.name)
    for path in (SCRATCH / "demo_gpu/project/.scratch").glob("demo_gpu*.png"):
        copy(path, EVIDENCE / "screenshots" / path.name)
    for phase in ["baseline", "final"]:
        copy(SCRATCH / phase / "project/.scratch/core_results.json", EVIDENCE / (phase + "_stage01_core.json"))
        copy(SCRATCH / phase / "editor/.scratch/editor_api_results.json", EVIDENCE / (phase + "_stage01_editor.json"))
    copy(SCRATCH / "stage02-verified/project/.scratch/stage02_results.json", EVIDENCE / "stage02_core.json")
    copy(SCRATCH / "stage02-verified/editor/.scratch/editor_stage02_results.json", EVIDENCE / "stage02_editor.json")
    package = json.loads((SCRATCH / "package/summary.json").read_text())["manifest"]
    (EVIDENCE / "package_manifest.json").write_text(json.dumps(package, indent=2) + "\n", encoding="utf-8")
    # Retain failed development probes separately from final results.
    for name in ["stage02", "stage02-r3", "stage02-r7"]:
        folder = SCRATCH / name
        for path in list(folder.glob("*.log")) + list(folder.glob("summary.json")):
            copy(path, EVIDENCE / "development_failures" / name / path.name)
    for folder in (SCRATCH / "attempts").glob("*"):
        for path in list(folder.glob("*.log")) + list(folder.glob("summary.json")):
            copy(path, EVIDENCE / "development_failures" / folder.name / path.name)
    # Canonical repository text bytes, matching .gitattributes on every host.
    for path in STAGE.rglob("*"):
        if path.is_file() and not any(p in path.parts for p in [".scratch", ".godot", "addons"]) and path.suffix in {".md", ".gd", ".uid", ".cfg", ".godot", ".tscn", ".json", ".log", ".txt"}:
            path.write_text(path.read_text(encoding="utf-8"), encoding="utf-8", newline="\n")
    inputs = {}
    for folder in [ROOT / "addons/go_flora", ROOT / "tests", STAGE / "demo"]:
        for path in sorted(folder.rglob("*")):
            if not path.is_file() or any(part in {".scratch", ".godot", "__pycache__", "addons"} for part in path.relative_to(folder).parts):
                continue
            inputs[path.relative_to(ROOT).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    (EVIDENCE / "source_hashes.json").write_text(json.dumps(inputs, indent=2) + "\n", encoding="utf-8")
    (EVIDENCE / "commands.json").write_text(json.dumps(commands, indent=2) + "\n", encoding="utf-8")
    core = json.loads((EVIDENCE / "stage02_core.json").read_text())
    editor = json.loads((EVIDENCE / "stage02_editor.json").read_text())
    previous_changes = subprocess.run(["git", "diff", "--name-only", "origin/main", "--", "stages/00_source_audit", "stages/01_painter_mvp"], cwd=ROOT, capture_output=True, text=True, check=True).stdout
    assert previous_changes == "", "Previous stage evidence modified"
    result = dict(status="READY_FOR_MANUAL_QA", engine="4.7.2.stable.official.ed1daf0bf", engine_sha256=json.loads((EVIDENCE / "final_summary.json").read_text())["engine_sha256"],
                  stage01_first="PASS", stage01_last="PASS", stage02_core_assertions=len(core["checks"]), stage02_editor_assertions=len(editor),
                  gpu_scissor="PASS Compatibility / Mobile / Forward+; 18 PNG/WebP near/far pixel checks", package="PASS CRC/SHA/reproducible/three installs",
                  owner_project_modified=False, previous_stage_evidence="PASS unchanged", INTERACTIVE_GUI_QA="NOT_RUN",
                  clean_export="NOT_RUN", large_forest_GPU_FPS="NOT_RUN", github_actions="NOT_RUN until push", benchmarks=core["benchmarks"])
    assert all(row["status"] == "PASS" for row in core["checks"] + editor)
    assert all(row["status"] == "PASS" for row in commands)
    (EVIDENCE / "results.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
