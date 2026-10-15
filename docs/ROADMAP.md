# Roadmap

Every stage needs its own owner-approved issue, branch, PR, evidence and stop point. Stage 00 does not authorize subsequent implementation.

| Stage | Scope | Exit gate |
| --- | --- | --- |
| 00 | Research, Tree3D/source/license audit, architecture and repository foundation | Auditable evidence, honest PASS/FAIL/NOT_RUN, ADR and owner review; no release |
| 01 | Painter vertical slice on generic collision-backed surfaces | Undoable paint/erase/single; weighted static sources; scene round trip; two-cell rendering; set draw distance updates existing placements |
| 02 | Imported assets and grass/alpha cards | Mesh/GLB/PackedScene classification, owned materials, atlas/pivot controls, renderer tests, graceful fallback |
| 03 | Tree Generator and optional generated tree/shrub providers — planned, NOT STARTED | Shape/topology/Seed/polygon-budget design; Tree3D source/build identity resolved or explicitly limited; licenses approved; cached ordinary mesh variants; lifecycle tests |
| 04 | Optimization and extensions — planned | Measured chunk sizing, explicit LOD, selective collisions, wind/fade gates, optional Terrain3D adapter; platform evidence |
| 05 | Release / open beta — planned | Packaging, clean-machine installation/export, migrations, supported versions, docs, owner-approved license and explicit publication authorization |

Stage 00 is accepted/merged via PR #2. Stage 01 is owner-accepted/merged via [PR #4](https://github.com/alekseypilishkov-gif/go_flora/pull/4) at `5c076153e1dea6363b885e82f4ef391808586348`. Historical evidence and unexecuted wider cases remain unchanged.

Stage 02–02.3 is merged by explicit owner exception through [PR #6](https://github.com/alekseypilishkov-gif/go_flora/pull/6), merge `b9672974bb3403b5c2326f507ddd76e7cf4158fd`. **Stage 02.3 — FINALIZED / OWNER GUI PASS**, [Issue #9 CLOSED](https://github.com/alekseypilishkov-gif/go_flora/issues/9). **Stage 02 overall — INTEGRATED, BUT MANUAL ACCEPTANCE INCOMPLETE.** GLB/PackedScene, UV-atlas and other unexecuted integration cases remain **NOT_RUN / READY_FOR_MANUAL_QA**. [Issue #5](https://github.com/alekseypilishkov-gif/go_flora/issues/5) and [Issue #8](https://github.com/alekseypilishkov-gif/go_flora/issues/8) are not closed as fully accepted by this merge. See [owner acceptance boundaries](../stages/02_imported_alpha_vegetation/integration/2026-10-15/owner_acceptance.md), [Stage 02 report](../stages/02_imported_alpha_vegetation/report.md) and [manual QA](../stages/02_imported_alpha_vegetation/manual_qa.md).

## Architecture backlog without stage reassignment

| Direction | Document/status | Open gate |
| --- | --- | --- |
| GO_FLORA Studio | [Workspace plan](GO_FLORA_STUDIO.md), not implemented | Main-screen UX, shared asset ownership and per-module implementation tasks; compact Painter remains available |
| Retro Texture Processor / Texture Lab | [Draft](RETRO_TEXTURE_PROCESSOR.md), SLK_img2pixel algorithm research only | Per-file license/provenance review, selected algorithms, recipe/persistence and GPU/GUI criteria |
| Surface Material Painting | [DRAFT v0.1](SURFACE_MATERIAL_PAINTING_DRAFT.md), [Issue #10](https://github.com/alekseypilishkov-gif/go_flora/issues/10), design only | Target/mapping support matrix, mask storage/save/Undo, material ownership, shader backend proof and separate implementation authorization |

Surface Painting remains an independent architectural backlog, with no final stage number or implementation date. The issue's working label SURFACE.00 is not a replacement for Stage 03/04/05. The owner wants its design seams reserved before adding future generators/Texture Lab; that does not authorize coding or reorder the agreed stages. [ADR 0001](ARCHITECTURE_ADR_0001.md) remains ACCEPTED. Stage 03 and later, release and Asset Library publication require separate authorization.
