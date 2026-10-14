"""Read-only ZIP provenance comparison; never extracts or redistributes assets."""
import argparse
import hashlib
import json
import zipfile
from pathlib import Path


def digest(data):
    return hashlib.sha256(data).hexdigest()


def audit(path):
    entries = {}
    descriptors = {}
    with zipfile.ZipFile(path) as archive:
        for name in sorted(archive.namelist()):
            if name.endswith("/"):
                continue
            data = archive.read(name)
            offset = name.replace("\\", "/").find("Tree3D/")
            if offset >= 0:
                key = name.replace("\\", "/")[offset:]
                entries[key] = digest(data)
            if name.endswith(".gdextension"):
                descriptors[name] = data.decode("utf-8-sig")
        source_files = [n for n in archive.namelist() if n.endswith((".cpp", ".h"))]
    return dict(archive_name=path.name, sha256=digest(path.read_bytes()), addon_entries=entries,
                descriptors=descriptors, cpp_source_files=source_files)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("local", type=Path)
    parser.add_argument("upstream", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    local, upstream = audit(args.local), audit(args.upstream)
    a, b = local["addon_entries"], upstream["addon_entries"]
    shared = sorted(a.keys() & b.keys())
    result = dict(local=local, upstream=upstream, comparison={
        "shared_entries": len(shared), "identical_entries": [key for key in shared if a[key] == b[key]],
        "different_entries": [key for key in shared if a[key] != b[key]],
        "local_only": sorted(a.keys() - b.keys()), "upstream_only": sorted(b.keys() - a.keys()),
        "source_binary_build_identity": "UNVERIFIED: payload equality does not prove build provenance"})
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result["comparison"], indent=2))


if __name__ == "__main__":
    main()
