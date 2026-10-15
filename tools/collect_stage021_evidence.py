"""Promote Stage 02.1 isolated evidence, including failed attempts, never older stages."""
import hashlib
import json
import shutil
from pathlib import Path

from run_stage021_tests import ROOT, UPDATE

EVIDENCE = UPDATE / "evidence"


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")


def main():
    runs = []
    for summary in sorted((EVIDENCE / ".scratch").glob("*/summary.json")):
        source = summary.parent
        target = EVIDENCE / "runs" / source.name
        target.mkdir(parents=True, exist_ok=True)
        data = json.loads(summary.read_text(encoding="utf-8"))
        write(target / "summary.json", data)
        for log in sorted(source.glob("*.log")):
            raw = log.read_bytes()
            value = raw.decode("utf-8")
            write(target / (log.stem + ".raw.json"), dict(encoding="utf-8", sha256=hashlib.sha256(raw).hexdigest(), content=value))
            readable = "\n".join(line.rstrip() for line in value.splitlines()).rstrip() + "\n"
            (target / log.name).write_text(readable, encoding="utf-8", newline="\n")
        for name in ["gl_compatibility", "mobile", "forward_plus"]:
            path = source / (name + ".json")
            if path.exists():
                write(target / path.name, json.loads(path.read_text(encoding="utf-8")))
        for path in source.glob("*/.scratch/*results.json"):
            write(target / (path.parents[1].name + "_" + path.name), json.loads(path.read_text(encoding="utf-8")))
        for image in source.glob("editor_ux_harness/.scratch/named_*.png"):
            shutil.copyfile(image, target / image.name)
        probes = data if isinstance(data, list) else data["probes"]
        runs.append(dict(run=source.name, status="FAIL" if any(p["status"] == "FAIL" for p in probes) else "PASS", summary=(target / "summary.json").relative_to(UPDATE).as_posix()))
    write(EVIDENCE / "run_index.json", dict(runs=runs, INTERACTIVE_GUI_QA="NOT_RUN", READY_FOR_MANUAL_QA=True))
    print("PASS promoted", len(runs), "isolated runs with exact logs/SHA; failed attempts retained")


if __name__ == "__main__":
    main()
