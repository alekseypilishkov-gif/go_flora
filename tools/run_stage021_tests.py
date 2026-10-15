"""Stage 02.1 isolated runs; historical stage evidence is never overwritten."""
import argparse
import hashlib
import json
import time
from pathlib import Path

from run_stage02_tests import ROOT, prepare, run_case

UPDATE = ROOT / "stages/02_imported_alpha_vegetation/updates/01_palette_dock_ux"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True, type=Path)
    parser.add_argument("--phase", choices=["baseline", "final", "ux"], default="ux")
    parser.add_argument("--editor-capture", action="store_true", help="Actual GPU editor API run and captures; not mouse GUI QA")
    args = parser.parse_args()
    output = UPDATE / "evidence/.scratch" / (args.phase + "-" + str(time.time_ns()))
    project = prepare(output / "project")
    rows = [run_case(args.godot, project, output, "version", ["--headless", "--version"], "4.7.2.stable.official.ed1daf0bf"),
            run_case(args.godot, project, output, "import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED")]
    scripts = [("stage01_core", "test_stage01.gd", "PASS scene_saved_for_fresh_process"),
               ("stage01_reopen", "test_stage01_reopen.gd", "PASS fresh_process_scene_reopen"),
               ("stage02_core", "test_stage02.gd", "PASS STAGE02_COMPLETE"),
               ("stage02_reopen", "test_stage02_reopen.gd", "PASS STAGE02_REOPEN")]
    if args.phase == "ux":
        scripts = [("ux_core", "test_stage021.gd", "PASS STAGE021_COMPLETE"),
                   ("ux_reopen", "test_stage021_reopen.gd", "PASS STAGE021_REOPEN")]
    for name, script, marker in scripts:
        rows.append(run_case(args.godot, project, output, name, ["--headless", "--script", "tests/" + script], marker))
    harnesses = ["editor_ux_harness"] if args.phase == "ux" else ["editor_harness", "editor_stage02_harness"]
    for harness in harnesses:
        editor = prepare(output / harness)
        config = editor / "project.godot"
        config.write_text(config.read_text(encoding="utf-8").replace(
            'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg")',
            f'enabled=PackedStringArray("res://addons/go_flora/plugin.cfg", "res://tests/{harness}/plugin.cfg")'), encoding="utf-8")
        if args.editor_capture:
            with config.open("a", encoding="utf-8") as stream:
                stream.write("\n[go_flora_qa]\ncapture=true\n")
        rows.append(run_case(args.godot, editor, output, harness + "_import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED"))
        marker = {"editor_harness": "PASS EDITOR_API reenable_one_plugin_no_parse_errors_data_rendered", "editor_stage02_harness": "PASS STAGE02_EDITOR_COMPLETE", "editor_ux_harness": "PASS STAGE021_EDITOR_COMPLETE"}[harness]
        flags = ["--headless"] if not args.editor_capture else ["--rendering-method", "gl_compatibility", "--position", "-10000,-10000", "--resolution", "1500x1000"]
        rows.append(run_case(args.godot, editor, output, harness, [*flags, "--editor", "demo.tscn"], marker))
    result = dict(phase=args.phase, engine_sha256=hashlib.sha256(args.godot.read_bytes()).hexdigest(), probes=rows, INTERACTIVE_GUI_QA="NOT_RUN")
    (output / "summary.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    pointer = output.parent / (args.phase + ("_gpu_editor" if args.editor_capture else "") + "_latest.json")
    prior = json.loads(pointer.read_text(encoding="utf-8"))["path"] if pointer.exists() else ""
    if not prior or int(output.name.rsplit("-", 1)[-1]) > int(Path(prior).name.rsplit("-", 1)[-1]):
        pointer.write_text(json.dumps(dict(path=output.relative_to(ROOT).as_posix())), encoding="utf-8")
    print("RESULT", output.relative_to(ROOT), flush=True)
    return int(any(r["status"] == "FAIL" for r in rows))


if __name__ == "__main__":
    raise SystemExit(main())
