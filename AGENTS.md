# GO_FLORA agent guardrails

- Follow only the currently authorized GitHub issue/stage. Future stages require their own owner-approved task; do not infer authorization from a roadmap or proposal.
- Use repository-relative paths in reusable commands. Do not inspect, edit, copy, or delete the separate Blender GAME_FLORA project.
- Keep reports/evidence/demos in the current `stages/<stage>/` directory, shared design documents in `docs/`, addon code in `addons/go_flora/`, and automated tests in `tests/`. Preserve previous stage evidence unchanged. Put downloaded dependencies, binaries and caches in ignored `.scratch/` only.
- Verify source/release identity using pinned revisions and checksums. Source inspection, author claims, runtime results, and unknowns must be labeled separately.
- Record each executed probe as PASS or FAIL with exact command/log; unexecuted checks are NOT_RUN. Never substitute code analysis for runtime evidence.
- Original GO_FLORA code and documentation use the owner-approved root MIT LICENSE. Preserve separate third-party conditions; no third-party assets/code redistribution without license review and owner authorization.
- Create the issue's named stage branch from current `main`; commit, push, and prepare a scoped PR toward `main`. Never force-push, rewrite history, auto-merge, or publish releases.
- Distinguish automatic/headless/editor API checks from real GUI mouse/navigation/save checks. If actual interactive acceptance cannot run, label INTERACTIVE_GUI_QA NOT_RUN and READY_FOR_MANUAL_QA, never PASS.
- Quality gates: working/staged whitespace checks plus `git diff --check <PR-base>...HEAD` for committed changes, repository validation, applicable isolated probes, evidence review, clean final Git status. Report blocked checks honestly.
