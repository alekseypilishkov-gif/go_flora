"""Static Stage 00 repository gate. This does not run Godot or certify runtime results."""
import ast
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = ["LICENSE", "README.md", "AGENTS.md", "CONTRIBUTING.md", "docs/PRODUCT_VISION.md",
            "docs/ARCHITECTURE_ADR_0001.md", "docs/LICENSING_DECISION.md", "docs/ROADMAP.md",
            "stages/00_source_audit/report.md", "stages/00_source_audit/competitor_matrix.md",
            "stages/00_source_audit/tree3d_source_audit.md", "stages/00_source_audit/next_stage_01_proposal.md"]
errors = []
for path in REQUIRED:
    if not (ROOT / path).is_file():
        errors.append("Missing required output: " + path)
result = subprocess.run(["git", "ls-files", "--cached", "--others", "--exclude-standard"],
                        cwd=ROOT, capture_output=True, text=True, check=True)
files = sorted(set(result.stdout.splitlines()))
for name in files:
    path = ROOT / name
    if not path.is_file():
        continue
    if path.stat().st_size > 512_000:
        errors.append("Oversized committed output: " + name)
    if path.suffix.lower() in {".dll", ".exe", ".so", ".dylib", ".zip", ".obj", ".o", ".res"} or ".godot" in path.parts or ".scratch" in path.parts:
        errors.append("Generated/dependency artifact: " + name)
    if path.suffix == ".py":
        ast.parse(path.read_text(encoding="utf-8"), filename=name)
    if path.suffix == ".json":
        json.loads(path.read_text(encoding="utf-8"))
    if path.suffix == ".md":
        for link in re.findall(r"\]\(([^)]+)\)", path.read_text(encoding="utf-8")):
            if "://" in link or link.startswith("#") or "<" in link:
                continue
            target = (path.parent / link.split("#", 1)[0]).resolve()
            if not target.is_relative_to(ROOT) or not target.exists():
                errors.append("Broken local link: " + name + " -> " + link)
readme = (ROOT / "README.md").read_text(encoding="utf-8")
for phrase in ["pre-development", "not yet available"]:
    if phrase not in readme:
        errors.append("README missing status: " + phrase)
print("\n".join(errors) if errors else "PASS static repository outputs, links, Python/JSON syntax and artifact isolation")
raise SystemExit(1 if errors else 0)
