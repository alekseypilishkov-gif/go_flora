"""Verify package bytes against the workspace and committed addon blobs."""
import argparse
import hashlib
import json
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UPDATE = ROOT / "stages/02_imported_alpha_vegetation/updates/03_erase_palette_remove"
BASE = "f8917186ce7cdbfd1177a2a80610e500280d81d3"


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--committed", action="store_true")
    args = parser.parse_args()
    manifest = json.loads((UPDATE / "evidence/package/manifest.json").read_text(encoding="utf-8"))
    archive = UPDATE / ".scratch/packages" / manifest["archive"]
    digest = lambda data: hashlib.sha256(data).hexdigest()
    assert digest(archive.read_bytes()) == manifest["sha256"]
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None
        assert set(package.namelist()) == set(manifest["files"])
        for name, expected in manifest["files"].items():
            assert name.startswith("addons/go_flora/")
            assert digest(package.read(name)) == expected == digest((ROOT / name).read_bytes()), name
            if args.committed:
                assert digest(git("show", "HEAD:" + name)) == expected, "Committed addon differs: " + name
    protected = ["stages/00_source_audit", "stages/01_painter_mvp", "stages/02_imported_alpha_vegetation/evidence",
                 "stages/02_imported_alpha_vegetation/demo", "stages/02_imported_alpha_vegetation/updates/01_palette_dock_ux",
                 "stages/02_imported_alpha_vegetation/updates/02_resource_picker_modal_fix"]
    for directory in protected:
        assert not git("diff", "--name-only", BASE, "--", directory).strip(), "Historical evidence changed: " + directory
    result = dict(status="PASS", archive=str(archive.relative_to(ROOT)), sha256=manifest["sha256"],
                  files=len(manifest["files"]), git_head=git("rev-parse", "HEAD").decode().strip(),
                  committed_blobs="PASS" if args.committed else "NOT_RUN", historical_evidence="PASS", INTERACTIVE_GUI_QA="NOT_RUN")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
