# Product vision

GO_FLORA should become a free, openly published, editor-first vegetation workflow for Godot. Artists place and revise vegetation on collision-backed 3D surfaces without committing to a terrain plugin. It takes interaction ideas from Unreal Foliage Mode; it does not reuse Epic code or assets.

Status on 2026-10-15: Stage 01 is owner-accepted. Stage 02–02.3 is integrated through [PR #6](https://github.com/alekseypilishkov-gif/go_flora/pull/6), merge `b9672974bb3403b5c2326f507ddd76e7cf4158fd`. **Stage 02.3 — FINALIZED / OWNER GUI PASS. Stage 02 overall — INTEGRATED, BUT MANUAL ACCEPTANCE INCOMPLETE.** Remaining GLB/PackedScene, UV-atlas and broader integration GUI cases are not claimed PASS. [Acceptance scope](../stages/02_imported_alpha_vegetation/integration/2026-10-15/owner_acceptance.md) and historical evidence remain separate from future product plans.

## Users and tasks

| Persona | Task | Desired result |
| --- | --- | --- |
| Solo Godot level designer | Dress a handmade mesh level with imported plants | Paint and erase on arbitrary surfaces; scene survives save/reopen |
| Environment artist | Mix grasses, shrubs and trees | Weighted sets, repeatable variation, slope/height filters, shared materials |
| Technical artist | Change vegetation density or draw distance | Previously placed records update without repainting; clear performance controls |
| Gameplay developer | Place an interactive tree or prop | PackedScene behavior and collisions preserved through explicit scene fallback |

## MVP boundaries

Stage 01 is a vertical slice with static Mesh sources, a small weighted palette, paint/erase/single placement, radius/density, scale/yaw variation, normal alignment, collision masks, slope/height filters, one undo action per stroke, persisted logical records, spatial MultiMeshes, and per-set draw distance affecting existing batches. Scene save/reopen and plugin disable/re-enable must not destroy authoritative data.

Selection and Reapply require stable instance IDs and stored placement seeds/brush revisions now; complete selection UX, Reapply filters, and density reconciliation remain future work. The plugin is useful without Tree3D. Stage 02 now includes imported GLB/PackedScene classification, PNG/WebP alpha cards/atlas regions and explicitly reviewed constrained scene fallback. Stage 02.1–02.3 adds the named palette, Inspector/Mix/Selected UX, native picker fixes, continuous Erase and safe source removal. Optional generated providers are not implemented.

## Later work

The planned [GO_FLORA Studio workspace](GO_FLORA_STUDIO.md) separates asset creation from the compact Painter beside Inspector. Future modules are Tree Generator (shape/topology/Seed/polygon budget), [Retro Texture Processor / Texture Lab](RETRO_TEXTURE_PROCESSOR.md), Material Library, Atlas Builder and Bake & Export. These are architectural plans, not implemented tools. SLK_img2pixel is an algorithm research candidate; its author-declared CC0 and separate third-party conditions are recorded without copying upstream code.

[Surface Material Painting DRAFT v0.1](SURFACE_MATERIAL_PAINTING_DRAFT.md), tracked in [Issue #10](https://github.com/alekseypilishkov-gif/go_flora/issues/10), adds a terrain-independent architecture backlog for layered ground materials. Foliage and Surface modes, separate persisted masks/data and Undo/Redo, initial ground-mesh mapping, RGBA weightmaps and optional future read-only interaction with foliage are proposed. Arbitrary 3D topology and a stable API are not promised. This draft is not an accepted ADR and does not modify GFInstanceRecord schema 1.

The sequence remains Stage 03 Tree Generator/optional providers, Stage 04 Optimization, Stage 05 Release/open beta. Stage 03 may evaluate optional Tree3D trees/shrubs after provenance and licensing review; it has not started. Stage 04 will measure chunking, LOD, selective colliders, wind and fade. Surface Painting has no final stage number or approved implementation date. A future Terrain3D adapter is optional; core targeting remains terrain-independent. Publication requires later gates and explicit owner approval.

Stage 00 and Stage 01 are accepted; the narrower Stage 02.3 owner acceptance does not complete all Stage 02 cases. [ADR 0001](ARCHITECTURE_ADR_0001.md) remains ACCEPTED. There is no promise of infinite worlds, per-instance MultiMesh culling, support for every imported scene or production performance. Architectural documentation alone authorizes no implementation or release.
