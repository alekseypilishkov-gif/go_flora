# Surface 03.00 — Decision matrix

Все cost/complexity оценки ниже — **INFERRED relative estimates**, не измеренные сроки разработки. L/M/H = low/medium/high. Runtime evidence указано отдельно; proposed support не выдаётся за PASS.

## 1. Mapping / topology

| Mapping | Сложность / development cost | Качество и performance | Data safety / reimport | Compatibility | Решение |
| --- | --- | --- | --- | --- | --- |
| Local planar XZ mask | L–M; validator overlaps/collider adds M | Независим от vertex density, 1 weight sample; на крутых гранях растяжение; height overlap неразличим | Стабилен при transform, если bounds/revision frozen; topology/bounds change must block | Обычный sampler2D, все три backend API tested на plane | **MVP candidate**: только однозначная ground sheet |
| UV-space texture paint | H: ray→render face→barycentric UV, islands/gutters, texel density | Поддерживает произвольные направления; seams и mirrored/overlapping UV размножают мазок; 1 mask sample | Reimport UV/index changes требуют explicit remap; texture asset должен принадлежать target | Native Image/Texture2D, но UV painting runtime NOT_RUN | Отложить в Mesh Paint; подходит для подготовленных уникально unwrap meshes |
| Vertex RGBA weights | M для простого ArrayMesh, H для imported/LOD/skinned | Нет mask texture, но качество зависит от tessellation; 4 weights/vertex interpolation; плотный mesh дороже | Нужна owned mesh copy/sidecar by stable topology; нельзя писать imported source colors. Reimport reorder ломает vertex identity | Godot mesh arrays/vertex color native; Surface runtime NOT_RUN | Не основной MVP: conflicts с user vertex colors/LOD, coarse ground |
| World planar XZ | L mapping; M multi-target orchestration | Соседние targets могут иметь continuous coordinates; translation mesh “скользит” по world texture; floors alias | Origin rebasing/moving targets меняет соответствие; единая writable atlas усиливает ownership coupling | Обычный shader; NOT_RUN | Возможный future shared grid, не индивидуальная MVP маска |
| Triplanar texture projection | M shader; H paint addressing | Помогает tiling на cliffs; **сам не решает ownership painted weights** и multi-level alias; до 3× detail fetches | Нужен отдельный mask address: UV, volume или multi-projection rules | Обычные shaders возможны; performance NOT_RUN | Future material-texturing mode, не замена mapping |
| 3D volume / per-face atlas | H–VH | Volume N³, sparse addressing/streaming; либо atlas seam work; способен различить caves | Версионирование storage/topology существенно сложнее | Texture3D/atlas platform budgets NOT_RUN | Не оправдан для ground MVP |
| Mesh BVH ray without physics | M acceleration cache | Уточняет render geometry и face index; **не mask mapping** | Должен пересоздаваться при geometry revision; original arrays read-only | TriangleMesh plane probe PASS | Использовать как refinement/validator alongside explicit collider |

Godot APIs: [TriangleMesh](https://docs.godotengine.org/en/4.7/classes/class_trianglemesh.html), [PhysicsDirectSpaceState3D](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectspacestate3d.html), [MeshDataTool](https://docs.godotengine.org/en/4.7/classes/class_meshdatatool.html). Physics face_index относится к concave collision shape, а не гарантированно к render triangle/UV.

| Сценарий | Local XZ | UV mask | Vertex colors | Bounded MVP |
| --- | --- | --- | --- | --- |
| Flat / slopes | Хорошо для single-valued local Y=f(X,Z); slope stretches projected area | Хорошо при адекватном unwrap | Градиент ограничен triangles | Flat и slopes ≤60° от world up; native slope painting ещё NOT_TESTED |
| Translation / yaw | Маска следует target; detail UV не меняется | Следует UV | Следует vertices | Candidate support; motion во время stroke cancels |
| Pitch / roll | Affine math возможна, меняется смысл ground/up | Mapping не зависит от orientation | То же | Reject в первом профиле, включая parent chain |
| Positive non-uniform scale | Mapping inverse/brush metric возможны; physics warning | Требуется correct metric/normals/collider behavior | Требуется normal transform | Reject; math PASS не physical acceptance |
| Zero / negative scale / shear | Degenerate или orientation/handedness risk | Та же проблема render/collision/TBN | То же | Reject, ничего не “bake/apply scale” автоматически |
| Negative coordinates | floor/clamp/origin дают корректный адрес; не fract | UV bounds/repeat policy | По geometry | Допускаются, math probe PASS |
| Collider отличается от mesh | Physics hit может красить неверную точку | Нельзя считать collider face render UV | Радиус может затронуть скрытые vertices | Reject после geometry/BVH agreement check |
| Adjacent mesh seam | Отдельные maps не гарантируют одинаковые edge weights/tiling | Gutters и islands требуют dilation | Shared border vertex duplication | One active target; no cross-target brush, no automatic seam welding |
| Overlapping geometry | XZ alias внутри target | UV может различить при unique layout | Может различить при separate vertices | Projected overlaps, overlapping floors и ambiguous targets reject |
| Walls / cliffs | Vertical triangles вырождаются в XZ; steep gradients | Возможно с правильным unwrap | Возможно с плотной topology | Walls/near-vertical cliffs unsupported |
| Caves / overhang / multilevel interior | Несколько Y на одном адресе | Возможны без UV overlaps | Возможны при topology ownership | Unsupported; не обещать на основании collision |
| UV islands / repeated UV0 | Не мешают mask XZ; detail seams принадлежат asset | Повторяют painted texels или создают edge artifacts | UV не влияет на addressing | UV0 используется только для detail textures, не для веса |

## 2. Storage / authority

| Вариант | Сложность / стоимость | Performance / size | Совместимость и data safety | Рекомендация |
| --- | --- | --- | --- | --- |
| Embedded CPU bytes Resource в scene | L–M, простая scene ownership и Undo | 512² = 1 MiB raw, ~1.40 MB .tscn; scene save растёт | Один authoritative scene graph; native pack/save + fresh process и Editor API PASS; backups/power loss ещё gate | **MVP default**, cap 512²/target и 4 targets/scene |
| External .res на target, CPU bytes | M–H: canonical bind + write/reload, scene/external history и recovery | Binary compression уменьшает disk size по entropy; measurements не переносим на любые карты | Одна .res может быть self-contained, но scene pointers + external file — уже 2 persistence domains; native rename PASS не multi-file atomic | Future scale-up после save coordinator/immutable revisions |
| PNG + metadata descriptor | H: import flags, per-file durability, UID/cache, ordering | Codec exact RGBA8 PASS; human-editable; importer can compress/change channels | PNG сам не хранит Surface ID/mapping/channel contract; unsaved editor texture не меняет PNG; direct Image file loading не export guarantee | Future explicit import/export; не default authoring |
| Resource с encoded PNG bytes | M: decode, compressed data authority, ROI operations требуют decode/re-encode | Меньше disk для compressible masks, CPU latency зависит от entropy | Один graph возможен; additional codec/error/canonical form concerns | Допустим later storage codec, performance NOT_RUN |
| Image Resource как authority | L для прототипа | Native get_data/get_region удобны; mutation notifications/nested dirty behavior надо контролировать | Image является Resource; serializer/API доступны, но persistent schema/IDs отдельно | Рабочий альтернативный payload, raw explicit bytes легче валидировать |
| ImageTexture / GPU readback как authority | Кажется L, реально H recovery | GPU readback stalls, process/device loss | ImageTexture.update не записывает источник; instance/RID не stable identity | **Reject**. Только derived rendering cache |
| SQLite/custom DB/engine native extension | H | Возможны большие данные, но новый persistence/runtime/dependency stack | Packaging, schema migrations, transaction/editor integration требуют отдельного этапа | Не оправдано bounded MVP |

Scene-embedded copy **не** является повторением Issue #18: для masks сознательно выбран единственный embedded authored object, external mask file отсутствует. Reusable MaterialSet остаётся external canonical asset. Нельзя иметь одновременно “каноническую PNG” и independently editable встроенную копию под тем же Surface ID.

## 3. Rendering / material strategy

| Стратегия | Сложность / development cost | Performance / GPU budget | Compatibility / safety | Выбор |
| --- | --- | --- | --- | --- |
| Dedicated opaque 4-layer ShaderMaterial | M + testing | 13 bindings с separate roughness; 1 mesh draw path, engine passes отдельно | Минимальный unshaded debug shader PASS трёх desktop renderer; lit/backend parity NOT_RUN | **MVP candidate**, explicit prepared texture descriptor |
| Packed roughness в albedo alpha | M artist input contract | 9 bindings вместо 13, меньше texture assets | Alpha roughness numerical; требует готовых packed textures. Packing generation не внедрять | Если lit Compatibility sampler budget не проходит — отдельное owner decision |
| Texture2D facade → CPU Resource | M; небольшой runtime Resource adapter | Private ImageTexture upload; может кэшироваться по committed revision | Save/reload/no GPU serialization + fresh-process CPU PASS; complete scene graph gate pending | **Candidate bridge** для owned material |
| Persistent ImageTexture snapshot плюс CPU bytes | L–M | Duplicate masks в scene/memory, rebuild/consistency checks | Два представления с одним authoritative source, но легче случайно редактировать derived копию | Reserve fallback только после отдельного review; не default |
| Material.next_pass / overlay draws | M–H | Повторная геометрия/overdraw; alpha/depth/order issues | Не нормализует автоматически произвольные PBR/ShaderMaterial | Future independent overlay, не Weight Blend MVP |
| Decals | M for look, H for editable persistence | Atlas/projection/overlap constraints | Не универсальный Compatibility baseline; не authoritative paint data | Не core architecture |
| Bake combined diffuse/normal textures | H | Меньше runtime samples ценой bake time/storage | Новый asset-generation/reimport pipeline | Out of active scope |
| GPU compute/render-to-mask | H | Быстрые stamps потенциально, readback и Undo complicate | Compatibility не имеет того же compute path; authoritative durable data остаются вопросом | Не MVP |

## 4. Оценки памяти и цены мазка

Это арифметические bounds, **не измеренный process RSS/VRAM**.

| RGBA8 tile | CPU base | CPU base + full preview | Full before+after delta | GPU base без mip |
| --- | --- | --- | --- | --- |
| 256² | 0.25 MiB | 0.50 MiB | 0.50 MiB | 0.25 MiB |
| 512² | 1 MiB | 2 MiB | 2 MiB | 1 MiB |
| 1024² | 4 MiB | 8 MiB | 8 MiB | 4 MiB |
| 2048² | 16 MiB | 32 MiB | 32 MiB | 16 MiB |

64×64 rect before+after = 32 KiB. Четыре 512² targets дают 4 MiB CPU authority, максимум ещё 1 MiB preview одного active target, до 2 MiB полного delta, до 4 MiB GPU base, плюс Image copies/uploads, GDScript Resource overhead и MaterialSet textures. Полный mip chain добавляет примерно 1/3 к GPU/base image payload; default MVP candidate без mask mip, поэтому дальний aliasing — explicit visual gate.

12 отдельных 2048² RGBA8 detail textures = 192 MiB base / ~256 MiB с mipmaps. Это может доминировать над масками. При BC7 albedo + BC5 normal + BC4 roughness арифметический пример ~40 MiB base / ~53.3 MiB с mip, но реальный importer/GPU format и фактическая residency НЕ измерены. Reusable textures не надо дублировать на каждый target.

32 full 512² stroke deltas = 64 MiB before/after bytes. Предлагается hard budget retained Surface payload 64 MiB и preflight reservation. При переполнении новый stroke отклоняется до commit; native общая Foliage/scene history не очищается автоматически. Точное управление lifetime delta objects и user recovery flow — Stage 04 acceptance, не реализованный limiter.
