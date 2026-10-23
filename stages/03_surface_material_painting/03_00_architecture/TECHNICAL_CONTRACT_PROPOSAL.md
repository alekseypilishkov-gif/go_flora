# Surface 03.00 — Technical contract proposal

**PROPOSED / NOT IMPLEMENTED / NOT ACCEPTED ADR.** Names, schema fields, limits и brush behavior требуют owner review. Текущие GFInstanceRecord, GFVegetationSet, GFBrush и Source Kind значения не меняются.

## 1. Candidate objects и зависимости

| Candidate | Persistent fields / обязанности | Чего не содержит |
| --- | --- | --- |
| SurfacePaintTarget3D, scene-owned Node3D | surface_id; explicit MeshInstance3D/collider NodePaths; slot=0; paint_data; original binding tuple; owned ShaderMaterial reference; binding schema | VegetationLayer3D, active set, instance records или file-writing brush |
| SurfacePaintData, embedded Resource | schema_version=1; surface_id; mapping kind/version; local origin/extent; geometry/collider fingerprints; channel IDs; fixed resolution; RGBA8 bytes; validated content revision; MaterialSet reference | RID, GPU slot, ImageTexture authority, transient preview или внешняя writable mask path |
| SurfaceMaterialSet, reusable external Resource | schema/version; stable set_id; four stable slot IDs; base_layer_id; four prepared layer descriptors; canonical path/UID/content identity | Индивидуальные masks, targets, brushes, scene IDs |
| SurfaceMaterialLayer, descriptor | stable layer_id; display name; albedo Texture2D; normal Texture2D; roughness Texture2D / documented scalar default; positive UV tiling; scalar strengths | Arbitrary ShaderMaterial program, texture generator, layer weights |
| SurfaceMaskTexture, Texture2D adapter | Сериализуемая ссылка на **тот же** SurfacePaintData; resource_local_to_scene=true; width/height/image interface | Экспортируемый private ImageTexture/RID. GPU cache строится из CPU data |
| SurfaceBrushSettings, editor state | radius_world_m; strength [0,1]; falloff [0,1]; spacing_ratio; operation; selected stable layer_id; stamp/pending budgets | Foliage density/yaw/scale/random source logic |
| SurfaceStrokeTransaction, nonpersistent RefCounted | scene/session key, exact target/data references, frozen revisions/transform, changed blocks and scratch preview, immutable before/after bytes on finish | Authoritative scene changes до commit; file I/O |
| SurfaceMaskDelta, nonpersistent RefCounted | surface/data identity, validated immutable rect before/after payloads, dirty rects and memory reservation | Raw references на mutable preview buffers |

Directed graph: target → data → reusable MaterialSet; target → owned material → mask Texture2D adapter → **same data**. data не ссылается обратно на material/target. Detaching may retain data for Undo; deleting target/binding cannot delete shared prepared textures/MaterialSet files.

Adapter suitability подтверждена [GPU probes](evidence/runs/gpu-04/summary.json), но whole scene graph alias preservation, inspector duplication и packed export ещё не tested. Stage 04 должен доказать, что сценовая сериализация сохраняет data единожды, обе references после load указывают на один authored object, а private GPU object не попал в serialized graph.

## 2. Target capability contract

Первый предлагаемый профиль: **GROUND_XZ_SINGLE_SURFACE_V1**.

- MeshInstance3D в непосредственно редактируемой сцене, один static triangle surface/material slot. Нет skin/blend shape/custom vertex displacement/LOD topology swaps, CSG/GridMap/MultiMesh/Terrain adapter.
- Mesh содержит finite positions, normals, UV0 и valid tangents для prepared tangent-space normal maps. UV0 — только detail coordinates: он может повторяться, weight mask от него не зависит. В MVP нет per-layer UV rotation/mirroring; обычный positive tiling.
- В local XZ каждый interior point поверхности имеет не более одного Y. Треугольники с degenerate XZ area, folds/overhangs, projected interior overlap, slope >60° к world up и ambiguous geometry rejected. Проверка full triangle projection нужна; sparse samples сами по себе недостаточны.
- Effective global transform и parent chain — finite translation + yaw + positive uniform scale, determinant >0, без shear/pitch/roll. Mapping математика шире, но support contract намеренно уже. Transform change во время stroke cancels; после изменения target повторно проверяется, маска остаётся в local space.
- Explicit StaticBody3D + ConcavePolygonShape3D; shape соответствует render triangles в общей локальной системе. Нельзя принимать approximate box/convex collider как доказательство совпадения грунта. Существующий collider не переписывается для “исправления”.
- Physics first hit должен принадлежать selected binding; render BVH refinement того же camera segment даёт consistent position. Предлагаемый tolerance: max(0.001 m, 0.00001×world target extent), зафиксирован в validator version. Геометрия вне tolerance блокируется. Порядок collision faces не переносится в render indices.
- Overlapping floors внутри target не поддерживаются. Перекрывающиеся selected/adjacent surfaces, walls, caves и occluders без надёжного collision не входят в guarantee. Невидимые/non-colliding occluders нельзя автоматически распознать только physics ray.
- Один target на stroke. Соседние meshes могут существовать независимо, но brush обрезается границей active target; seamless stitching/cross-target interpolation отсутствуют.
- Candidate limits: resolution 256² default, max 512²; 4 targets/scene; geometry validator cap 20,000 triangles/target с ускорением projected-overlap checks. Эти budgets — initial safeguards, не measured production limits. Большее значение — explicit unsupported diagnostic, без downsampling/remeshing.

Typed validation result: READY, NO_TARGET, MISSING_COLLISION, COLLIDER_MISMATCH, UNSUPPORTED_TRANSFORM, UNSUPPORTED_TOPOLOGY, PROJECTED_OVERLAP, UNSUPPORTED_MATERIAL_BINDING, STALE_GEOMETRY, INVALID_SCHEMA, MISSING_DEPENDENCY, IDENTITY_CONFLICT. Diagnostic объясняет repair; не удаляет data и не меняет original mesh.

## 3. Mapping, addressing и stable IDs

Для world hit h и global target transform T:

```text
p = inverse_affine(T) * h
u = (p.x - origin_x) / extent_x
v = (p.z - origin_z) / extent_z
texel_position = (u, v) * (resolution - 1)
GPU_sample_uv = (texel_position + 0.5) / resolution
```

Extent строго положительный, finite. Origin/extent фиксируются при attach и не пересчитываются из нового AABB молча. Outside [0,1]² → OUTSIDE, с заданным numerical epsilon для самого ребра; никаких fract/modulo. Texture repeat disabled. CPU bilinear sampling использует четыре соседних texels и ту же convention, shader не интерполирует texel edges по другой формуле.

World brush radius оценивается по world distance в соответствующей точке supported ground sheet. Для будущего affine profile горизонтальная projection метрика: dᵀBᵀBd; native non-uniform collision support потребует отдельного proof. Для неровной ground sheet stroke inclusion использует также восстановленную geometry height/world point; одна только плоская XZ distance не равна surface geodesic. MVP brush — world-space Euclidean radius, не обещанный geodesic brush.

Identity:

1. surface_id и layer_id — stable serialized values; display_name, row index, Node instance_id и RID не identity.
2. Binding key при редактировании: owning scene identity + surface_id. При runtime instancing добавляется scene instance scope/path; несколько runtime экземпляров одной сцены законно имеют одинаковый authored surface_id.
3. Saved path/UID разрешает asset location, но schema/content validation обязательна. Renaming resource не назначает channels заново.
4. Duplicate scene node может копировать surface_id: текущая проба это показывает. В одной edited scene collision блокирует editing; предложить явный **Fork Paint Data** с новым Surface ID, deep-copy bytes и Undo. Не перенумеровывать автоматически при каждом load.
5. Scene Save As — самостоятельная авторская копия scene-owned graph, scope меняется; reusable MaterialSet остаётся shared. Inherited/instanced scene editing в MVP запрещено, пока независимость данных не доказана.
6. Geometry/collider fingerprint привязывает mapping к positions/triangle topology/shape transforms и profile version. Mesh/UV/tangent reimport changes trigger revalidation. No silent reproject/resize/remap.
7. Изменение только texture pixels не переписывает weights/IDs. Изменение layer ID/channel layout — incompatible contract, painting blocks until explicit reviewed conversion.

## 4. Четыре веса и channel table

Фиксированная таблица `R→base layer ID; G/B/A→остальные три layer IDs` сохраняется в data и проверяется против MaterialSet. База определяется stable ID и channel 0. UI row order — отдельное непостоянное представление.

Каждый texel — 4 bytes, диапазон 0..255, сумма **255**. New mask initialized (255,0,0,0). CPU quantizer: clamp finite nonnegative → normalize → floor(255*w) → distribute remaining units по largest remainder, ties по fixed channel order. Поэтому сумма точна и переименование не меняет веса. Corrupt length/NaN input/schema не “чинятся” без команды пользователя.

Shader defensive fallback: max(weights,0), sum normalize; при sum<epsilon — base. Это fallback для numerical zero/нового пустого GPU значения, **не** разрешение заменить missing/corrupt saved data пустой картой.

MVP brush operations:

- Paint выбранного k: `w' = (1-a)*w + a*unit(k)`, a=strength×falloff(distance), затем deterministic quantizer.
- Replace — Paint с strength=1 в центре stroke; falloff регулирует границу.
- **Erase to Base**: `w' = (1-a)*w + a*unit(base)` независимо от selected row. UI явно сообщает возврат к Base. Selective removal с иной redistribution не входит в этот MVP.
- Stationary pointer даёт один initial stamp; без time-based airbrush. Resampling по world distance и freeze settings на gesture; одинаковая траектория с разной частотой MouseMotion должна давать одинаковые bytes.
- Пропуск/invalid hit разрывает path, следующий valid hit начинает отдельный segment того же stroke. Ни через hole, ни через другой target линия автоматически не достраивается.

Layer reorder/name/texture edit не переводит painted bytes между channels. Удаление/структурная замена layer layout в MVP disabled/diagnostic, без потери старых весов. Overlays и height blend later используют отдельный schema/space, не “пятый нормализуемый канал”.

## 5. Material ownership и runtime loading

Attach — explicit opt-in, одна native undo action. Сохраняются actual material_override, slot-0 surface override и target identity, включая null. Проверяется one-surface mesh; owned ShaderMaterial назначается только этому MeshInstance3D.material_override. Исходный Mesh.surface material/arrays и пользовательские Material/Texture Resources не меняются.

SurfaceMaskTexture adapter ссылается на canonical embedded data, private ImageTexture строится из validated bytes. На load/enter/reimport runtime binding восстанавливает disposable cache; engine editor API не является runtime dependency. Plugin disabled не должен делать ground невидимым: runtime Resource/binding code и ordinary ShaderMaterial продолжают работать без EditorPlugin.

Во время preview возможен отдельный scratch texture adapter на owned shader, но перед pack/save/scene switch обязательно восстановить committed adapter через _apply_changes/cancel. Не сериализовать scratch preview как committed map. Parent data Resource и committed facade refs остаются неизменными во время pending stroke.

Detach/restore:

- Если current override == owned material, восстановить original tuple; retain data для redo.
- Если пользователь уже поменял binding, вывести conflict и не затирать текущую ссылку. Explicit owner restore action может применять сохранённый original tuple через Undo.
- Target missing/reimported — сохранить original tuple и bytes, editing disabled; никаких операций над пропавшим source.
- Missing MaterialSet/textures — preserve weights/IDs, typed dependency diagnostic, editing disabled. Диагностический render fallback должен быть явно заметен; не объявлять weights сброшенными в base и не подменять canonical data.
- Общий MaterialSet меняет внешний вид всех его targets по обычной asset reference policy, но **никогда** не делает маски shared. В MVP set editing через native Inspector/подготовленный asset, без генератора текстур.

13-sampler separate texture contract — первоначальный renderer candidate. Actual lit Compatibility budget и color/normal-space parity являются Stage 04 blockers перед support claim; при провале требуется review уменьшенного 9-sampler prepared packed profile, а не silent loss of normal/roughness.

## 6. Brush transaction и история

State machine:

```text
IDLE → VALIDATING → PENDING_PREVIEW → RELEASING → COMMITTED → IDLE
                                  ↘ CANCELLED → IDLE
```

При begin фиксируются scene history ID/context Node, target/data object и stable identity, geometry/mapping/material layout revisions, transform, brush snapshot. Перед первым изменением каждого блока сохраняются original bytes. Рекомендуемый dirty block 64×64; repeated touches сохраняют before только один раз. After фиксируется на finish, payload не имеет alias на scratch arrays.

Commit preflight проверяет тот же scene/target/data, revisions, schema и бюджеты. Один get_undo_redo().create_action(..., MERGE_DISABLE, target_node), одна do и одна undo operation применяют все rects через одинаковый validation/emit_changed/GPU invalidation path. No-op не создаёт history entry. Не использовать global history для scene mask; не объединять разные strokes автоматически.

Cancel целиком discards preview и pending deltas при Esc, focus out, released outside viewport, opening native modal, mode/tool/target/brush change, scene switch/close, target deletion/move, external data change, reimport, plugin disable. Disconnect callbacks before applying committed changes, чтобы собственный emit_changed не вызывал рекурсивный cancel.

Пока queued stamps не обработаны, input controller хранит release state; Esc всё ещё отменяет весь gesture. Proposed bounded work: не более 65,536 texels CPU work per tick и 4096 resampled stamps/gesture; превышение cancels whole pending stroke с diagnostic. Эти числа требуют profiling, они не FPS guarantee.

Memory: max full delta 512²×4×2 = 2 MiB плюс metadata. Retained Surface delta byte payload budget 64 MiB, учитывается по lifetime delta Resource/RefCounted, включая redo. Reservation делается до commit, отказ не меняет authority. Сжатие deltas можно добавить после измерений; полный Scene/Foliage native history автоматически не очищается ради Surface.

## 7. Dirty state, save, recovery и cache

CPU data — источник правды; content hash и committed data revision меняются при do/undo/redo, cache generation проверяет ту же revision. Dirty flag нельзя сбрасывать после ImageTexture.update либо после одного Resource.emit_changed. Native scene history/context + explicit mark_scene_as_unsaved для graph attach/необычных authoring changes обеспечивают editor dirty state; setters явно emit_changed.

Предлагаемый save protocol:

1. _apply_changes cancels pending preview, проверяет committed data/bindings и возвращает owned shader на committed adapter. API hook synchronous, не запускает deferred mask writer.
2. Native Godot сохраняет один scene graph: data + mapping/channel metadata + owned material/facade/original binding refs. Prepared imported assets только referenced.
3. Только после успешного native save и validation нового scene snapshot допустимо обновить last-saved digest/UI. При failure data и undo остаются RAM dirty, последний хороший scene/backup сохраняется.
4. New process load проверяет type/schema/length/checksum/channel IDs/dependencies/target geometry, затем строит GPU из CPU. Future schema/read errors — preserve/read-only, не initialize fresh bytes.
5. Save As меняет scene scope, не пишет старую scene и shared masks. Close/discard follows native scene ownership; hook не имеет права подавить ошибку фиктивным Saved.
6. В disposable editor наблюдалось native backup-then-rename setting=true. В Stage 04 fault injection должен подтвердить old/new file recoverability и error visibility для native save. Power-loss/OS durability не обещается; нельзя считать rename probe доказательством fsync/transaction across files.

Для **не выбранных** external .res/PNG: сначала новый файл/immutable revision в той же директории, close writer, reload с disk-bypass, проверить bytes/schema/hash, затем publish canonical loaded ref; keep last good version и recoverable descriptor. CACHE_MODE_REUSE сам по себе не disk verification; CACHE_MODE_REPLACE может затереть несохранённые RAM edits. Two-file PNG+metadata не становится atomic от одного rename. Поэтому внешние mutable mask files не включены в Stage 04 default.

[Image](https://docs.godotengine.org/en/4.7/classes/class_image.html), [ResourceSaver](https://docs.godotengine.org/en/4.7/classes/class_resourcesaver.html), [ResourceLoader](https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html), [EditorPlugin](https://docs.godotengine.org/en/4.7/classes/class_editorplugin.html), [EditorUndoRedoManager](https://docs.godotengine.org/en/4.7/classes/class_editorundoredomanager.html), [Texture2D](https://docs.godotengine.org/en/4.7/classes/class_texture2d.html) — API references; actual executed scope указан в inventory.

## 8. Future read-only Surface→Foliage query

Предлагаемый versioned interface, **не код текущего этапа**:

```text
snapshot = acquire_weight_snapshot(scene_instance_scope, surface_id, expected_revision)
sample = snapshot.sample(world_position, optional_surface_hit, requested_layer_ids)

sample = {
  status: OK | NO_TARGET | OUTSIDE | AMBIGUOUS | STALE |
          MISSING_DATA | INVALID_SCHEMA | UNKNOWN_LAYER,
  surface_key, data_revision, mapping_revision, transform_revision,
  sampling_version: "bilinear-base-v1",
  weights_by_layer_id, world_normal, diagnostic
}
```

snapshot immutable и согласован на весь будущий placement stroke. Query проверяет profile/height/triangle membership, а не только XZ; caller задаёт identity, неоднозначность не решается “ближайшим именем”. Sample returns nonnegative normalized logical base-resolution weights по stable IDs, CPU bilinear с той же texel convention. Render mip/LOD может визуально усреднять иначе; логический placement sampling не берёт screenshot/GPU readback.

Query не возвращает mutable Image/Resource/byte-array reference. Missing/unknown не превращается в weight=0; caller выбирает явно fail-closed skip и показывает diagnostic. Painting/erasing Surface, reimport или изменение MaterialSet **не вызывают удаление, перенос, смену source или resampling существующих GFInstanceRecord**. Future foliage filters касаются только новых placements; результат записывается обычным existing placement flow.

Future Reconcile/Rescatter — отдельная explicit command с immutable query revision, preview/counts/locked-placement policy и Undo. Она требует своего approved task; ни этот contract, ни Stage 04 не разрешают её реализовать.
