# GO_FLORA Stage 01 addon

Experimental GDScript foliage painter for **Godot 4.7.2**, under MIT. Manual GUI acceptance is pending. Copy this directory into `res://addons/go_flora/` and enable **GO_FLORA** in Project Settings → Plugins. No native extension is required.

Version 0.1.1-dev wraps the entire dock in a scroll container so hidden/wrapped controls cannot push FileSystem and Output outside the editor window. A local ZIP contains `addons/go_flora/`; extract it into your project root with Godot closed, then reopen and enable the plugin. Do not create an extra nested `addons/go_flora/addons/` directory. No scenes or tests are included in the plugin-only ZIP.

Add a `VegetationLayer3D`, configure its `GFVegetationLayerData.sets`, and assign each set a unique ID and weighted `GFPaletteEntry` resources. Each `GFVegetationSource` needs a unique source ID and an existing **Mesh** in `asset`. `mesh_transform` adjusts its pivot; surface overrides must match the mesh's surface count. PackedScenes/GLB/generated kinds are diagnosed and never flattened.

The GO_FLORA dock selects layer/set and shows native mesh previews. Choose Paint, Erase or Single. Hold LMB for Paint/Erase, click once for Single, release to commit one undo action; Esc cancels pending changes. Navigate mode passes input through. RMB/MMB/Alt/Ctrl navigation cancels pending work and passes input to Godot. Refresh Layers/Sets after changing the scene hierarchy or palette. Edit Set in Inspector exposes distance and enabled state; **0 m is unlimited**, fade is off. Distance changes all existing cells of that set without changing records. A MultiMesh cell is culled as a whole; there is no independent member culling.

Brush controls use metres and density per m², distance-based spacing, seed, yaw/scale ranges, normal alignment, slope, world/layer height, collision mask and ray length. Include/exclude target buttons use the selected CollisionObject3D (or a mesh's collision parent). Visible meshes without collision cannot themselves receive paint; rays can still hit colliders behind them. No colliders are generated for vegetation instances.

Pending preview is a disposable render cache. Logical records are stored in layer data and saved with the authored scene; plugin disable removes editor controls/brush only. Runtime rendering uses the same data without EditorPlugin dependencies. Unsupported/newer schema is read-only; missing sources preserve records with diagnostics. Do not edit serialized records manually or reuse IDs for unrelated sources/sets.

Work budget defaults to 2,000 candidates and stamp steps (maximum 20,000). Erase also bounds inspected records; on larger layers raise the budget or use smaller operations. A brush already at its work limit stops adding/removing records and reports the limit. Pending and committed caches are rebuilt by cell grouping; optimization, LOD, wind, alpha-card generation and scene fallback belong to later stages.
