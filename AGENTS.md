# GO_FLORA agent guardrails

- Follow the authorized issue/stage. Stage 00 permits documentation and isolated architecture probes only; no production painter, generator, or Stage 01 implementation.
- Use repository-relative paths in reusable commands. Do not inspect, edit, copy, or delete the separate Blender GAME_FLORA project.
- Put Stage 00 outputs in `stages/00_source_audit/`, shared design documents in `docs/`; downloaded dependencies, demos, binaries, and caches in ignored `.scratch/` only.
- Verify source/release identity using pinned revisions and checksums. Source inspection, author claims, runtime results, and unknowns must be labeled separately.
- Record each executed probe as PASS or FAIL with exact command/log; unexecuted checks are NOT_RUN. Never substitute code analysis for runtime evidence.
- No third-party assets/code redistribution without license review and owner authorization. Do not adopt a final GO_FLORA license silently.
- Use `codex/stage-00-foundation` for Stage 00; commit, push, and prepare a PR toward `main`. Never force-push, rewrite history, auto-merge, or publish releases.
- Quality gates: `git diff --check`, repository validation, applicable isolated probes, evidence review, clean final Git status. Report blocked checks honestly.
- For tasks using PixelLab MCP, read https://api.pixellab.ai/mcp/docs before choosing tools or parameters and use its available MCP tools directly.
