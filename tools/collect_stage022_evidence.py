"""Promote only Stage 02.2 evidence; retain failed probes and exact log bytes."""
import hashlib
import json
import shutil

from run_stage022_tests import UPDATE

EVIDENCE = UPDATE / "evidence"


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")


def main():
    index = []
    for summary in sorted((EVIDENCE / ".scratch").glob("*/summary.json")):
        source = summary.parent
        target = EVIDENCE / "runs" / source.name
        data = json.loads(summary.read_text(encoding="utf-8"))
        write(target / "summary.json", data)
        probes = data if isinstance(data, list) else data["probes"]
        failed = any(row["status"] == "FAIL" for row in probes)
        for log in source.glob("*.log"):
            raw = log.read_bytes()
            value = raw.decode("utf-8")
            write(target / (log.stem + ".raw.json"), dict(encoding="utf-8", sha256=hashlib.sha256(raw).hexdigest(), content=value))
            readable = "\n".join(line.rstrip() for line in value.splitlines()).rstrip() + "\n"
            (target / log.name).write_text(readable, encoding="utf-8", newline="\n")
        for path in source.glob("*/.scratch/*results.json"):
            write(target / (path.parents[1].name + "_" + path.name), json.loads(path.read_text(encoding="utf-8")))
        for path in source.glob("*.json"):
            if path.name != "summary.json":
                write(target / path.name, json.loads(path.read_text(encoding="utf-8")))
        if not failed:
            for path in source.glob("editor_modal_harness/.scratch/*.png"):
                shutil.copyfile(path, target / path.name)
        index.append(dict(run=source.name, status="FAIL" if failed else "PASS", summary=(target / "summary.json").relative_to(UPDATE).as_posix(),
                          legacy_reproduction=next((p.get("reproduction_probe") for p in probes if "reproduction_probe" in p), None)))
    write(EVIDENCE / "run_index.json", dict(runs=index, OWNER_REPORTED_GUI_FAIL="0.2.1-dev PNG Quick Load, Issue #8", INTERACTIVE_GUI_QA="NOT_RUN"))
    print("PASS promoted", len(index), "runs; legacy and intermediate FAIL retained, raw content/SHA preserved")


if __name__ == "__main__":
    main()
