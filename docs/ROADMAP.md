# Roadmap

Every stage needs its own owner-approved issue, branch, PR, evidence and stop point. Stage 00 does not authorize subsequent implementation.

| Stage | Scope | Exit gate |
| --- | --- | --- |
| 00 | Research, Tree3D/source/license audit, architecture and repository foundation | Auditable evidence, honest PASS/FAIL/NOT_RUN, ADR and owner review; no release |
| 01 | Painter vertical slice on generic collision-backed surfaces | Undoable paint/erase/single; weighted static sources; scene round trip; two-cell rendering; set draw distance updates existing placements |
| 02 | Imported assets and grass/alpha cards | Mesh/GLB/PackedScene classification, owned materials, atlas/pivot controls, renderer tests, graceful fallback |
| 03 | Optional generated tree/shrub providers | Tree3D source/build identity resolved or explicitly limited; licenses approved; cached ordinary mesh variants; lifecycle tests |
| 04 | Optimization and extensions | Measured chunk sizing, explicit LOD, selective collisions, wind/fade gates, optional Terrain3D adapter; platform evidence |
| 05 | Open beta | Packaging, clean-machine installation/export, migrations, supported versions, docs, owner-approved license and publication |

Stage 00 is accepted/merged via PR #2. Stage 01 is owner-accepted/merged via [PR #4](https://github.com/alekseypilishkov-gif/go_flora/pull/4) at `5c076153e1dea6363b885e82f4ef391808586348`. Its historical [report](../stages/01_painter_mvp/report.md) and unexecuted wider cases remain unchanged. [Issue #5](https://github.com/alekseypilishkov-gif/go_flora/issues/5) authorizes Stage 02 only: **READY_FOR_MANUAL_QA**, [report](../stages/02_imported_alpha_vegetation/report.md), [owner acceptance](../stages/02_imported_alpha_vegetation/manual_qa.md). Stage 03 and later are not authorized. No automatic merge or release.
