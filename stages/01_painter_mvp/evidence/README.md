# Stage 01 evidence

Overall: **READY_FOR_MANUAL_QA**. **INTERACTIVE_GUI_QA: NOT_RUN**. These records describe actual Windows 11 / Godot 4.7.2 processes and checks; the native Editor harness directly calls APIs and does not perform real mouse acceptance.

| File | Meaning |
| --- | --- |
| [results.json](results.json) | Separate source/headless/editor/GUI/render/performance statuses, exact engine binary identity, source-input SHA-256 fingerprints and measured counts/timings |
| [commands.json](commands.json) | Exact commands/paths/exit codes for each final automatic process |
| [version.log](version.log), [editor_import.log](editor_import.log) | Audited runtime version; completed actual editor import/plugin initialization |
| [core.log](core.log), [core_results.json](core_results.json) | 45 assertions on deterministic data, real physics, persistence setup, render/cache settings and CPU timings |
| [fresh_reopen.log](fresh_reopen.log) | A second, fresh Godot process loads the scene saved by core tests; stable data, float tolerance 1e-5, rebuilt cache |
| [editor_api.log](editor_api.log), [editor_api_results.json](editor_api_results.json) | 17 actual headless native Editor API checks: Paint/Erase/Single history, two scenes, cancellation API and plugin lifecycle |
| [editor_gui_startup.log](editor_gui_startup.log) | Actual visible Windows editor startup, OpenGL/GPU and addon enabled; proves startup only |
| [hardware.json](hardware.json) | Read-only Windows hardware capture for the CPU benchmark |
| [whitespace_regression.json](whitespace_regression.json) | Unchanged Stage 00 probe executes the current CI Bash gate against committed dirty/clean Git fixtures; both PR and push cases pass |
| [ci_summary.json](ci_summary.json) | Successful GitHub Actions job/step metadata, implementation commit, artifact digest and excerpts from actual headless Linux logs |
| [development_failures.md](development_failures.md) | Observed development/environment failures and how they were resolved or left NOT_RUN |

No screenshots/video were captured. The owner's [manual script](../manual_qa.md) contains the unexecuted real interaction checks. Generated scenes, profiles, binaries and full Godot caches are ignored under `.scratch/` / `.godot/`. Historical Stage 00 evidence is unchanged.

Committed text logs remove ANSI color sequences and trim line-ending whitespace for review/CI hygiene. Original subprocess output remains under ignored `.scratch/runs/`. No statuses, assertions or measurements were changed.

## Reproduce

From repository root, with an existing Godot 4.7.2 executable:

```text
python tools/prepare_stage01.py
python tools/run_stage01_tests.py --godot <path-to-Godot-4.7.2-executable>
python tools/verify_repository.py
python stages/00_source_audit/evidence/whitespace_probe.py
git diff --check
git diff --cached --check
git diff --check origin/main...HEAD
```

On this Windows host Bash is not on PATH. The executed regression command was `python stages/00_source_audit/evidence/whitespace_probe.py --bash "C:/Program Files/Git/bin/bash.exe"`, with authorized escalation because the sandbox denies MSYS named objects. On CI, Bash is available directly. Previous committed Stage 00 evidence remains untouched; this stage retains a copy of the new fixture results.

The runner uses ignored **test_project** and **editor_project** copies, keeping automatic writes away from the owner's interactive demo. It runs version → completed editor import → core → fresh-process reopen → headless native Editor harness. A nonzero exit, Godot error, failed assertion, missing completion marker or wrong engine identity fails the run. Logs/results appear under `evidence/.scratch/`; committed files above are a snapshot of the final Windows run, not silently refreshed history.

GitHub Actions runs the repository's static gate and the same automated Godot suite in an Ubuntu job with the official 4.7.2 Linux artifact, pinned SHA-256 `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`. Workflow artifacts preserve their own logs. Linux headless CI is additional automation evidence; it is not Linux GUI/export support or owner acceptance. Upstream identity: [4.7.2-stable release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable).

Verified implementation commit `b4a3381fe5cf5daef0fd5001ddb7571370db3e22`: [static job](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/38562618639) PASS and [Godot automatic job](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/38562618673) PASS. Full CI evidence: [artifact](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/38562618673/artifacts/11893506724). [PR #4](https://github.com/alekseypilishkov-gif/go_flora/pull/4) remains open for owner acceptance.
