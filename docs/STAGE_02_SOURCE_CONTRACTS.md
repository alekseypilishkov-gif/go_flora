# Stage 02 — source resolution and persistence

Authorization: [Issue #5](https://github.com/alekseypilishkov-gif/go_flora/issues/5). Original implementation/assets MIT. See [user guide](../addons/go_flora/README.md) and [runtime evidence](../stages/02_imported_alpha_vegetation/evidence/README.md).

## Stable data

Layer/record schema remains **1**, including the Stage 01 SHA-256 counter algorithm, stable IDs, transforms, normal, serial, flags and source/set selection. No migration or placement rewrite is introduced. Source schema is explicitly **1**; fields are additive. Kind values remain `STATIC_MESH=0`, `SCENE_UNSUPPORTED=1`, `GENERATED_UNSUPPORTED=2`; new `IMPORTED_SCENE=3`, `ALPHA_CARD=4`. Old unsupported kinds require an explicit source edit before use. Future/invalid schemas preserve data and disable editing/rendering as appropriate.

New records retain a resolved source revision for new kinds; old static records retain `variant_revision`. Cache invalidation resolves the current source without replacing stored record revisions/positions. Historical source variant restoration is not implemented. Deleting a source never deletes placements automatically.

## Resolver

`GFVegetationSource.resolve()` returns typed `GFSourceResolution`: status READY / UNAVAILABLE / UNSUPPORTED / ERROR, diagnostics, provider `go_flora/builtin-v2`, resource paths, source/dependency content revision, capabilities, typed parts and optional PackedScene. `GFSourcePart` contains a stable scene node path, Mesh with effective materials, accumulated Transform3D and conservative AABB. Direct static Mesh retains its fast path and legacy `resolve_mesh()` API; multi-part clients use `parts`.

Static scenes are read from SceneState **without node instantiation**. Every eligible part is considered; hierarchy is capped at 256 nodes. Material priority is Material Override → non-null Surface Override → mesh surface material. Shallow owned Mesh copies contain changed material bindings; original arrays, normals/tangents/UVs, materials and textures are not edited. Transforms are multiplied at rendering time, including root/pivot and nonuniform scales; geometry is not rebaked. Inherited/nested scenes and unsupported properties fail closed with paths/reasons. Groups/signals/scripts/colliders prevent silent static flattening.

Godot imports and loads project resources normally. The resolver does not sandbox hostile Resource scripts or the engine importer; projects/assets must be trusted. It avoids running Node scripts merely for extraction/preview. Tool-script scenes remain blocked even when their fingerprint is approved. Paths used by the addon are project-local `res://`, without traversal.

## Scene fallback

Opt-in review requires `allow_scene_fallback=true` and `reviewed_scene_revision` equal to the exact scene/dependency revision displayed in diagnostics. Changed files/dependencies require new review. Allowlist: Node3D / MeshInstance3D / StaticBody3D / CollisionShape3D with reviewed non-tool scripts, internal connections/groups and supported properties. Skeleton/skin/blend shapes, animation, particles, lights, tool scripts, nested/inherited/placeholder scenes, per-instance shader parameters and unknown render flags are unsupported.

Editor: inert mesh preview only, no script execution or authored physics bodies. Runtime: one scene instance per logical record, keyed by record ID + reviewed revision. Rebuilds reuse matching nodes; erase/revision changes remove old nodes, additions instantiate new ones. Child ownership remains authored; cache roots are unowned/internal and do not pack. Script state is not serialized by GO_FLORA. Source replacement resets that state by lifecycle design.

`enabled`/record-hidden/distance change visual GeometryInstances only. Script processing and collision layers are not toggled. Invisible plants can still cost CPU/physics. Renderer-owned visibility/ranges are the supported visual policy, not a general behavior scheduler. Complex scripts creating/removing/reconfiguring geometry dynamically are not validated examples. The original example proves ready/process/signal/group behavior and a real collider, not every possible gameplay script.

## Diagnostic contract

`GFSourceResolution` also exposes non-persistent UI classification for Source Diagnostics. It does not replace `status`, does not alter source revision/fingerprinting, and is never saved in `GFVegetationSource`, records or scenes. `diagnostic_state` is one of `STANDARD`, `REVIEW_REQUIRED`, `REVISION_MISMATCH`, `REVIEWED_READY`, or `HARD_UNSUPPORTED`; `blocking_reason` is a typed category from the concrete resolver branch. The Editor uses these fields, never a substring from free-form diagnostics, to choose user guidance.

`REVIEW_REQUIRED` is emitted only after the inspected PackedScene has passed the existing fallback allowlist but lacks a current opt-in review. `REVISION_MISMATCH` takes priority when a non-empty saved review differs from the current computed revision. `REVIEWED_READY` is emitted only after the original `allow_scene_fallback` and exact-revision checks already succeeded. Unsupported node/property/render/mesh features, nested or inherited structures and `@tool` scripts are `HARD_UNSUPPORTED`; an unclassified scene failure remains fail-closed. This diagnostic classification is explanatory only: it cannot enable fallback, instantiate a scene in the editor preview, or weaken any resolver branch.

## Alpha cards

`GFAlphaCard` references project PNG/WebP Texture2D, single/crossed/radial mode, bounded 3–4 radial count, width/vertical height, splay ±30°, pixel region, inward gutter and threshold. Zero region means full image. Invalid bounds/dimensions/gutters/opaque images are rejected. Mesh/material are shared deterministic derived resources; no new random mesh per placement. No vertex colors are written. Width/height control aspect explicitly.

Mesh has 4 vertices/6 indices per card, normals/tangents/UVs and ground pivot Y=0. Godot clockwise front winding and top-left image UV orientation are tested. Owned StandardMaterial3D uses double-sided alpha-scissor, threshold 0.5, clamp and linear-with-mipmaps. It references the original texture. Import settings are not forced globally; user enables texture mipmap generation and supplies extruded gutters. GPU probes pin isolated fixture mipmaps only. Alpha-hash is unavailable because Stage 00 Compatibility evidence failed. No wind/LOD/blade modeler is included.

## Cache and presentation

Batch key includes layer/set/cell/source revision/part path/Mesh/effective materials/LOD placeholder 0. One record contributes to every part. Conservative bounds use transformed Mesh bounds. Set edits update existing GeometryInstances without regenerating records. Static distance is whole-cell culling; fallback distance is per authored geometry. 0 is unlimited and set B remains independent.

Resource/card/texture changes and Godot `resources_reimported` invalidate/reload caches. Genuine PNG and GLB reimports are tested in disposable editor projects; IDs/transforms remain fixed. Static topology edits still coalesce a full cell rebuild, with measured 1,000/5,000-record CPU timings. Large-forest/FPS optimization is not claimed.

## Evidence boundaries

Native headless, Editor API, actual GPU pixels and owner GUI are recorded separately. A frozen pre-Stage-02 scene saved from accepted main is compared with its original JSON (transform tolerance 1e-5). Schema is not relaxed to pass tests. Stage 01 tests are unchanged and run before/after. ZIP tests use disposable projects and compare scene/config/layout SHA. Clean export/new machines/other GPU hardware and full interactive GUI remain NOT_RUN.

Primary API references: [SceneState](https://docs.godotengine.org/en/stable/classes/class_scenestate.html), [BaseMaterial3D](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html), [MultiMesh](https://docs.godotengine.org/en/stable/classes/class_multimesh.html). API reading is source analysis; executed 4.7.2 probes are runtime evidence.
