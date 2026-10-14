import argparse
import json
import os
import subprocess
import textwrap
import uuid
from pathlib import Path

parser = argparse.ArgumentParser(description="Exercise the actual CI Bash whitespace gate on committed Git fixtures")
parser.add_argument("--bash", default="bash")
args = parser.parse_args()
root = Path(__file__).resolve().parents[3]
fixture = root / ".scratch" / ("whitespace-fixture-" + uuid.uuid4().hex)
fixture.mkdir(parents=True)
workflow = (root / ".github/workflows/foundation.yml").read_text(encoding="utf-8")
marker = "        run: |\n"
assert workflow.count(marker) == 1
gate = textwrap.dedent(workflow.split(marker)[1])
bash = args.bash
records = []

def git(*args):
    return subprocess.run(["git", *args], cwd=fixture, check=True, capture_output=True, text=True).stdout.strip()

def commit(message):
    git("add", "sample.txt")
    git("-c", "user.name=Whitespace probe", "-c", "user.email=probe@example.invalid", "commit", "-m", message)

def test_gate(label, base_sha, expected):
    probe_environment = os.environ.copy()
    probe_environment["PR_BASE_SHA"] = base_sha
    result = subprocess.run([str(bash), "--noprofile", "--norc", "-c", gate], cwd=fixture,
                            env=probe_environment, capture_output=True, text=True)
    assert result.returncode == expected, (label, result.returncode, result.stdout, result.stderr)
    records.append(dict(case=label, status="PASS", expected_exit=expected, observed_exit=result.returncode,
                        output=result.stdout + result.stderr))

git("init", "-b", "main")
(fixture / "sample.txt").write_text("clean base\n", encoding="utf-8")
commit("clean base")
base = git("rev-parse", "HEAD")
git("update-ref", "refs/remotes/origin/main", base)
git("switch", "-c", "probe")
(fixture / "sample.txt").write_text("committed trailing space \n", encoding="utf-8")
commit("committed whitespace regression")
assert git("status", "--porcelain") == ""
old = subprocess.run(["git", "diff", "--check"], cwd=fixture, capture_output=True)
assert old.returncode == 0
records.append(dict(case="old gate misses committed whitespace in clean working tree", observed_exit=0, status="PASS"))
test_gate("PR base catches committed whitespace", base, 2)
test_gate("push origin/main fallback catches committed whitespace", "", 2)
(fixture / "sample.txt").write_text("clean changed content\n", encoding="utf-8")
commit("fix whitespace")
assert git("status", "--porcelain") == ""
test_gate("PR base accepts clean committed diff", base, 0)
test_gate("push origin/main fallback accepts clean committed diff", "", 0)
output = root / "stages/00_source_audit/evidence/.scratch/whitespace_regression.json"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps({"workflow": ".github/workflows/foundation.yml", "executed_bash": gate,
                              "cases": records, "scope": "static Git gate regression; no Godot runtime test"}, indent=2), encoding="utf-8")
print("PASS workflow's actual Bash gate: committed whitespace rejected; clean diff accepted for PR and push")
