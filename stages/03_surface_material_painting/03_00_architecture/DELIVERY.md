# Stage 03.00 — Delivery and stop point

**READY_FOR_OWNER_ARCHITECTURE_REVIEW.** Stage 03 research completed. **Surface implementation NOT STARTED / NOT AUTHORIZED. INTERACTIVE_GUI_QA: NOT_RUN / READY_FOR_MANUAL_QA.**

- Research branch: `codex/stage-03-surface-00-research`.
- Baseline: remote main `d911087157ecaa9e3ab2b92d95049f2999aebab1`.
- Isolated worktree: Codex managed `surface-03-00-research/GO_FLORA`; owner's primary checkout and PR #19 checkout retained.
- Exact delivered commit and research Draft PR URL are supplied in the final delivery message and PR head. This file is part of that commit; no self-referential future SHA is invented.
- [Report](SURFACE_03_00_ARCHITECTURE_REPORT.md), [decision matrix](DECISION_MATRIX.md), [technical contract](TECHNICAL_CONTRACT_PROPOSAL.md), [Stage 04 proposal](STAGE_04_MVP_PROPOSAL.md), [evidence inventory](EVIDENCE_INVENTORY.md).

Recommended candidate: dedicated Surface data/controller, local XZ ground-only mapping, four stable normalized RGBA8 channels, scene-embedded CPU authority, reusable prepared MaterialSet, owned ShaderMaterial with Texture2D facade/private GPU cache, and one scene Undo action per entire stroke.

Principal cost: capped map/target sizes and larger text scene files. Principal unresolved risks: lit normal/color parity and full sampler pressure; reliable topology/collider validation; complete target/material serialization and duplicate identity; native failed-save recovery; actual Surface input/UI lifecycle, export and performance. Stage 04 is feasible within the bounded profile after explicit owner approval of the [proposed scope and gates](STAGE_04_MVP_PROPOSAL.md).

## Evidence and quality gates

[Quality command results](evidence/quality.json), [owner checkout integrity](evidence/owner_integrity.json), [pinned addon identity](evidence/source_identity.json), [probe source checksums](evidence/probe_sources_manifest.json).

Final relevant probe cases: CPU 5 PASS, native Editor API 3 PASS, GPU/facade 4 PASS. Earlier 6 FAIL process cases remain recorded with causes in the inventory. No result is presented as owner interactive acceptance. New packages were not installed; no release/ZIP/manual scene was produced.

Working/staged whitespace, static repository validation, historical/source scope checks and committed PR-base diff checks are required for delivery. Post-commit checks are run against the final HEAD; runtime source/listing identity is independent of later documentation-only delivery commits. Source inspection is not relabeled runtime testing.

Only this Stage 03 directory changes in the research PR. Existing addon, tests, docs, previous-stage evidence and MIT/third-party notices remain unchanged. Primary checkout tracked/untracked manifest is compared before/after excluding ignored caches and Git administrative files; no TEST_FLORA/PR19 worktree content was inspected, copied or written.

PR #20 remains the owner-approved direction snapshot, open Draft and unmerged. PR #19 remains separate/open/unmerged; its owner GUI acceptance is not inferred from this work. Research branch is pushed and Draft PR targets main without modifying either existing PR.

**STOP. Await owner architecture decision. No merge, release, installation, resource migration or Stage 04 implementation is authorized by this delivery.**
