"""Issue #9 quality gates with exact commands/output, separate from GUI QA."""
import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UPDATE = ROOT / "stages/02_imported_alpha_vegetation/updates/03_erase_palette_remove"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--committed", action="store_true")
    parser.add_argument("--label", required=True)
    args = parser.parse_args()
    output = UPDATE / "evidence/gates" / (args.label + ".json")
    if output.exists():
        raise ValueError("Choose a new gate label; preserve old evidence")
    commands = [["git", "diff", "--check"], ["git", "diff", "--cached", "--check"],
                [sys.executable, "tools/verify_repository.py"],
                [sys.executable, "tools/verify_stage023_delivery.py", *(["--committed"] if args.committed else [])]]
    if args.committed:
        commands += [["git", "diff", "--check", "origin/main...HEAD"],
                     ["git", "status", "--porcelain", "--untracked-files=no"]]
    rows = []
    for command in commands:
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
        clean = result.returncode == 0
        if command[:2] == ["git", "status"]:
            clean = clean and not result.stdout.strip()
        rows.append(dict(command=command, exit_code=result.returncode, status="PASS" if clean else "FAIL", stdout=result.stdout, stderr=result.stderr))
        print(rows[-1]["status"], " ".join(command[1:]))
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(dict(probes=rows, INTERACTIVE_GUI_QA="NOT_RUN"), indent=2) + "\n", encoding="utf-8")
    return int(any(row["status"] == "FAIL" for row in rows))


if __name__ == "__main__":
    raise SystemExit(main())
