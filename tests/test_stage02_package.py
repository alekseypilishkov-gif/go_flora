"""Plugin ZIP integrity, repeated update preservation and disposable native smoke."""
import argparse
import hashlib
import json
import shutil
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from install_stage02 import install
from package_stage02 import build
from run_stage02_tests import ROOT, STAGE, run_case


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True, type=Path)
    args = parser.parse_args()
    output = STAGE / "evidence/.scratch/package"
    output.mkdir(parents=True, exist_ok=True)
    archive, manifest = build(STAGE / ".scratch/packages")
    second, other = build(STAGE / ".scratch/packages/repeat")
    assert archive.read_bytes() == second.read_bytes(), "ZIP is not byte-reproducible"
    print("PASS plugin-only reproducible ZIP CRC/SHA", flush=True)
    project = output / "project"
    project.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(STAGE / "demo/project.godot", project / "project.godot")
    shutil.copyfile(STAGE / "demo/demo.tscn", project / "demo.tscn")
    shutil.copyfile(STAGE / "demo/runtime_camera.gd", project / "runtime_camera.gd")
    shutil.copytree(STAGE / "demo/fixtures", project / "fixtures", dirs_exist_ok=True)
    shutil.copyfile(STAGE / "demo/fixtures/stage01_saved.tscn", project / "existing_stage01.tscn")
    layout = project / ".godot/editor/editor_layout.cfg"
    layout.parent.mkdir(parents=True, exist_ok=True)
    layout.write_text("; owner layout preservation sentinel\n", encoding="utf-8")
    preserved = {str(p.relative_to(project)): digest(p) for p in [project / "project.godot", project / "demo.tscn", project / "existing_stage01.tscn", layout]}
    installations = []
    for _ in range(3):
        installations.append(install(project, archive))
        assert all(digest(project / name) == before for name, before in preserved.items()), "Installer touched scene/settings/layout"
        assert all(digest(project / name) == expected for name, expected in manifest["files"].items())
    assert Path(installations[-1]["backup"]).is_dir()
    print("PASS three installs preserve Stage 01 + Stage 02 scenes/config/layout SHA and keep backups", flush=True)
    # Refuse a matching-manifest traversal payload before any project mutation.
    malicious = output / "bad.zip"
    with zipfile.ZipFile(malicious, "w") as package:
        package.writestr("addons/go_flora/../../evil.gd", b"bad")
    malicious.with_suffix(".json").write_text(json.dumps(dict(sha256=digest(malicious), files={"addons/go_flora/../../evil.gd": hashlib.sha256(b"bad").hexdigest()})), encoding="utf-8")
    try:
        install(project, malicious)
        raise AssertionError("Traversal accepted")
    except ValueError:
        pass
    assert not (project / "evil.gd").exists()
    rows = [dict(case="reproducible_ZIP_CRC_SHA", status="PASS"), dict(case="three_installs_preserve_scene_config_layout_SHA", status="PASS", hashes=preserved),
            dict(case="ZIP_path_traversal_refused", status="PASS")]
    for name, flags, marker in [
        ("standalone_import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED"),
        ("stage02_runtime", ["--headless", "--quit-after", "15"], "Godot Engine"),
        ("stage01_runtime", ["--headless", "existing_stage01.tscn", "--quit-after", "15"], "Godot Engine")]:
        rows.append(run_case(args.godot, project, output, name, flags, marker))
    (output / "summary.json").write_text(json.dumps(dict(probes=rows, installations=installations, manifest=manifest,
                                                     owner_project_modified=False, INTERACTIVE_GUI_QA="NOT_RUN"), indent=2) + "\n", encoding="utf-8")
    raise SystemExit(int(any(r["status"] == "FAIL" for r in rows)))


if __name__ == "__main__":
    main()
