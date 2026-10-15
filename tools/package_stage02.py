"""Deterministic plugin-only ZIP. No scenes, fixtures, dependencies or release upload."""
import argparse
import hashlib
import json
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / "stages/02_imported_alpha_vegetation"


def build(output):
    output = output.resolve()
    if not output.is_relative_to(ROOT) or ".scratch" not in output.parts:
        raise ValueError("Packages must stay in a workspace .scratch directory")
    source = ROOT / "addons/go_flora"
    files = sorted(p for p in source.rglob("*") if p.is_file() and (p.name == "LICENSE" or p.suffix in {".gd", ".uid", ".cfg", ".md"}))
    hashes = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
    source_digest = hashlib.sha256(json.dumps(hashes, sort_keys=True).encode()).hexdigest()
    version = next(line.split("=", 1)[1].strip('"') for line in (source / "plugin.cfg").read_text().splitlines() if line.startswith("version="))
    output.mkdir(parents=True, exist_ok=True)
    archive = output / f"GO_FLORA_stage02_{version}_{source_digest[:8]}.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_STORED) as package:
        for path in files:
            entry = zipfile.ZipInfo(path.relative_to(ROOT).as_posix(), (1980, 1, 1, 0, 0, 0))
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            package.writestr(entry, path.read_bytes())
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None and set(package.namelist()) == set(hashes)
        assert all(hashlib.sha256(package.read(name)).hexdigest() == digest for name, digest in hashes.items())
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix(".sha256").write_text(f"{digest}  {archive.name}\n", encoding="utf-8")
    commit = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True, check=True).stdout.strip()
    manifest = dict(scope="plugin-only local update; not a release", version=version, archive=archive.name, sha256=digest,
                    source_digest=source_digest, git_head_at_packaging=commit, files=hashes,
                    format="ZIP_STORED; sorted paths; fixed timestamp/Unix permissions", verification="PASS CRC and every file SHA-256")
    archive.with_suffix(".json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return archive, manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=STAGE / ".scratch/packages")
    archive, manifest = build(parser.parse_args().output)
    print(json.dumps(dict(status="PASS", archive=str(archive), sha256=manifest["sha256"], files=len(manifest["files"])), indent=2))
