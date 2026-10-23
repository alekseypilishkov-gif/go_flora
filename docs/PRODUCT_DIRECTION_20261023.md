# GO_FLORA — Product Direction Decision (23 October 2026)

**Status:** owner-approved PRODUCT DIRECTION. **Implementation of Surface Painting: NOT STARTED.** This document revises the product roadmap; it is not a release, stage implementation approval, or new accepted technical ADR.

## Mission

GO_FLORA is a **terrain-independent Godot 4.x environment-authoring editor plugin**. Its goal is to combine:
1. **Foliage / Object Painter** — the existing system for placing ready-made Mesh, GLB, PackedScene and PNG/WebP alpha-card vegetation/decor with palettes, Undo/Redo, persistence and diagnostics.
2. **Surface Material Painting** — the next primary capability, inspired by Unreal Landscape Paint: painting masks/weights of prepared Grass Ground, Dirt, Rock, Mud and other material layers on supported surfaces.
3. **Mesh Paint** and **Surface→Foliage rules** — future, separately gated capabilities for painting on particular meshes and filtering new object placements by read-only material weights.

**Unreal Foliage / Landscape Paint / Mesh Paint are workflow and UX references, not a commitment to full feature parity in the MVP.** A terrain sculptor is not in the initial scope.

## Superseded direction

The former Stage 03 **Tree Generator / Tree3D generated providers** plan is removed from the active GO_FLORA roadmap. GO_FLORA will not generate complete trees/shrubs, PBR materials, textures, bake atlases or ready-made plant models itself as a core responsibility. Existing user assets are imported; **GAME_FLORA** remains a separate Blender addon. GO_FLORA Studio's Texture Lab, retroization and generated asset tools are deferred and do not gate Surface MVP. Historic research and licensing decisions are preserved.

## Data and rendering boundaries

- Keep the existing Foliage `GFInstanceRecord`, `GFVegetationSet` and Stage 02 user-resource formats backward compatible. Surface masks, material-layer descriptors, target mappings, and painted weights use separate persistent schemas.
- **Proposed MVP:** one explicitly supported ground-like `MeshInstance3D`, suitable collision, one managed material slot and unambiguous `PLANAR_LOCAL_XZ` paint mapping. No claim of supporting arbitrary walls, caves, stacked surfaces, overlapping planar projection, multiple material slots or generic user shaders.
- First candidate: **four normalized weight-blended layers**, including a deterministic base channel, stored in lossless RGBA8 masks; exact format and write protocol are research questions.
- Keep `SurfaceMaterialSet` reusable and non-destructive while editable mask data belong individually to target surfaces. Preserve source Mesh/Texture/Material and restore prior material assignment. Never treat GPU `ImageTexture` as persistent source of truth.
- Independent alpha overlays (snow/puddles), height-aware blending, 8+ layers, per-mesh UV/texture paint, and vertex paint are distinct future contracts.
- Foliage may **read** Surface layer weights to filter **new** placements. Repainting ground must not silently delete existing placement records. Any Rescatter/Reconcile requires explicit preview, confirmation and Undo.

## Stages and authority

| Stage | Scope | Authorization/status |
| --- | --- | --- |
| 02.x | Source Identity / Issue #18, PR #19 (0.2.6-dev) | PR OPEN, READY_FOR_OWNER_QA, manual GUI NOT_RUN; no merge |
| 03 | Surface Painting Architecture & Feasibility | **Research/design only authorized**; no plugin implementation |
| 04 | Surface Painter MVP: 4 layers, save/reopen, Undo, safe material ownership | NOT STARTED; separate owner approval required |
| 05 | Read-only Surface→Foliage rules for new paint placements | NOT STARTED |
| 06 | Mesh Paint, overlays and height-aware layer refinements | NOT STARTED |
| 07 | Profiling, renderer compatibility, optimization and optional beta | NOT STARTED; release requires approval |

Stage 03 must audit the current addon, native Godot 4.7.2 APIs, target support matrix, shader strategy, UV/projection correctness, material binding, durable storage, dirty-state/atomic save, scene/editor UndoRedo, cancel semantics, compatibility/GPU costs and module boundaries. Deliver a technical design, alternatives, evidence and a limited Stage 04 implementation proposal. Experimental probes only in isolated temporary `.scratch`, without changing `addons/go_flora` or `C:\Dev\TEST_FLORA`.

## Current QA and safety invariants

As last verified on 23 October 2026: `main` includes PR #14/#17 (0.2.5-dev at `d911087157ecaa9e3ab2b92d95049f2999aebab1`). Stage 02 is FINALIZED / ACCEPTED_WITH_DEFERRED_QA; Issue #12 deferred, Issue #15 UX backlog. Issue #18 PR #19 (head `7093b07922999778d01b3afa49ebc4272cc10cde`) contains the canonical-external-source fix but is **NOT MERGED / INTERACTIVE_GUI_QA NOT_RUN**.

Only owner-managed TEST_FLORA project `C:\Dev\TEST_FLORA` and scene `res://go_flora_stage01_demo/demo.tscn` are used for physical owner QA: one manual step, one owner response. ZIP inspection/sha, backups and explicit approval precede installation. Do **not** auto-sync the local checkout, change the QA project, migrate old Sources, merge, release, or advance implementation stages without separate owner authorization.

## Source documents

- [Roadmap](ROADMAP.md)
- [Surface Painting DRAFT](SURFACE_MATERIAL_PAINTING_DRAFT.md)
- [Studio (historical/optional)](GO_FLORA_STUDIO.md)
- [Issue #10 / Stage 03 architecture research](https://github.com/alekseypilishkov-gif/go_flora/issues/10)
- [Owner product vision](https://docs.google.com/document/d/1Jy2_9_ILvEFk1HAxjFrfrHX_Y32FoG793v8eLefYLSc/edit)
- [Owner roadmap](https://docs.google.com/document/d/12j2p5CuVLecJ66iFDDJ99gPcaD1AF2IAU-d0t4r_zUs/edit)
- [Owner Surface architecture](https://docs.google.com/document/d/1fkWorFG1pNALeVlCUWD2sTk9DmHgrMl7ZeCuVeohDaA/edit)

Only this direction and Stage 03 **research** are approved. The proposed classes, layer formats, renderer choices and later stage numbers remain design-level until technical/owner review.
