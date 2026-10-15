# GO_FLORA 0.2.0-dev

GDScript vegetation painter for Godot **4.7.2**, MIT. Stage 02 is **READY_FOR_MANUAL_QA**, **INTERACTIVE_GUI_QA: NOT_RUN**. Copy this directory to `res://addons/go_flora/`, then enable GO_FLORA in Project Settings → Plugins. No native dependency or Tree3D is required. The plugin-only ZIP contains no scenes, textures or models.

## Add your plants

1. Create/select a `VegetationLayer3D`. In its Layer Data → Sets, create a `GFVegetationSet`, assign a unique Set ID, then Refresh Layers / Sets in the dock.
2. Import your project-local GLB/GLTF with Godot first. Click **Add Mesh / GLB / Scene…**, select the Mesh or PackedScene, and **Save Source…** as a project `.tres`. It is added to the active palette with weight 1. Static hierarchies keep every mesh, surface material and accumulated transform. Mesh Transform adjusts the authored pivot.
3. For PNG/WebP, click **Create Alpha Plant…**. Choose the texture, single/crossed/radial mode, width, vertical height, optional ±30° splay, alpha threshold and atlas rectangle in **pixels from top left**. A zero rectangle uses the full image. Radial mode accepts 3 or 4 cards. Preview shows the chosen UV region; save the reusable `.tres`.
4. Click a dock source preview to edit its source in Inspector. Edit Set in Inspector changes weights or adds an existing source `.tres` to another palette. Stable source IDs are generated once; do not change them after painting.

Cards use ground pivot Y=0, owned mesh/material, double-sided **alpha-scissor**, linear filtering with mipmaps, clamp, default threshold 0.5. Texture originals are referenced and never rewritten. Set texture Import → Mipmaps → Generate when desired; supply extruded atlas gutters. UV Gutter is an inward pixel inset; 0.5 px avoids sampling the boundary, while stronger minification may require larger gutters (tested diagnostic atlas: 8 px at 3/12/24 m). A gutter cannot repair a tightly packed/poorly padded atlas. Width/height control aspect explicitly. Alpha-hash is not exposed: Compatibility has a historical failing pixel probe.

## Scenes with authored behavior

SceneState is inspected without instantiating nodes. Scripts, signals, groups and colliders are never silently flattened. A source can be saved for review even when blocked. **Source diagnostics / revision…** shows full selectable status/reasons/references and a **Copy revision** button. Inspect the scene **and all scripts**, then enable **Allow Scene Fallback** in Source Inspector and paste that exact revision into **Reviewed Scene Revision**. File/dependency changes invalidate the approval.

Supported fallback is deliberately narrow: Node3D / MeshInstance3D / StaticBody3D / CollisionShape3D, ordinary non-tool scripts and internal signals/groups. Runtime creates real scene instances with original processing/collisions, and reuses them across static cache rebuilds. It is more expensive than MultiMesh. Set visibility/distance changes only geometry; invisible plants keep gameplay processing/collisions. Deleting a placement destroys its scene; a source revision change replaces it. Script runtime state is not persisted independently of placement data.

**In the editor fallback is an inert mesh preview**: scripts do not execute and authored colliders are absent. Run the scene to inspect behavior. Animation, skeleton/skin, blend shapes, particles, lights, tool scripts, inherited/nested scenes, >256-node hierarchies, per-instance shader parameters and unreviewed render/node properties remain explicitly unsupported. Transform components are supported; combining `transform` with component aliases is rejected. Godot resource loading itself is trusted; this is not a sandbox for hostile project files.

## Paint and save

Choose layer/set, Paint/Erase/Single. LMB drag paints/erases; Single click adds one record. Release commits one scene undo step, Esc cancels pending preview. Navigate and RMB/MMB/Alt/Ctrl pass editor navigation through. Ordinary and tilted collision-backed surfaces are supported; visible geometry without collision is not itself a target. Mask, slope, height, normal alignment, seed, scale/yaw and weighted palettes use the existing deterministic painter.

**Draw distance (m)** remains directly below the active set. 0 = unlimited. It updates existing geometry of that set without moving/deleting records. Each static MultiMesh cell is culled as a whole; this is not per-instance culling. Fallback uses each authored GeometryInstance's range. Gameplay processing/collisions are independent of rendering distance.

Records/IDs/transforms remain authoritative schema 1. One record may render several parts. Save the scene normally; caches are internal/unowned and rebuilt on reopen. Reimport changes derived assets without regenerating placement positions. Missing resources and future/corrupt schema report diagnostics and retain records. Erase still works when a palette source is unavailable. Source/set IDs must stay unique. Stage 01 enum values 0/1/2 keep their original meanings; old unsupported values are not automatically promoted.

The dock keeps its accepted default Scene/Import slot and bounded 260×120 px minimum; saved custom arrangements are left to Godot. It does not write editor layout files. Work budget defaults to 2,000 samples/stamps (max 20,000); Erase also limits scanned records. Topology edits still rebuild static cells. Large-forest optimization, LOD and wind are outside Stage 02.

## Update safely

Save scenes and close Godot. Extract a verified plugin-only ZIP at the project root, or use the repository's optional `tools/install_stage02.py` with a selected project/archive. The script verifies CRC/SHA/path allowlist, moves the old addon to a timestamped `.scratch/go_flora_updates/.../previous/go_flora` backup and installs only the addon. It does not write scenes, project.godot or saved dock layout; on a fresh project enable the plugin yourself. Keep the ZIP's adjacent `.json` manifest for the script. No automatic update of the owner's TEST_FLORA is performed.
