"""Actual GPU pixel probes, separate from headless/editor/owner GUI evidence."""
import argparse
import hashlib
import json
from pathlib import Path

from run_stage02_tests import ROOT, STAGE, prepare, run_case

parser = argparse.ArgumentParser()
parser.add_argument("--godot", required=True, type=Path)
parser.add_argument("--output", type=Path, default=STAGE / "evidence/.scratch/gpu")
args = parser.parse_args()
output = args.output.resolve()
if not output.is_relative_to(ROOT) or ".scratch" not in output.parts:
    raise SystemExit("GPU outputs must stay in a workspace .scratch directory")
project = prepare(output / "project")
# Vulkan shader-cache keys add long subpaths; keep the isolated Windows profile
# short enough for engine/driver file APIs, independently of the evidence path.
profile = ROOT / ".scratch/gpu-profiles" / hashlib.sha256(str(output).encode()).hexdigest()[:12]


def case(name, flags, marker):
    return run_case(args.godot, project, output, name, flags, marker, profile_path=profile)


rows = [case("import", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED")]
# Pin fixture imports to mipmaps; no global/project rendering settings are changed.
for texture in (project / "fixtures").glob("pixel_atlas.*.import"):
    texture.write_text(texture.read_text(encoding="utf-8").replace("mipmaps/generate=false", "mipmaps/generate=true"), encoding="utf-8")
rows.append(case("mipmap_reimport", ["--headless", "--editor", "--import"], "GO_FLORA_PLUGIN_ENABLED"))
for renderer in ["gl_compatibility", "mobile", "forward_plus"]:
    rows.append(case(renderer,
                         ["--rendering-method", renderer, "--position", "-10000,-10000", "--resolution", "64x64", "--script", "tests/test_stage02_gpu.gd"], "PASS GPU_COMPLETE"))
    data = project / ".scratch/gpu/results.json"
    if data.exists():
        (output / (renderer + ".json")).write_bytes(data.read_bytes())
(output / "summary.json").write_text(json.dumps(rows, indent=2) + "\n", encoding="utf-8")
raise SystemExit(int(any(r["status"] == "FAIL" for r in rows)))
