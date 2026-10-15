"""Static repository gate. This does not run Godot or certify runtime results."""
import ast
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = ["LICENSE", "README.md", "AGENTS.md", "CONTRIBUTING.md", "docs/PRODUCT_VISION.md",
            "docs/ARCHITECTURE_ADR_0001.md", "docs/LICENSING_DECISION.md", "docs/ROADMAP.md",
            "stages/00_source_audit/report.md", "stages/00_source_audit/competitor_matrix.md",
            "stages/00_source_audit/tree3d_source_audit.md", "stages/00_source_audit/next_stage_01_proposal.md",
            "addons/go_flora/plugin.cfg", "addons/go_flora/editor/plugin.gd", "addons/go_flora/LICENSE",
            "addons/go_flora/README.md", "stages/01_painter_mvp/report.md", "stages/01_painter_mvp/manual_qa.md",
            "stages/01_painter_mvp/demo/project.godot", "stages/01_painter_mvp/demo/demo.tscn",
            "stages/01_painter_mvp/demo/README.md", "tests/test_stage01.gd", "tests/test_stage01_reopen.gd",
            "tests/editor_harness/plugin.gd", "stages/01_painter_mvp/evidence/results.json"]
REQUIRED += ["docs/STAGE_02_SOURCE_CONTRACTS.md", "addons/go_flora/sources/source_resolver.gd",
             "addons/go_flora/data/alpha_card.gd", "stages/02_imported_alpha_vegetation/report.md",
             "stages/02_imported_alpha_vegetation/manual_qa.md", "stages/02_imported_alpha_vegetation/demo/demo.tscn",
             "stages/02_imported_alpha_vegetation/demo/fixtures/original_plant.glb",
             "stages/02_imported_alpha_vegetation/evidence/results.json", "tests/test_stage02.gd",
             "tests/editor_stage02_harness/plugin.gd", "tools/package_stage02.py", "tools/install_stage02.py"]
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
for phrase in ["READY_FOR_MANUAL_QA", "INTERACTIVE_GUI_QA: NOT_RUN", "addons/go_flora/"]:
    if phrase not in readme:
        errors.append("README missing status: " + phrase)
if (ROOT / "addons/go_flora/LICENSE").read_bytes() != (ROOT / "LICENSE").read_bytes():
    errors.append("Addon MIT notice differs from root license")
adr = (ROOT / "docs/ARCHITECTURE_ADR_0001.md").read_text(encoding="utf-8")
if "ACCEPTED" not in adr:
    errors.append("ADR 0001 missing accepted status")
evidence = json.loads((ROOT / "stages/01_painter_mvp/evidence/results.json").read_text(encoding="utf-8"))
if evidence.get("INTERACTIVE_GUI_QA") == "NOT_RUN" and "READY_FOR_MANUAL_QA" not in readme:
    errors.append("README must disclose pending manual acceptance")
print("\n".join(errors) if errors else "PASS static repository outputs, links, Python/JSON syntax and artifact isolation")
raise SystemExit(1 if errors else 0)
