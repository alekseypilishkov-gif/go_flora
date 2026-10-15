"""Build a reproducible local addon ZIP, without publishing a release."""
import argparse
import hashlib
import json
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--output", type=Path, default=ROOT / "stages/01_painter_mvp/.scratch/packages")
args = parser.parse_args()
output = args.output.resolve()
if not output.is_relative_to(ROOT) or ".scratch" not in output.parts:
    raise SystemExit("Local ZIP outputs must stay in an ignored workspace .scratch directory")
source = ROOT / "addons/go_flora"
files = sorted(path for path in source.rglob("*") if path.is_file()
               and (path.name == "LICENSE" or path.suffix in {".gd", ".uid", ".cfg", ".md"}))
hashes = {path.relative_to(ROOT).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest() for path in files}
source_digest = hashlib.sha256(json.dumps(hashes, sort_keys=True).encode()).hexdigest()
version = next(line.split("=", 1)[1].strip('"') for line in (source / "plugin.cfg").read_text(encoding="utf-8").splitlines() if line.startswith("version="))
output.mkdir(parents=True, exist_ok=True)
archive = output / f"GO_FLORA_stage01_{version}_{source_digest[:8]}.zip"
with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as package:
    for path in files:
        entry = zipfile.ZipInfo(path.relative_to(ROOT).as_posix(), date_time=(1980, 1, 1, 0, 0, 0))
        entry.external_attr = 0o100644 << 16
        entry.compress_type = zipfile.ZIP_DEFLATED
        package.writestr(entry, path.read_bytes(), compresslevel=9)
with zipfile.ZipFile(archive) as package:
    assert package.testzip() is None
    assert set(package.namelist()) == set(hashes)
    assert all(hashlib.sha256(package.read(name)).hexdigest() == digest for name, digest in hashes.items())
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
archive.with_suffix(".sha256").write_text(f"{digest}  {archive.name}\n", encoding="utf-8")
commit = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True, check=True).stdout.strip()
manifest = {"scope": "Local addon package, not a published release", "version": version,
            "git_head_at_packaging": commit, "source_digest": source_digest, "sha256": digest,
            "archive": archive.name, "files": hashes, "verification": "PASS CRC and every extracted file SHA-256",
            "INTERACTIVE_GUI_QA": "NOT_RUN"}
archive.with_suffix(".json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"archive": str(archive), "sha256": digest, "files": len(files), "status": "PASS"}, indent=2))
