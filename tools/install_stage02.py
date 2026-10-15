"""Owner-invoked addon-only update, with validation and rollback backup.

Save scenes and close Godot first. This script never writes project.godot,
scene files or .godot/editor layout. Enable the addon manually on a fresh project.
"""
import argparse
import datetime
import hashlib
import json
import shutil
import zipfile
from pathlib import Path, PurePosixPath


def install(project, archive):
    project, archive = project.resolve(), archive.resolve()
    if not (project / "project.godot").is_file():
        raise ValueError("Choose an existing Godot project; save and close its editor first")
    manifest = json.loads(archive.with_suffix(".json").read_text(encoding="utf-8"))
    if hashlib.sha256(archive.read_bytes()).hexdigest() != manifest["sha256"]:
        raise ValueError("Archive SHA-256 mismatch")
    addon = project / "addons/go_flora"
    scratch = project / ".scratch/go_flora_updates"
    # Refuse link redirection and verify every final absolute target before moving.
    for target in [project / "addons", addon, project / ".scratch", scratch]:
        if target.is_symlink() or not target.resolve().is_relative_to(project):
            raise ValueError("Update target redirects outside the explicitly chosen project")
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    backup = scratch / stamp
    stage = backup / "new/go_flora"
    with zipfile.ZipFile(archive) as package:
        if package.testzip() is not None or len(package.namelist()) != len(set(package.namelist())) or set(package.namelist()) != set(manifest["files"]):
            raise ValueError("ZIP CRC/member validation failed")
        for name, digest in manifest["files"].items():
            path = PurePosixPath(name)
            if path.parts[:2] != ("addons", "go_flora") or ".." in path.parts or "\\" in name or ":" in name:
                raise ValueError("Invalid archive path")
            if path.name != "LICENSE" and path.suffix not in {".gd", ".uid", ".cfg", ".md"}:
                raise ValueError("Archive contains a non-addon payload")
            if hashlib.sha256(package.read(name)).hexdigest() != digest:
                raise ValueError("Member SHA-256 mismatch")
        for name in manifest["files"]:
            destination = stage.joinpath(*PurePosixPath(name).parts[2:])
            if not destination.resolve().is_relative_to(stage.resolve()):
                raise ValueError("Invalid staging target")
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(package.read(name))
    old = backup / "previous/go_flora"
    if not addon.resolve().is_relative_to(project) or not old.resolve().is_relative_to(scratch.resolve()):
        raise ValueError("Resolved move target outside intended directories")
    had_previous = addon.exists()
    if had_previous:
        old.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(addon), str(old))
    try:
        addon.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(stage), str(addon))
    except OSError:
        if had_previous and not addon.exists():
            shutil.move(str(old), str(addon))
        raise
    result = dict(status="PASS", version=manifest["version"], archive_sha256=manifest["sha256"],
                  backup=str(old) if had_previous else None, scenes_and_project_settings="untouched")
    (backup / "installation.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True, type=Path)
    parser.add_argument("--archive", required=True, type=Path)
    args = parser.parse_args()
    print(json.dumps(install(args.project, args.archive), indent=2))
