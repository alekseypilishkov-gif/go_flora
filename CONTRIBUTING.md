# Contributing

Follow the currently authorized stage issue. Do not start a later stage without owner authorization. Use relative repository paths in scripts and documentation commands; never touch the separate Blender GAME_FLORA project.

1. Read the current issue and stage report.
2. Create the issue's named feature branch from updated `main`; Stage 01 uses `codex/stage-01-painter-mvp`.
3. Preserve previous stage results. Put current reports/demos/evidence in its stage directory, addon code in `addons/go_flora/`, tests in `tests/`, and shared decisions in `docs/`. Keep downloads and generated outputs in ignored `.scratch/` directories.
4. Record PASS, FAIL, and NOT_RUN separately. Source inspection is not runtime validation.
5. Check `git diff --check` for working changes and `git diff --cached --check` before committing; then run `git diff --check origin/main...HEAD` against the PR base with sufficient history. Run `python tools/verify_repository.py` and applicable stage tests. For Stage 01, prepare the demo, then run `python tools/run_stage01_tests.py --godot <Godot-4.7.2-executable>`. Commit only small, reviewable source and evidence. Headless Editor API tests do not substitute for the [real manual QA](stages/01_painter_mvp/manual_qa.md).
6. Submit a scoped PR with evidence, limitations, and owner decisions. Do not auto-merge or publish a release.

Original GO_FLORA code and documentation use the owner-approved [MIT license](LICENSE). Third-party code/assets retain their own terms: follow the [licensing inventory](docs/LICENSING_DECISION.md), link upstream sources and preserve notices if authorized derivative code is later introduced. Do not copy unverified demo assets or competitor implementation.
