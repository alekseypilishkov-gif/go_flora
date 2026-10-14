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

The detailed [Stage 01 proposal](../stages/00_source_audit/next_stage_01_proposal.md) is a review artifact, not an active implementation instruction.
