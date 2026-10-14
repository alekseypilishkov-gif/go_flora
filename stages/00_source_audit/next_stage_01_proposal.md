# Stage 01 proposal — requires owner approval

**Do not execute from Stage 00.** Proposed branch: a separately approved Stage 01 branch/issue. Target Godot 4.7.2 first; expand support only through tests. Follow ADR 0001 after owner review.

Build a minimal editor vertical slice in `addons/go_flora/`: one VegetationLayer3D, typed versioned records, static Mesh source, VegetationSet with weighted entries and draw distance, brush state and editor dock. Add paint/erase/single on arbitrary collision-backed surfaces with mask, radius/density, slope/height filter, scale/yaw variation, normal alignment and stable versioned seeds. Use small cell MultiMeshes keyed by set/mesh/material. One completed stroke is one scene-bound undo transaction; Escape cancels it.

Deliver and verify these scenarios:

1. Paint two ordinary meshes on a plane and another rotated/scaled collision mesh; no hit on a visual mesh without collision. Camera navigation continues working.
2. Erase affects only selected layer/set; single creates exactly one record; zero/invalid palette weights fail gracefully.
3. Undo/redo restores logical IDs/transforms and rendering; undo across scene switching does not retain wrong scene history. Save, close, reopen in a separate editor process and compare records.
4. Create at least two cells, show independent visibility and maintain correct bounds. No per-instance culling claim.
5. Change one set's draw distance after placement: every old cell for that set updates, another set does not; record count and transforms remain unchanged.
6. Missing source/provider or newer schema preserves data with a useful diagnostic. Verify negative cell coordinates, layer transform and serialization invariants.
7. Benchmark a small fixed scene with documented hardware/count and frame/update times; do not invent a large-forest performance promise.

Keep complete selection/Reapply UI, card generator, Tree3D integration, native optimization, complex LOD/fade/wind, automatic colliders, terrain adapters and publishing out of this vertical slice. Reserve their fields/interfaces without implementing them. Scene fallback implementation and GLB classification follow in Stage 02; Stage 01 unsupported input must be diagnosed, not silently flattened.

Prerequisites/owner decisions: MIT adoption, ADR A approval, 4.7.2 baseline, alpha-scissor default, and confirmation of this narrowed scope. Native build remains NOT_RUN until an existing compiler + local SCons/godot-cpp setup is available; it is not a Stage 01 painter dependency. Repeat the real interactive viewport checks that Stage 00 marks NOT_RUN before accepting the slice. Submit a scoped PR and stop for owner review.
