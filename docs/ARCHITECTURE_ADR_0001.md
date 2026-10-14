# ADR 0001 — Editor-first logical data with optional plant providers

Date: 2026-10-14. Status: **ACCEPTED — ADR A**, per [owner review](https://github.com/alekseypilishkov-gif/go_flora/pull/2#pullrequestreview-5516040817), [merged PR #2](https://github.com/alekseypilishkov-gif/go_flora/pull/2), and [Stage 01 authorization](https://github.com/alekseypilishkov-gif/go_flora/issues/3). Baseline: **Godot 4.7.2**, Windows x86_64 verified in Stage 00. Tree3D advertises 4.5+; GO_FLORA does not yet claim 4.5, Linux or macOS runtime support. Stage 00 findings below are historical; Stage 01 evidence lives in its own directory.

The [implemented Stage 01 contracts](STAGE_01_DATA_CONTRACTS.md) distinguish this static-Mesh vertical slice from the broader provider, migration and optimization proposals below. Real interactive owner acceptance remains pending.

## Options and decision

| | A: GDScript EditorPlugin + optional provider | B: C++ editor/runtime + GDExtension providers |
| --- | --- | --- |
| Portability/packaging | Core ships as scripts/resources; optional native provider needs its own platform binaries | Every editor install/export depends on compatible native binaries |
| Build cost | None for painter core; isolated tree integration can be deferred | SCons, godot-cpp pin, compiler and platform matrix required from first slice |
| Maintenance/extensibility | Godot editor APIs directly accessible; provider registry avoids terrain/generator coupling | Explicit ABI/API work, native debugging and rebuilds for each platform |
| Performance | Bulk data updates and limited dirty-cell rebuilds first; profile actual bottlenecks | Native hot loops possible, but early complexity without measurements |
| Editor UX | Fast iteration in docks, inspectors and undo manager | Same Godot UX possible but slower iteration and more bindings |

**Recommend A.** Stage 00 executed GDScript editor/physics/resource probes and a native Tree3D import/extraction probe. No performance comparison was run. Keep a native optimization seam for data transforms only after profiling. Tree3D is an optional source provider, never a prerequisite for painting.

## Source contract

Proposed `VegetationSource : Resource` fields: immutable `source_id`, `schema_version`, `kind`, URI/resource reference, `revision_hash`, import settings and provenance reference. `resolve(context) -> SourceResolution` returns status (`READY`, `UNAVAILABLE`, `UNSUPPORTED`, `ERROR`), diagnostic, `capabilities`, static parts (`Mesh`, per-surface material, local transform, conservative bounds), optional `PackedScene`, optional collider recipe and variant key.

| Kind | Resolution |
| --- | --- |
| Static Mesh | Batch ordinary surfaces with effective materials; preserve resource ownership |
| Imported GLB/PackedScene | Classify entire hierarchy: static parts may be explicitly baked with accumulated transforms; scripts, animation, skins, particles, lights, signals or authored colliders default to scene-instance fallback |
| Texture card | User PNG/WebP alpha or atlas region; card dimensions, pivot, crossed-card count, material policy; Stage 02 |
| Generated tree/shrub | Provider ID + pinned recipe revision + seed; cache finite shared variants as ordinary meshes; Stage 03 |
| Unknown/unavailable | Preserve source and records, show actionable inspector diagnostic, skip rendering or display editor-only proxy; never crash, delete data or silently flatten gameplay scenes |

Provider API is proposal only. Tree3D extraction can inspect `get_children(true)` in a pinned adapter, duplicate meshes and capture surface overrides/local transforms. Child order is not a stable semantic trunk/leaf API; validate expected topology and fail closed on changes. An upstream public bake/snapshot method would improve stability; this does not justify changing C++ in Stage 00.

## Deterministic sets, brush and records

`VegetationSet : Resource`: stable set ID, version, ordered weighted entries (source ID + variant policy), enabled/density multiplier, draw distance (0 = unlimited), fade mode/interval, optional LOD policy. Reject negative/NaN weights, duplicate IDs and an all-zero active palette; preserve missing entries visibly. Stable source-ID order and a versioned counter-based random algorithm (`sha256-v1` proposed, fixed byte encoding) consume `(stroke_seed, candidate_index, purpose)` so candidate rejection does not reshuffle other choices. Store chosen source and transform; loading does not regenerate placement. Hash-based sampling and distribution quality are **NOT_RUN** in Stage 00 and require Stage 01 fixtures; do not rely on RNG stability across Godot versions.

`BrushParameters`: radius in metres, density per m², spacing, brush seed, yaw/scale ranges, normal-alignment weight, slope in degrees from up, height in layer coordinates, collision mask, target include/exclude rules, maximum ray length and sample budget. Stroke spacing is world-distance based; sample generation and physics targeting are separate interfaces. GPU frame rate must not set density.

`InstanceRecord`: stable instance/stroke/source/set/layer IDs, source revision, position, surface normal, full local `Transform3D`, seed, placement revision, cell coordinate, flags (locked/hidden/selected overrides), optional target reference and brush snapshot ID. Position must equal transform origin; enforce this invariant on writes/migrations. Coordinates are relative to a `VegetationLayer3D` root; transform hit positions/normals into that space correctly under non-uniform scale. Recompute derived cells using floor(x/cell_size), floor(z/cell_size), including negative coordinates.

`VegetationLayerData : Resource` owns schema version, records, stroke descriptors, set/source references and generation revision. Logical records are authoritative. GPU slot indices, RIDs, MultiMesh buffers and cell nodes are disposable caches. One record may produce multiple render parts. Never use cache indices as stable instance IDs.

## Editor operations and targeting

An editor dock selects source/set/layer and modes. `EditorPlugin._forward_3d_gui_input` handles pointer events only in the active tool; camera navigation and shortcuts remain available. Project camera rays against arbitrary `PhysicsDirectSpaceState3D` collision-backed surfaces via a `SurfaceTarget` interface. Exclude plugin previews/vegetation colliders from hit masks; filter collision object, layer, slope, height and normal. A visible mesh without collision reports no eligible target. Later terrain adapters implement this same hit result, not a new record format.

Paint/erase/single/select/Reapply produce transactions of logical added/removed/modified records. Preview a stroke without persistent cache mutation; on pointer release commit one `EditorUndoRedoManager` action, tied to the edited scene history. Store before/after record deltas and stable IDs; execute both directions through the same data mutation and dirty-cell invalidation path. Cancel on Escape, scene change or lost tool context without commit. Bound undo memory and candidate count. Selection is editor state unless an explicit persisted lock/flag is changed.

Reapply explicitly chooses which fields to recompute from stored seeds/brush revision (rotation, scale, alignment, source or density); frozen/locked overrides are preserved. Set visibility/draw-distance edits only update cached presentation. Density reconciliation is a separately undoable data operation, not a silent deletion when a slider changes. Surface reprojection is explicit if source geometry moved; a lost target reference retains the last transform and raises a diagnostic.

## Rendering and live set updates

Batch key: `(layer_id, set_id, cell, variant_revision, mesh/part, effective material tuple, LOD)`. Share mesh/material variants across cells but use separate MultiMesh resources and renderer nodes per cell. Include set ID even for identical meshes because draw distance, fade and visibility may differ. For multi-surface meshes preserve each surface's material; incompatible per-instance effects or scene semantics choose fallback.

Compute conservative cell bounds from transformed mesh AABBs plus wind displacement margin. Place cell nodes at consistent local origins. Dirty-cell rebuilds produce an instance-ID→slot map and replace only affected buffers. Set format/colors/custom-data flags before allocating instance_count. Camera-frustum/occlusion/visibility ranges apply to the **whole MultiMesh**, never independently to its members. `visible_instance_count` is a prefix count, not an arbitrary per-instance culling mechanism. See [Godot MultiMesh](https://docs.godotengine.org/en/stable/classes/class_multimesh.html).

Maintain set-ID→existing renderer-node index. On `VegetationSet.changed`, increment presentation revision and propagate enabled state, `visibility_range_end`, margins and material policy to every existing batch and appropriate scene fallback, without creating new placement records. Distance is from the GeometryInstance AABB center, so cell edges have a tolerance; smaller cells improve accuracy at greater node/draw cost. Per-set draw-distance propagation is designed here, **NOT_RUN** as a complete subsystem. A Stage 01 acceptance test must change it after painting and verify old cells update.

Default fade is disabled with hysteresis. Native visibility fade/shader variants are capability-gated and need renderer tests; shader-driven fade does not remove individual members from the draw call. Scene fallback preserves authored nodes/scripts/colliders; distance-based hiding must not disable gameplay processing without an explicit policy. [Godot visibility ranges](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html) explain node-level thresholds and fade cost.

## Alpha cards, shaders and ownership

Accept lossless PNG/WebP transparency, explicit atlas region/gutters, UVs, card dimensions and ground pivot. No bundled third-party samples. Alpha-scissor is the recommended first option: Stage 00 pixel probes pass Compatibility, Mobile and Forward+. Alpha-hash fails the Compatibility probe (black/zero-alpha hole instead of expected background); Vulkan probes pass. This is an observed configuration-specific result, not a universal engine bug claim. Probe bilinear filtering, mip edges, depth/shadows and partial alpha later. Do not silently promote hash or identical renderer behavior.

Original source resources remain immutable. Each owned material variant is copied deliberately and keyed by policy/revision; shared user materials are not edited globally. Tree3D stores material overrides on child nodes, so detached mesh arrays alone do not preserve appearance. Provider must capture these overrides. Any later wind channel/global uniform names are namespaced, installed explicitly and removed only when owned by GO_FLORA. Preserve vertex color channels when baking; avoid tint overwriting wind influence. LOD, collider selection, wind and Terrain3D adapters are later enhancements, not painting blockers.

## Persistence, migration and distribution

First slice uses typed Resource data embedded in `.tscn` or an explicit external `.tres`; save owned child nodes only, with correct scene owner. On scene reopen validate schema and source availability, then rebuild caches deterministically. On plugin disable keep runtime data; transient editor UI is removed. Runtime scripts load data and render, and contain no unconditional editor-class references. Generated variants baked as ordinary Godot resources can export without Tree3D; live recipes require the optional extension. Validate both export modes in Stage 03/05.

Migrations advance one schema version at a time on a copy, validate IDs/coordinates/types, retain old data until the new file saves, and reject newer schemas read-only. Separate generator recipe version, PRNG version and record schema version. Reimport invalidates source revision/cache but does not move placements automatically.

Core distribution: `addons/go_flora/{editor,data,rendering,sources}` with clean plugin.cfg and runtime/editor separation. Optional `addons/go_flora_tree3d/` package contains only approved providers, platform binaries and complete notices. Native dependencies pin source SHA, godot-cpp SHA, compiler/SCons versions and artifact digests; separate Windows/Linux/macOS debug/release/architecture builds. No broad compatibility claim until clean-machine editor/import/export tests. Android, Web, Windows ARM and macOS runtime remain untested. Stage 00 adds no distributable addon.

## Risks and validation gates

| Risk | Impact | Mitigation / gate |
| --- | --- | --- |
| Tree3D release tag differs from published binary source | Unreproducible provider | Preserve tag + main pins and digest; independent build/provenance comparison before integration |
| Missing asset/license notices | Redistribution blocked | Exclude demos/textures; owner license approval and notice allowlist |
| Internal Tree3D topology changes | Extraction breaks | Adapter capability checks, ordinary mesh bake, no core dependency |
| Cell-level culling pops/overdraw | Poor scene scale/UX | Conservative bounds, tunable measured cell size and hysteresis; no per-instance promise |
| Material or set sharing crosses layer boundaries | Existing instances change unexpectedly | Owned immutable variants, set-specific batches and explicit update index |
| Undo references temporary nodes / huge snapshots | Lost edits or excessive memory | Logical stable deltas, scene history binding, stress/cancel tests |
| Collision target cost or non-uniform transforms | Wrong placements | Mask/exclusion, bounded samples, transformed normal tests |
| Alpha-hash Compatibility result | Visible incorrect holes | Scissor default; hash disabled for that renderer until verified |
| Scene flattening drops scripts/collisions | Gameplay regression | Explicit classification and scene fallback |
| New resource schema or moved surfaces | Corrupt/stale placement | Versioned copy migrations, read-only future schema, explicit reprojection |
| Sparse environment/platform evidence | False support claims | Fix 4.7.2 baseline, enumerate NOT_RUN platforms/builds and manual viewport gates |
