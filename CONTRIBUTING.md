# Contributing

GO_FLORA is in pre-development. Do not start a later stage without owner authorization. Use relative repository paths in scripts and documentation commands; never touch the separate Blender GAME_FLORA project.

1. Read the current issue and stage report.
2. Create a feature branch from `main`; Stage 00 uses `codex/stage-00-foundation`.
3. Keep research probes inside `stages/00_source_audit/`. Keep downloads and generated outputs in ignored `.scratch/` directories.
4. Record PASS, FAIL, and NOT_RUN separately. Source inspection is not runtime validation.
5. Check `git diff --check` for working changes and `git diff --cached --check` before committing; then run `git diff --check origin/main...HEAD` against the PR base with sufficient history. Run `python tools/verify_repository.py` and relevant documented probes. Commit only small, reviewable source and evidence.
6. Submit a scoped PR with evidence, limitations, and owner decisions. Do not auto-merge or publish a release.

Original GO_FLORA code and documentation use the owner-approved [MIT license](LICENSE). Third-party code/assets retain their own terms: follow the [licensing inventory](docs/LICENSING_DECISION.md), link upstream sources and preserve notices if authorized derivative code is later introduced. Do not copy unverified demo assets or competitor implementation.
