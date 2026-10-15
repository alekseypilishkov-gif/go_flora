"""Copy small delivery evidence from Issue #9 scratch; never copy projects/caches."""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UPDATE = ROOT / "stages/02_imported_alpha_vegetation/updates/03_erase_palette_remove"


def collect(source, target):
    target.mkdir(parents=True, exist_ok=True)
    for file in source.iterdir():
        if file.is_file() and file.suffix in {".log", ".json", ".sha256"}:
            destination = target / file.name
            if destination.exists() and destination.read_bytes() != file.read_bytes():
                raw = destination.with_suffix(".raw.json")
                if file.suffix == ".log" and raw.exists() and json.loads(raw.read_text(encoding="utf-8"))["raw_output"] == file.read_text(encoding="utf-8"):
                    continue
                raise ValueError("Preserve existing evidence: " + str(destination))
            shutil.copyfile(file, destination)


def main():
    collect(UPDATE / "evidence/.scratch/package-delivery", UPDATE / "evidence/package")
    collect(UPDATE / "evidence/.scratch/alpha-gpu-final", UPDATE / "evidence/gpu")
    package = json.loads((UPDATE / "evidence/package/summary.json").read_text(encoding="utf-8"))
    manifest = package["manifest"]
    destination = UPDATE / "evidence/package/manifest.json"
    if not destination.exists():
        destination.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    capture = ROOT / ".scratch/qa023/final04/editor/editor_erase_palette_harness/.scratch"
    images = UPDATE / "evidence/viewport"
    images.mkdir(parents=True, exist_ok=True)
    for file in capture.glob("palette_*.png"):
        shutil.copyfile(file, images / file.name)
    # These are source-review conclusions, intentionally separate from runtime.
    review = UPDATE / "evidence/review.json"
    if not review.exists():
        review.write_text(json.dumps(dict(
            reviewer="Astra", scope="read-only source audit, independent runtime NOT_RUN",
            status="PASS", remaining_confirmed_P1_P2=0,
            corrected=["release endpoint coverage", "incremental preview slots", "input only enqueues", "long sparse empty sweeps"],
            limitation="512 operations/4ms is per query slice, not a whole-frame deadline; final delta/apply/rebuild synchronous",
            owner_clarification="Owner explicitly approved strengthening exactly two duplicate-ID scenarios; unchanged failed run retained",
            INTERACTIVE_GUI_QA="NOT_RUN"), indent=2) + "\n", encoding="utf-8")
    # Keep exact Output inside JSON; readable logs normalize trailing whitespace
    # for the repository whitespace gate. Never alter older stage evidence.
    for file in (UPDATE / "evidence").rglob("*.log"):
        if ".scratch" in file.parts:
            continue
        original = file.read_text(encoding="utf-8")
        raw = file.with_suffix(".raw.json")
        if not raw.exists():
            raw.write_text(json.dumps(dict(raw_output=original, readable_log="trailing whitespace normalized"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        normalized = "\n".join(line.rstrip() for line in original.splitlines()).rstrip()
        file.write_text(normalized + "\n" if normalized else "", encoding="utf-8", newline="\n")
    print("PASS copied package, GPU, viewport and source-review evidence without projects/dependencies")


if __name__ == "__main__":
    main()
