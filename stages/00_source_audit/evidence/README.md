# Evidence and reproduction

All committed probes are original, disposable Stage 00 scripts. They are not the GO_FLORA plugin. Inputs/outputs, Godot profiles, imported upstream addons, resource saves and binaries stay in ignored `.scratch/`. Small logs and self-generated screenshots are retained here. Committed logs use normalized line endings; one trailing space in the initial editor error was removed for the whitespace gate, with its error text preserved.

`environment.json` records tool discovery/version commands and original executable SHA-256. `source_refs.json` records source pins. `tree3d_source_checksums.json` hashes the fetched UTF-8 source contents (with their fetched line endings) and records upstream Git blob IDs. `archive_comparison.json` stores ZIP/addon per-file digests, not file contents. `logs/` records the final command results; `logs/sandbox-attempt/` retains initial failures caused by denied Godot profile writes.

## Reproduce probes from the repository root

Use a local Python and detected Godot executable; paths below are examples relative to the repo, not a requirement to use the audit workstation's absolute paths. On Windows, run a copy of the existing engine with `_sc_` marker to isolate editor data. The runner also redirects child-process APPDATA/LOCALAPPDATA into stage `.scratch/profile`; it does not change system environment variables.

```powershell
New-Item -ItemType Directory -Force -Path .scratch/godot-portable
Copy-Item -LiteralPath <existing-Godot-executable> -Destination .scratch/godot-portable/godot.exe
New-Item -ItemType File -Path .scratch/godot-portable/_sc_
python stages/00_source_audit/evidence/audit_environment.py --godot .scratch/godot-portable/godot.exe --output .scratch/environment-rerun.json
python stages/00_source_audit/evidence/run_probes.py --godot .scratch/godot-portable/godot.exe
# After downloading and verifying the official v1.1.0 addon ZIP digest:
python stages/00_source_audit/evidence/run_probes.py --godot .scratch/godot-portable/godot.exe --tree3d-archive .scratch/Tree3D-upstream-v1.1.0.zip
python stages/00_source_audit/evidence/run_probes.py --godot .scratch/godot-portable/godot.exe --render gl_compatibility
python stages/00_source_audit/evidence/run_probes.py --godot .scratch/godot-portable/godot.exe --render mobile
python stages/00_source_audit/evidence/run_probes.py --godot .scratch/godot-portable/godot.exe --render forward_plus
python stages/00_source_audit/evidence/audit_archives.py <local-archive> .scratch/Tree3D-upstream-v1.1.0.zip --output .scratch/archive-rerun.json
python tools/verify_repository.py
git diff --check
git diff --cached --check
git diff --check origin/main...HEAD
```

The run summary JSON under stage `.scratch/runs/` includes the exact child command and exit code. The alpha GPU commands open short-lived renderer windows and write viewport PNGs. They do not use headless dummy rendering for pixel checks. The Compatibility alpha-hash probe currently returns FAIL and exit 1; retain it as evidence, do not relabel it PASS. Resource-only headless alpha checks explicitly print render NOT_RUN. Review [results.json](results.json) for per-case distinctions; command PASS can coexist with explicit NOT_RUN subchecks.

## Licensing follow-up static checks

The corrected Actions workflow checks out the actual PR head with full history and compares its committed diff with the event's PR base SHA; push runs compare with `origin/main`. A clean working-tree check alone does not inspect committed changes. [licensing_followup_whitespace.json](licensing_followup_whitespace.json) records a regression probe of the actual Bash block extracted from the workflow: an intentionally bad committed file in a clean fixture is rejected (exit 2) for both PR-base and push-fallback paths; corrected committed content passes (exit 0).

Reproduce with `python stages/00_source_audit/evidence/whitespace_probe.py --bash <bash-executable>` from any working directory, using Git Bash on Windows or `bash` on Linux. It creates original temporary Git fixtures under ignored repository `.scratch/` and writes results under stage `.scratch/`; it does not modify project branches. These are static Git checks, not Godot runtime tests. The initial Windows sandbox launcher failed to create an MSYS named object; the authorized rerun passed.

## Manual viewport gate — NOT_RUN

Open the probe project in Godot 4.7.2. In an otherwise empty scene add a MeshInstance3D PlaneMesh, generate a StaticBody trimesh collision and enable the Stage 00 input probe. Temporarily add a print of `not last_hit.is_empty()` immediately after the ray query in the isolated callback. Left-click the plane in the 3D editor, then click empty space and confirm false; navigate with editor controls. Save the fixture scene only in `.scratch/`. This checks actual editor event routing, which the automated direct callback invocation does not prove. No production painting is present.

Other NOT_RUN checks: Tree3D source build, exported release binary, visual wind/material/collision and lifecycle stress; Linux/macOS/Web/mobile device execution; set-distance propagation as a complete system. Mobile renderer was tested on desktop Vulkan, not an Android/iOS device. See [native build reproduction](../tree3d_source_audit.md).
