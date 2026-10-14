# Competitive workflow matrix

Snapshot: 2026-10-14. **No competitor runtime tests were run**; all tested versions in this file refer to declared requirements, not local verification. Labels: **I** = implementation inspected in pinned source; **D** = primary documentation/author claim (including marketing); **P** = explicitly planned; **U** = unknown in inspected evidence. I is not a runtime PASS. A procedural update or scale brush is not automatically Reapply.

## Primary evidence and versions

| ID | Source and pin | Declared version/license | Local tested version |
| --- | --- | --- | --- |
| UE | [Epic Foliage Mode](https://dev.epicgames.com/documentation/unreal-engine/foliage-mode-in-unreal-engine), current 5.8 docs; [4.27 detailed tool behavior](https://dev.epicgames.com/documentation/en-us/unreal-engine/foliage-tool?application_version=4.27) | Proprietary UE ecosystem; behavior reference only | NOT_RUN |
| SG | [Spatial Gardener README](https://github.com/dreadpon/godot_spatial_gardener/blob/77b822f50ded7211f91c0f0588d7b7c8bedac5f6/README.md); 77b822f (2025-03-05) | D Godot ≥4.2; MIT code, separate demo credits | NOT_RUN |
| T3 | [Terrain3D instancer guide](https://github.com/TokisanGames/Terrain3D/blob/854a4575ef0f6db8f3e2c051d352181da75236a2/doc/docs/instancer.md); 854a457 (2026-10-07) | MIT code; [README](https://github.com/TokisanGames/Terrain3D/blob/854a4575ef0f6db8f3e2c051d352181da75236a2/README.md) version/build requirements vary by release; no local compatibility claim | NOT_RUN |
| PS | [ProtonScatter README](https://github.com/HungryProton/scatter/blob/7198cc00078ebde61307578137c3f35223c6e438/README.md); 7198cc0 (2026-09-27) | D Godot 4; MIT addon; bundled Textures.com images restricted separately | NOT_RUN |
| TB | [TerraBrush README](https://github.com/spimort/TerraBrush/blob/d538805f1c2278787641588d9de1fb227a150cba/README.md); d538805 (2026-10-14) | D Godot ≥4.5; now C++ GDExtension (from 0.14.0-alpha); MIT code | NOT_RUN |
| FF | [FoliageFlow source](https://github.com/GdevSarvesh/FoliageFlow/tree/7be55699ffc6f02af3d1cc1189a9745847e5fb86); 7be5569 (2026-09-04); [official listing](https://store.godotengine.org/asset/gdevsarvesh/foliageflow/) | D Godot 4.7 minimum/listing v1.0.0, marked unstable; MIT code | NOT_RUN |
| MM | [MultiMesh+ README](https://github.com/gtibo/multimesh-plus/blob/03f518bb2eedaa26a138400e7718ad83cfaf49a8/readme.md); 03f518b (2026-10-11) | D Godot 4, early development; MIT code; exact support floor U | NOT_RUN |

ProtonScatter's GitHub repository description identifies it as a mirror of **[canonical Codeberg upstream](https://codeberg.org/hungryproton/proton_scatter)**. Codeberg fetch failed in this audit; the inspected pin is the GitHub mirror and mirror↔canonical head parity is **UNVERIFIED**. FoliageFlow and MultiMesh+ have identifiable primary repos; no freshness/stability claim beyond the snapshot dates is inferred.

## Editing and asset workflow

| Feature | UE | SG | T3 | PS | TB | FF | MM |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Paint | D static/actor foliage | I stroke handlers | D terrain brush | D procedural areas/modifiers; brush U | D terrain foliage/objects | I raycast paint | I Paint mode |
| Erase | D selected types | I erase handler | D Ctrl remove | D exclusion areas; erase brush U | I foliage tool erase flag | I radius erase | I Shift erase |
| Select instances | D click/lasso | U individual gizmo semantics | U | D shapes/items; individual U | U | U | D active mesh groups; individual U |
| Reapply | D selected parameter mask | I transform reapply handler | U | D regenerate stack, distinct from brush Reapply | U | U | I scale/color edits; full Reapply U |
| Single placement | D Single tool | I single handler | U exact one-instance tool | D point creation; single-click U | U | U exactly one mode | U |
| Palette/weights | D selected mesh list; exact weighted semantics U | I plant list; weight semantics U | D mesh asset list | D ScatterItems; weight semantics U | D foliage/object layers | I one target MultiMesh; palette U | I active groups + rand_weighted(probability) |
| Surface independence | D landscapes/static meshes and filters | D arbitrary 3D surfaces | D Terrain3D-specific storage/target | D project to arbitrary colliders | D TerraBrush terrain | I collision raycasts | I collision-layer raycasts |
| Alpha cards | D masked mesh material | D imported mesh/scene; generator U | D generated texture card | D imported assets; card generator U | D foliage texture/mesh definitions | I chosen MultiMesh mesh; card generator U | I chosen mesh; card generator U |
| Asset interchange | D UE static meshes/Actor Foliage | I Mesh/PackedScene LOD source acceptance | D .tscn/.scn/.glb/.fbx extraction; first mesh and transforms caveat | I scene/instance render modes | D PackedScenes or octree MultiMesh objects | I target ordinary MultiMesh | I reusable MMPlusMesh resources |
| Undo/Redo | D editor workflow; not tested | I project tests/history integration referenced | U in inspected instancer excerpt | I undo_redo member; full stroke semantics U | D UndoRedo interface; I tool manager | I before/after buffers | I actions; D README known bugs |

## Rendering and persistence

| Feature | UE | SG | T3 | PS | TB | FF | MM |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Chunking | D cluster rendering | I octree MultiMeshes | I region→mesh/LOD→cell; D 32m cells | I use_chunks/chunk_dimensions | I foliage chunks / object octree | I one target MultiMesh; chunk system U | I grid/AABB groups |
| Cull distance | D start/end cluster range | I per-plant kill distance | D asset visibility ranges | U exposed distance control | D maximum foliage distance | U | I update_visibility_range |
| LOD | D cluster LOD; Nanite caveats | I LOD variants/max distance | D automatic and authored mesh LOD | U | D object LOD list; terrain clipmap is separate | U | U |
| Fade | D material PerInstanceFadeAmount; Nanite exceptions | U | D visibility range options; not tested | U | U renderer semantics | U | U |
| Persistence | D UE level assets | I restore_after_load octree | D Terrain3D regions | I optional cache/rebuild controls | D DataPath + layer textures | I transform data in target MultiMesh | D embedded/external .tres/.res buffers |
| Scenes with gameplay | D Actor Foliage, separate cost | U exact script/collider retention | D mesh extraction, no individual mesh collider; planned P collision via scene shapes | I individual render mode; detailed retention U | D scene vs MultiMesh object strategies | U automatic fallback | U automatic fallback |

## Implementation evidence paths

All repository source links below use the pins listed above; no code/assets copied into GO_FLORA.

- SG: [sh_reapply.gd](https://github.com/dreadpon/godot_spatial_gardener/blob/77b822f50ded7211f91c0f0588d7b7c8bedac5f6/addons/dreadpon.spatial_gardener/arborist/stroke_handler/sh_reapply.gd), [stroke handlers](https://github.com/dreadpon/godot_spatial_gardener/tree/77b822f50ded7211f91c0f0588d7b7c8bedac5f6/addons/dreadpon.spatial_gardener/arborist/stroke_handler), [greenhouse_plant.gd](https://github.com/dreadpon/godot_spatial_gardener/blob/77b822f50ded7211f91c0f0588d7b7c8bedac5f6/addons/dreadpon.spatial_gardener/greenhouse/greenhouse_plant.gd), [mmi_octree_node.gd](https://github.com/dreadpon/godot_spatial_gardener/blob/77b822f50ded7211f91c0f0588d7b7c8bedac5f6/addons/dreadpon.spatial_gardener/arborist/mmi_octree/mmi_octree_node.gd).
- T3: [terrain_3d_instancer.h](https://github.com/TokisanGames/Terrain3D/blob/854a4575ef0f6db8f3e2c051d352181da75236a2/src/terrain_3d_instancer.h) and linked instancer guide. Guide explicitly distinguishes no individual culling, first-mesh scene extraction, generated cards and future collision work.
- PS: [scatter.gd](https://github.com/HungryProton/scatter/blob/7198cc00078ebde61307578137c3f35223c6e438/addons/proton_scatter/src/scatter.gd) and README. Procedural shape/modifier workflow is useful for determinism/cache design; it is not evidence of an Unreal-style painter.
- TB: [foliage.h](https://github.com/spimort/TerraBrush/blob/d538805f1c2278787641588d9de1fb227a150cba/src/nodes/foliage.h), [foliage_tool.cpp](https://github.com/spimort/TerraBrush/blob/d538805f1c2278787641588d9de1fb227a150cba/src/editor_tools/foliage_tool.cpp), [tool_undo_redo.cpp](https://github.com/spimort/TerraBrush/blob/d538805f1c2278787641588d9de1fb227a150cba/src/misc/tool_undo_redo.cpp) and README. C++ rewrite means old C# tutorial assumptions are obsolete.
- FF: [plugin.gd](https://github.com/GdevSarvesh/FoliageFlow/blob/7be55699ffc6f02af3d1cc1189a9745847e5fb86/addons/FoliageFlow/plugin.gd), [FoliageFlow.gd](https://github.com/GdevSarvesh/FoliageFlow/blob/7be55699ffc6f02af3d1cc1189a9745847e5fb86/addons/FoliageFlow/FoliageFlow.gd): before/after transform snapshots, collision sampling, one assigned target.
- MM: [mm_plus_editor.gd](https://github.com/gtibo/multimesh-plus/blob/03f518bb2eedaa26a138400e7718ad83cfaf49a8/addons/mm_plus_editor/mm_plus_editor.gd), [mm_plus_3d.gd](https://github.com/gtibo/multimesh-plus/blob/03f518bb2eedaa26a138400e7718ad83cfaf49a8/addons/mm_plus_editor/nodes/mm_plus_3d.gd): weighted groups, grid editing, explicit visibility update and undoable buffers.

## Architecture implications

GO_FLORA should combine generic collision targeting and editor tools with authoritative logical records rather than only raw MultiMesh buffers. SG demonstrates an editor-first GDScript structure; T3 explicitly documents cell culling and scene-extraction limits; FF shows a compact paint/erase workflow; MM exposes weighted meshes and updates of existing visibility; PS illustrates separate procedural rules and cached output; TB illustrates the cost of terrain-coupled data and migration after a native rewrite. These are design observations, not endorsements or runtime/performance rankings.
