# Roadmap

**CURRENT DIRECTION — owner decision, 23.10.2026.** GO_FLORA is now a foliage/object + surface-material painting environment editor, with optional later mesh paint and foliage-by-surface-layer rules. The earlier Tree3D Generator roadmap was **superseded**. See [product direction decision](PRODUCT_DIRECTION_20261023.md) and [Stage 03 research Issue #10](https://github.com/alekseypilishkov-gif/go_flora/issues/10). This is documentation and owner-approved research scope, **not a Stage 04 implementation authorization**.

Every stage needs its own owner-approved issue, branch, PR, evidence and stop point. Stage 00 does not authorize subsequent implementation.

| Stage | Scope | Exit gate |
| --- | --- | --- |
| 00 | Research, Tree3D/source/license audit, architecture and repository foundation | Auditable evidence, honest PASS/FAIL/NOT_RUN, ADR and owner review; no release |
| 01 | Painter vertical slice on generic collision-backed surfaces | Undoable paint/erase/single; weighted static sources; scene round trip; two-cell rendering; set draw distance updates existing placements |
| 02 | Imported assets and grass/alpha cards | Mesh/GLB/PackedScene classification, owned materials, atlas/pivot controls, renderer tests, graceful fallback |
| 03 | Surface Painting Architecture & Feasibility — RESEARCH ONLY | Audit mapping/material ownership/masks/atomic save/Undo/shader/UX on Godot 4.7.2; support matrix + ADR candidate + owner review; no addon changes |
| 04 | Surface Painter MVP — NOT STARTED | Single supported ground-like MeshInstance3D; proposed 4 normalized weight-blended layers; reusable layer references vs per-surface mask data; paint/erase, undo, save/reopen, diagnostics; owner-approved implementation required |
| 05 | Surface→Foliage Rules — NOT STARTED | Read-only weight queries for new placements; explicit and reversible Reconcile only; existing placements untouched |
| 06 | Mesh Paint, overlays and advanced layer blending — NOT STARTED | UV/mesh target support and seam-aware persistence; Snow/puddles independent overlays; height-aware transitions, platform proof |
| 07 | Optimization, platform coverage and open beta — NOT STARTED | Profiling, shader sampling costs, renderer targets, packaging/migration/licensing, explicit owner release permission |

Stage 00 is accepted/merged via PR #2. Stage 01 is owner-accepted/merged via [PR #4](https://github.com/alekseypilishkov-gif/go_flora/pull/4) at `5c076153e1dea6363b885e82f4ef391808586348`. Historical evidence and unexecuted wider cases remain unchanged.

Stage 02–02.3 is merged by explicit owner exception through [PR #6](https://github.com/alekseypilishkov-gif/go_flora/pull/6), merge `b9672974bb3403b5c2326f507ddd76e7cf4158fd`. **Stage 02.3 — FINALIZED / OWNER GUI PASS**, [Issue #9 CLOSED](https://github.com/alekseypilishkov-gif/go_flora/issues/9). **Stage 02 overall — FINALIZED / ACCEPTED_WITH_DEFERRED_QA (owner, 16.10.2026).** Native/main functionality and specific GUI flows were accepted; three deferred regressions remain under [Issue #12](https://github.com/alekseypilishkov-gif/go_flora/issues/12). PR #14 Source Diagnostics and PR #17 Configuration Warnings are merged in `main` at `d911087157ecaa9e3ab2b92d95049f2999aebab1` (0.2.5-dev). **Issue #18 / PR #19 (0.2.6-dev): OPEN, READY_FOR_MANUAL_QA, no merge, INTERACTIVE_GUI_QA NOT_RUN.** [Issue #15](https://github.com/alekseypilishkov-gif/go_flora/issues/15) remains deletion UX backlog. See [owner acceptance boundaries](../stages/02_imported_alpha_vegetation/integration/2026-10-15/owner_acceptance.md), [Stage 02 report](../stages/02_imported_alpha_vegetation/report.md) and [manual QA](../stages/02_imported_alpha_vegetation/manual_qa.md).

## Updated architectural priorities — 23.10.2026

| Direction | Document/status | Open gate |
| --- | --- | --- |
| GO_FLORA Studio | [Historical workspace concept](GO_FLORA_STUDIO.md), DEFERRED | Only compact, mutually exclusive Foliage/Surface tools and existing-material selection are required for MVP; optional workspace later |
| Retro Texture Processor / Texture Lab | [Historical draft](RETRO_TEXTURE_PROCESSOR.md), DEFERRED | Not a dependency or gate for Surface Painting; preserve prior research and licenses |
| Surface Material Painting | [DRAFT v0.1 + current direction](SURFACE_MATERIAL_PAINTING_DRAFT.md), [Issue #10 / Stage 03](https://github.com/alekseypilishkov-gif/go_flora/issues/10), RESEARCH ONLY | Supported targets/mapping, save/undo, material ownership, renderer feasibility, separate Stage 04 authorization |

**Owner-approved reassignment, 23.10.2026:** Stage 03 = **Surface Painting Architecture & Feasibility (research/design only)**. Stage 04 implementation is NOT authorized. Old Stage 03 Tree3D Generator, Stage 04 Optimization and Stage 05 Release are historical plans, not active assignments. No full plant/material/texture generator inside GO_FLORA. [ADR 0001](ARCHITECTURE_ADR_0001.md) remains ACCEPTED; preserving Foliage schema 1 and all historical evidence is mandatory. Research cannot merge PR #19, release, alter TEST_FLORA, or silently advance a coding stage.

## Superseded 15.10 roadmap (historical only)

Former Stage 03: Tree3D / generated trees and shrubs; former Stage 04: optimization/LOD; former Stage 05: release/open beta. These scopes were valid historical proposals, **superseded by the owner on 23.10.2026**, not completed or silently deleted. License/provenance audit evidence stays in the project.
