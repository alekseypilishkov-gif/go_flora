# Product vision

GO_FLORA should become a free, openly published, editor-first vegetation workflow for Godot. Artists place and revise vegetation on collision-backed 3D surfaces without committing to a terrain plugin. It takes interaction ideas from Unreal Foliage Mode; it does not reuse Epic code or assets.

## Users and tasks

| Persona | Task | Desired result |
| --- | --- | --- |
| Solo Godot level designer | Dress a handmade mesh level with imported plants | Paint and erase on arbitrary surfaces; scene survives save/reopen |
| Environment artist | Mix grasses, shrubs and trees | Weighted sets, repeatable variation, slope/height filters, shared materials |
| Technical artist | Change vegetation density or draw distance | Previously placed records update without repainting; clear performance controls |
| Gameplay developer | Place an interactive tree or prop | PackedScene behavior and collisions preserved through explicit scene fallback |

## MVP boundaries

Stage 01 is a vertical slice with static Mesh sources, a small weighted palette, paint/erase/single placement, radius/density, scale/yaw variation, normal alignment, collision masks, slope/height filters, one undo action per stroke, persisted logical records, spatial MultiMeshes, and per-set draw distance affecting existing batches. Scene save/reopen and plugin disable/re-enable must not destroy authoritative data.

Selection and Reapply require stable instance IDs and stored placement seeds/brush revisions now; complete selection UX, Reapply filters, and density reconciliation follow the vertical slice. The plugin is useful without Tree3D. Imported GLB resources, alpha-card creation, scene fallback, and optional generated providers enter later stages.

## Later work

Stage 02 adds asset interchange and grass/card sources. Stage 03 evaluates optional Tree3D trees/shrubs after provenance and licensing review. Stage 04 measures chunking, LOD, selective colliders, wind, and fade. A Terrain3D adapter can provide terrain-specific targeting later; the core keeps its generic collision target interface. Open beta, installation instructions and Asset Library publication require later gates and explicit approval.

Stage 00 is accepted. Stage 01 contains an initial static-Mesh painter and original demo; owner GUI acceptance is pending. There is no promise of infinite worlds, per-instance MultiMesh culling, support for every imported scene, or production performance.
