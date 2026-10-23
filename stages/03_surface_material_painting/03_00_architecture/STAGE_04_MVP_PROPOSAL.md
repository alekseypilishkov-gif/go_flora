# Stage 04 — bounded Surface Painter MVP proposal

**NOT AUTHORIZED / NOT STARTED.** Это review-ready предложение будущей задачи. Stage 03 исследование не санкционирует код, установку ZIP, merge или release.

## 1. Точный рекомендуемый scope

1. Surface mode рядом с существующим Foliage, без изменения Foliage schema 1 и его Source/Palette semantics.
2. Attach/detach поддержанного MeshInstance3D: GROUND_XZ_SINGLE_SURFACE_V1, одна static triangle material surface, single-valued XZ ground, slope ≤60°, matching static trimesh collision, UV0/normals/tangents; finite translation/yaw/positive uniform scale. Validator блокирует unsupported geometry/transform/import revision.
3. Один reusable MaterialSet из четырёх stable prepared albedo/normal/roughness layer descriptors, включая base R. Native Inspector asset workflow; никакой генерации материалов/текстур и обещания arbitrary ShaderMaterial conversion.
4. Per-target embedded RGBA8 CPU Resource + serialized mapping/channel table, отдельный owned ShaderMaterial и Texture2D facade с derived private GPU cache.
5. Paint, strength=1 Replace и явно названный Erase to Base. World radius/falloff, distance resampling, invalid-hit path breaks, one target/gesture.
6. Один полносценовый Undo/Redo на gesture с immutable dirty-block deltas; cancel целого pending stroke при всех context changes и save.
7. Native scene save/reopen, Save As, plugin disable/runtime load и recoverable failed-save behavior без записи исходных assets.
8. Compact dock: mode, target diagnostics, MaterialSet, четыре layers, Paint/Erase, radius/strength/falloff. Inspector/FileSystem/Output и native camera остаются доступны.
9. Budgets: 256² default / 512² max; до 4 targets/scene; 20,000 triangles/target validator cap; один active target; max 2 MiB full byte delta, retained Surface payload 64 MiB; bounded CPU queue. Числа provisional до owner review/profiling.
10. Windows Godot 4.7.2 первым квалифицируется на actual desktop Forward+/Mobile/Compatibility. Renderer support объявляется отдельно после lit fixtures и color-space approval, не на основании research debug probes.

## 2. Unsupported / excluded

Walls, near-vertical cliffs, caves/overhangs, multi-level or projected-overlap targets, negative/non-uniform scale, shear/pitch/roll, multiple material slots, CSG/GridMap/Terrain3D adapters, skinned/deforming meshes, inherited/instanced authoring, cross-target seamless strokes, UV-space painting, vertex-color writes, mask resize/remap, external mutable mask authoring, 8+ layers, independent snow/puddle overlays, height blend, texture packing/generation, Studio, runtime player painting, Surface→Foliage filters и Reconcile.

Соседние независимые targets допустимы в пределах лимита; автоматическое совпадение border weights/UV tiles не входит в support. Для неподдержанного случая — объяснение и сохранение data, без скрытого “best effort” paint.

## 3. Implementation decomposition и stop gates

| Пакет будущей работы | Зависимости / результат | Gate до следующего шага |
| --- | --- | --- |
| 04.A Data & serialization | Separate schemas, IDs, channel mapping, embedded CPU bytes, Texture2D facade; graph validation и fixtures в tests/ | Fresh-process graph round trip; shared MaterialSet / independent masks; duplicate conflict; no derived GPU bytes |
| 04.B Capability validator | Geometry/BVH/collider mapping, frozen bounds, transform/profile checks, typed diagnostics | Positive/negative topology fixtures, reimport mismatch, no resource mutation |
| 04.C Owned rendering | 4-layer shader, source texture coordinates, normal encoding, original binding snapshot/restore, runtime reconstruction | Lit slope and normals; all declared backends; full sampler budget; explicit color-space decision |
| 04.D Stroke core | Paint/Erase-to-Base, quantization, resampling, dirty-block transactions and budget preflight | Deterministic bytes, no preview authority changes, one-step Undo/Redo, no-op/cancel/stress |
| 04.E Editor integration | One mode dispatcher; Surface controller; compact dock; scene history and save hooks | Native Editor API lifecycle/save/error matrix; Foliage regressions unchanged |
| 04.F Qualification | Owner-approved single-project manual flow, isolated automated fixtures, package identity if separately requested | Interactive owner PASS for agreed cases; quality gates; scoped PR stays open until owner merge decision |

Не делать upfront shared BrushBase/GFStroke refactor. Если нужный ray helper всё же выносится, сначала characterization tests existing Foliage input/filters, затем backward-compatible wrapper и parity evidence. При blocker в 04.C остановиться на concrete renderer trade-off для review; не снимать normal/roughness или storage safety молча.

Будущий code/layout split: addon data/runtime bridge внутри addons/go_flora/, editor-only controllers внутри addons/go_flora/editor/, reusable runtime shader отдельно; tests/ для автоматических проверок; evidence и owner steps только в stages/04_.../. Выбор имени ветки/директории будущего этапа задаётся approved task, здесь не создаётся.

## 4. Главные regression risks

| Изменение | Возможная регрессия | Требуемая защита |
| --- | --- | --- |
| Input dispatcher | Два обработчика LMB, swallowed navigation, pending Foliage stroke | Characterization active/inactive modes, modifiers, RMB/MMB/wheel, focus/scene transitions |
| Shared modal lifecycle | Native picker остаётся за окном или surface paints under modal | Existing Source Creator/picker/Diagnostics flows + new mode transitions |
| Resource local ownership | Две surfaces делят editable bytes или duplicates расходятся по ID | Full serialized graph identity assertions, explicit Fork Undo, reopen двух scenes |
| Owned ShaderMaterial | Затёрт original override/shared mesh material | Snapshot null/non-null priority cases, conflict-safe detach and Undo |
| Dirty/save hooks | Preview попал в файл, Saved ошибочно при disk error | Save during pending, _apply_changes, fail-injection, fresh process compare |
| Reimport | Изменились mapping/layer channels или silently reset mask | Geometry fingerprint block; texture refresh без byte changes; missing deps retained |
| History/budgets | External/global history, wrong scene Undo, memory growth | Custom scene context, two tabs, reserve/release payload, redo pruning tests |
| Dock labels | Минимальная ширина/высота выталкивает FileSystem/Output | Outer ScrollContainer preserved; long names/status/counters/DPI manual QA |
| Runtime/export | Material требует EditorPlugin или editor-only API | Plugin disabled, packaged/exported project load and render proof |

Issue #18 / PR #19 отдельны. Stage 04 planning должен заново проверить актуальный main и состояние кандидата, но не включать его merge/rework в Surface task. Existing Source canonical bug не использовать как шаблон нового MaterialSet publishing.

## 5. Test requirements

### Автоматические isolated tests, не owner GUI

| Группа | Обязательные cases |
| --- | --- |
| Data | schema bounds, byte lengths/checksum, sum=255, all base, four channels, stable IDs despite names/order, future schema read-only, missing dependency сохранность |
| Geometry | flat; sloped 15/45/60°; threshold reject; yaw/translation/uniform scale; negative coords; parent transforms; invalid/negative/nonuniform/degenerate; duplicated projected triangles, stacked floors, hole; collider offset/wrong shape |
| Coordinates | CPU/GPU texel-center parity, boundaries/negative origins, brush world radius, detail UV tiling независим от mask dimensions, no mapping rewrite on mere move |
| Materials | distinct layers и asymmetric directional normal texture, flat/steep lit surfaces, roughness response, base fallback, zero/corrupt defensive path, four channel stable mapping; full light/shadow environment на каждом claimed backend |
| Render ownership | two meshes share source material; attaching one сохраняет другой; null/non-null material_override/slot override; detach/undo/redo; concurrent owner override conflict |
| Brush | sparse vs dense pointer events, stationary one-stamp, fast segment, path break/reentry, erase to base, Replace, overlapping stamps, rect snapshots immutable, no-op, budget exhaustion atomic cancel |
| History | one full stroke action, exact Undo/Redo bytes, new action after Undo, two scene tabs, scene close/history release, target deleted/reimported during queue, retained byte cap without clearing Foliage history |
| Cancel | Esc, focus loss, released outside viewport, Alt/Ctrl/navigation, mode/tool/target/brush changes, popup, data change, scene switch/close, plugin disable; no file/authority/history changes |
| Persistence | save/close/reopen in new process, native Save As, no pending preview saved, one canonical data graph, MaterialSet external path/UID content, runtime with editor plugin disabled |
| Failure/recovery | read-only destination, locked target file, unavailable dependency, malformed data, interrupted temp/write/replace paths, last-good scene/backup recovery; no fictional Saved state |
| Reimport | mesh/UV/topology revision blocks edits retaining masks; texture reimport changes render cache only; changed MaterialSet layout blocks without reassignment |
| Performance | 4×512² targets / 20k triangles bound, dense full-target stroke, upload throttling/cancel latency, retained Undo budget; report CPU/GPU hardware and measured frame time/RSS instead of assumed FPS |
| Regressions | Existing Stage 01/02/02.1/02.2/02.3, Issue #13/#16 applicable suites and baseline source contracts; if main includes accepted #18 at that time, run its suites too |
| Packaging/export | Exact addon manifest, no scratch dependencies, clean project imports, scene/runtime with exported dependency closure on explicitly qualified target |

9-sampler packed fallback, mobile hardware, other OS/Web — additional qualification, не автоматический support. Power-loss/fsync durability не заменять обычным save/reopen.

### Физическая owner acceptance

После отдельной implementation/installation authorization использовать согласованный owner project/scene. Новые постоянные manual scenes не создавать автоматически; существующий TEST_FLORA в исследовании не открывался и не менялся. В будущей задаче владелец подтверждает один согласованный шаг за раз.

1. Source palette/Diagnostics в Foliage доступны; camera orbit/pan/zoom, Inspector, FileSystem и Output работают.
2. Surface attach на approved ground явно показывает original binding/reversibility и неподдержанные target diagnostics.
3. Выбрать Grass/Dirt/Rock/Mud, провести видимый blended stroke; один Undo убирает весь мазок, один Redo возвращает.
4. Erase to Base/Replace соответствуют названиям. Во время мазка Esc/focus/mode/popup/scene switch не оставляют частичный результат.
5. Native Save/Save As/полное закрытие и повторное открытие сохраняют masks, MaterialSet refs и исходные assets; plugin disable/runtime ground остаётся корректным.
6. Отдельно подтвердить normal/roughness/color appearance на согласованных backends и stable dock при длинных labels.

До выполнения: **INTERACTIVE_GUI_QA: NOT_RUN / READY_FOR_MANUAL_QA**. Native/headless/GPU evidence этого статуса не меняет.

## 6. Acceptance criteria будущей реализации

- Все поддерживаемые target fixtures paint корректно; все unsupported fixtures дают actionable diagnostic до mutation.
- В data sum(weights)=255 для каждого texel; stable channel table не зависит от UI order/name.
- Целый gesture undoable одной action; cancel/no-op не меняют bytes/IDs/files/историю.
- Shared MaterialSet не делает masks shared. Исходные mesh/material/texture и старые Foliage scenes подтверждены hashes/round trips.
- Один authoritative mask Resource на target после save/reopen; ни transient draft, ни GPU image не выступают вторым editable source of truth.
- Native saves либо дают validated persisted state, либо оставляют доступный last-good file/backup и unsaved editable RAM state с ошибкой. Save during pending сохраняет только committed state.
- Owned material restores исходный binding и уважает последующие owner edits. Ground работает без EditorPlugin и в проверенном runtime/export.
- Полный lit shader работает в каждом объявленном renderer; color-space policy согласована, normal orientation доказана directional fixture. Необъявленные платформы честно NOT_RUN.
- Foliage modes, palette remove choices/Undo, Source Diagnostics, native picker lifecycle и draw distance без регрессии.
- Взаимоисключающие modes, compact dock и owner mouse/navigation/save acceptance пройдены отдельно от API.
- Working/staged/committed diff whitespace, repository validation, tests, evidence review и clean research/code branch status; scoped PR, без auto merge/release.

## 7. Что именно требуется утвердить до старта

Владелец принимает support profile и отказ от arbitrary mesh claims; четыре stable channels и Erase-to-Base behavior; embedded scene storage вместо external mutable masks с указанными limits; Texture2D bridge/owned override restoration; texture/normal/color contract и renderer qualification gates; identity/fork/save recovery rules; test/GUI scope и отдельную Stage 04 implementation issue/branch.

Если нужны сразу большие карты, external mask authoring или стены/пещеры, этот bounded MVP нужно пересмотреть **до** кода. До такого решения остаётся только текущий research Draft PR. Stage 04 здесь не начат.
