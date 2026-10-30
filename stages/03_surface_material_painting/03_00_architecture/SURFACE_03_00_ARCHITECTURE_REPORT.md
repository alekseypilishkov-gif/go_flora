# Surface 03.00 — Architecture & Feasibility Report

23.10.2026. **READY_FOR_OWNER_ARCHITECTURE_REVIEW. Исследование; addon implementation не разрешена.**

## 1. Вывод для решения владельца

Ограниченный Surface Painter технически реализуем на Godot 4.7.2. Рекомендуется отдельный subsystem рядом с существующим Foliage: scene-owned CPU RGBA8 weights, один supported ground mesh на жест, reusable MaterialSet без индивидуальных масок, собственный ShaderMaterial и scene Undo/Redo. Начальный профиль — статическая однозначная heightfield-поверхность с одной material surface, совпадающим trimesh collider, UV0/нормалями/тангентами и положительным uniform scale; перемещение и yaw допускаются как кандидат поддержки.

Для первого MVP рекомендую **embedded Resource**, а не writable external PNG/.res. Это осознанное уточнение исходной гипотезы, требующее owner approval. Маска 512² — 1 MiB сырых данных и около 1.40 MB текста сцены; четыре таких targets — 4 MiB raw. Ограничение масштаба уменьшает риск расхождения сцены и внешних файлов. Сам по себе успех API-проб не доказывает готовность production save/cancel/UI, сложных склонов или всех GPU.

Отклонить на первом проходе: arbitrary topology, multi-floor/caves, multi-slot materials, blending чужих ShaderMaterials, независимые overlays, автоматическое удаление Foliage, shared universal brush refactor. Полный scope, budgets и критерии: [Stage 04 proposal](STAGE_04_MVP_PROPOSAL.md). Точный draft API: [contract](TECHNICAL_CONTRACT_PROPOSAL.md); сравнения: [matrix](DECISION_MATRIX.md).

## 2. Проверенная база и действующее направление

| Источник | Закреплённая идентичность / статус |
| --- | --- |
| Удалённый main, GitHub API | `d911087157ecaa9e3ab2b92d95049f2999aebab1`, 0.2.5-dev, PR #14/#17 уже merged |
| Research branch | `codex/stage-03-surface-00-research`, создана от этого main в отдельном managed worktree |
| Основной checkout владельца | `3d043d3ee48578501a2249c13db331b43aee9c37`, другая ветка и существующие untracked; не синхронизировался |
| Draft PR #20 | [product pivot](https://github.com/alekseypilishkov-gif/go_flora/pull/20), OPEN / DRAFT / NOT MERGED, head `6fefe29cad6fbfbb1437b21681a2d31bf576def3` |
| PR #19 / Issue #18 | [canonical Source candidate](https://github.com/alekseypilishkov-gif/go_flora/pull/19), OPEN / NOT MERGED, head `7093b07922999778d01b3afa49ebc4272cc10cde`, 0.2.6-dev, owner GUI NOT_RUN |
| Движок проб | `4.7.2.stable.official.ed1daf0bf`; SHA-256 `ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424` |
| GPU | Windows, NVIDIA RTX 5060 Ti; OpenGL 3.3 NVIDIA 616.56 / Vulkan 1.4.351 |

main проверен через connected GitHub API после DNS FAIL у локального git ls-remote. Исследовательский worktree совпал с API main; локальная ветка main владельца не обновлялась. [Снимок контекста](evidence/context.json), [защита checkout](evidence/owner_integrity.json), [исходный hash manifest](evidence/owner_before.json).

Прочитаны именно версии PR #20: [Product Direction](https://github.com/alekseypilishkov-gif/go_flora/blob/6fefe29cad6fbfbb1437b21681a2d31bf576def3/docs/PRODUCT_DIRECTION_20261023.md), [Roadmap](https://github.com/alekseypilishkov-gif/go_flora/blob/6fefe29cad6fbfbb1437b21681a2d31bf576def3/docs/ROADMAP.md), [Surface draft](https://github.com/alekseypilishkov-gif/go_flora/blob/6fefe29cad6fbfbb1437b21681a2d31bf576def3/docs/SURFACE_MATERIAL_PAINTING_DRAFT.md), а также main [ADR 0001](../../../docs/ARCHITECTURE_ADR_0001.md) и [Source contracts](../../../docs/STAGE_02_SOURCE_CONTRACTS.md). Старые Tree3D/Stage 03 формулировки в main/ADR остаются историей и не задают текущий scope. PR #20 не переносился в research branch, не изменялся и не сливался. Никакая отменённая генерация не исследовалась как задача реализации.

Binary checksum совпадает с уже закреплённым репозиторным Stage 00 environment; версия подтверждена новым запуском. Независимая загрузка/проверка официального release archive в этом исследовании NOT_RUN; self-reported official build не равен новой supply-chain аттестации.

## 3. Фактическая архитектура Foliage

**CONFIRMED / source inspection**, addon bytes закреплены [manifest](evidence/source_identity.json); runtime assertions Surface отдельно перечислены в [inventory](EVIDENCE_INVENTORY.md).

| Узел | Проверенный контракт и сцепление | Решение для Surface |
| --- | --- | --- |
| [plugin.gd](../../../addons/go_flora/editor/plugin.gd), L51–159, L949–1076 | Один EditorPlugin владеет dock, всегда включённым forwarding, Foliage tool enum, active layer/set, GFStroke и preview. Esc, outside release, focus out, scene changes отменяют pending. L120 следит за layer transform/data | Сохранить единый вход, добавить явный диспетчер mode ownership. Новая Surface session; существующие enum значения и Foliage маршруты не переписывать |
| [GFSurfaceTarget](../../../addons/go_flora/editor/surface_target.gd), L5–28 | Physics ray query использует GFBrush.collision_mask, GFBrush.accepts_hit и VegetationLayer3D.global_transform; исключает go_flora_owned и descendants layer. Результат — collider path, не mesh/material identity | API целиком не переиспользовать. Camera ray arithmetic и исключение owned previews можно вынести в маленький helper только при доказанном выигрыше и parity-тестах |
| [GFBrush](../../../addons/go_flora/data/brush.gd), L5–69 | Radius/spacing/filter fields смешаны с density, placement yaw/scale/seed; height может быть layer-relative. accepts_hit не проверяет соответствие render topology | Новый компактный SurfaceBrushSettings. Похожие поля не являются причиной наследовать Foliage Resource |
| [GFStroke](../../../addons/go_flora/core/stroke.gd), L30–176 | begin требует GFVegetationLayerData и GFVegetationSet. Resampling по world distance; random placement, source choice, erase queue и результат GFRecordDelta | Переиспользовать принцип distance resampling/break-path/bounded work, не сам класс. Маски требуют opacity, quantization, byte deltas и ownership другого типа |
| [GFPlacement](../../../addons/go_flora/core/placement.gd), L5–50 | SHA counter source selection, floor для отрицательных cells; inverse transform для positions, transpose для normals; создаёт GFInstanceRecord | Не использовать для weights. Только математические правила как проверяемые примеры; native Surface sampling независимо от vegetation RNG |
| [GFRecordDelta](../../../addons/go_flora/core/record_delta.gd) | Stable record IDs, added/removed arrays, исходные индексы, serial, emit_changed | Сохранить Foliage контракт. Новый immutable mask rect delta, одна native history action на весь gesture |
| [GFVegetationLayerData](../../../addons/go_flora/data/layer_data.gd) | Schema 1, records/sets/serial persistent; resource_local_to_scene=true; invalid/future schema disables edits | Не расширять для Surface. Separate schema, IDs, diagnostics и bytes |
| [VegetationLayer3D](../../../addons/go_flora/vegetation_layer_3d.gd), L53–127, L129–197 | Resource.changed bindings, signature, deferred coalesced rebuild; internal unowned caches; authoritative records не меняются preview | Принципы ownership/derived cache применимы. MultiMesh renderer, cache roots, placement slots к материалам не относятся |
| [Source Creator](../../../addons/go_flora/editor/source_creator.gd), L231–252 и plugin L852–862 | main сохраняет draft и затем публикует тот же объект. PR #19 fix ещё отсутствует | Не копировать этот flow. При любых новых внешних MaterialSet assets: validate → save → disk validate/reload → canonical bind; embedded masks вообще не имеют второго external edit identity |
| plugin L864–877 и [resolver](../../../addons/go_flora/sources/source_resolver.gd) | Reimport отменяет pending, CACHE_MODE_REPLACE обновляет источники, инвалидируются render caches | Для Surface отдельно: reimport geometry invalidates mapping; texture reimport refreshes owned rendering, не weights |

В plugin L1071–1074 create_action(... MERGE_DISABLE, layer) явно закрепляет scene context. Palette operations используют собственный set/context и сохраняют render-only references; рисование Surface не должно вызывать эти операции. Source Diagnostics имеет typed status/reason, а не анализ свободного текста; новый Surface validator должен следовать этому принципу, не вызывать vegetation resolver ради ground mesh.

## 4. Какие общие части оправданы

Немедленный общий BrushBase дал бы зависимости Resource schema, active set/layer, mode values и cancel semantics двум разным транзакциям. Польза в текущем MVP мала: одинаковы лишь ray setup, несколько lifecycle events и distance resampling. Риск — регрессии Foliage Erase queue, outside-release cancellation, selected-source mode и history routing.

Предлагаемая граница: один EditorPlugin владеет input dispatch и modal registry; Foliage controller остаётся прежним, Surface controller получает собственную session. Общий низкоуровневый ray helper возможен после отдельного characterization/parity теста, без изменения публичных GFBrush/GFStroke/GFSurfaceTarget сигнатур. В Stage 04 сначала допустимо несколько строк дублированной camera-ray математики. Полноценный framework не является зависимостью Surface MVP.

## 5. Targeting и координаты

Local XZ mapping однозначно адресует terrain-like sheet, но два треугольника на разных Y с одинаковыми XZ используют одни texels. Наличие collision не исправляет этот alias. Изолированная проба подтвердила alias и отсутствие UV в physics hit; mesh BVH дал свой face index/position, а сдвиг collider на 0.3 m был обнаружен сравнением позиций. Это plane probe, не валидация любой поверхности.

Поэтому target binding указывает конкретный MeshInstance3D и collider shape; проверяет static triangles, one surface, normals/UV0/tangents, invertible transform, geometry revision и отсутствие projected triangle overlaps (общие рёбра допустимы). Physics hit служит выбором/occlusion guard; тот же camera segment уточняется в локальном TriangleMesh BVH render mesh, расстояние до physics hit проверяется с tolerance. Collider face_index не считается render face_index: importer/physics может иначе упорядочить faces. При несовпадении — diagnostic и никакой записи.

Mapping: affine_inverse(world hit), затем сохранённые origin/extent → [0,1]²; отрицательные coordinates не оборачиваются через fract. World-radius brush проверяет длину преобразованного локального смещения. Математика произвольного nonsingular affine transform прошла probe; реальный physics under non-uniform scale НЕ проверен, а Godot [предупреждает об этом масштабе](https://docs.godotengine.org/en/4.7/classes/class_physicsbody3d.html). Начальный профиль его отвергает.

Точное сравнение mapping alternatives, seams, walls/caves/overlap и границы transformed targets находятся в [matrix](DECISION_MATRIX.md). В MVP один active target на stroke; cross-target stitching не обещается. Shape mismatch, missing collision, imported geometry revision change, unsupported parent transform — блокирующие причины, не повод незаметно пересоздать карту.

## 6. Материалы и шейдер

Dedicated opaque spatial ShaderMaterial смешивает ровно четыре prepared layer descriptors. Не смешивает готовые ShaderMaterial программы. Layer IDs/channel slots постоянны; display reorder меняет только UI.

- RGBA8 хранит четыре веса, включая base в R; CPU после quantization поддерживает sum(bytes)=255. Shader дополнительно нормализует и для zero sum использует base.
- Albedo uses source_color. Weight mask, normal и roughness — numerical data без source_color; normal textures должны соответствовать согласованному normal encoding. Detail coordinates идут через подготовленный UV0 и отдельный tiling; mask coordinates — local XZ. Изменение resolution маски не меняет размер детали.
- Нормали смешиваются как векторы в одном tangent frame, затем нормализуются, а не как готовые RGB цвета. Для RG/BC5 нужно восстановление Z. Нулевой вектор имеет flat fallback. Shader NORMAL_MAP использует tangent space; правильный green convention, tilted normals и lighting на slope обязательны в Stage 04.
- Roughness смешивается линейно как выбранная художественная модель. Это не физически точная смесь разных BRDF. Height-aware transitions — другое будущее правило.
- Один mask + 4×(albedo, normal, roughness) = **13 texture bindings и до 13 samples** в базовом fragment path, без подсчёта дополнительных engine/light samplers. Нет compute, framebuffer painting, normal_roughness screen texture или renderer-specific dependency.
- GPU-проба прошла все три desktop renderer на одной карте. Flat normal/roughness проверены через unshaded debug output относительно reference shader того же backend. Реальные освещённые PBR материалы, дальние mip/aliasing, shadow/light sampler pressure и frame budgets — NOT_TESTED.
- Probe обнаружил backend output difference: одинаковая red/green смесь ~0.502/0.498 в GL и ~0.737/0.733 в Vulkan. **Это не visual parity PASS.** Перед заявлением parity нужен явный color-space contract и golden captures на каждом backend.

Политика нормалей и sampler hints основана на [Spatial shaders](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html) и [Shading language](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/shading_language.html). [Renderer overview](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html) не подтверждает производительность конкретного материала. Packed albedo-alpha roughness уменьшает sampler count до 9, но требует подготовленных textures; automatic packing/texture generation не входит в GO_FLORA MVP.

Исходные Mesh/material/texture Resources не меняются. Для единственного слота owned ShaderMaterial назначается на конкретный MeshInstance3D.material_override; до opt-in сохраняются material_override и slot override, включая null. Restore сравнивает текущую ссылку с owned material; если владелец уже заменил binding, автоматическое восстановление не затирает его правку. Mesh.surface_set_material не используется. Attach/detach/restore — undoable scene actions.

## 7. Persistence, canonical identity и Undo

Пробы CONFIRMED:

1. PNG round trip сохранил все RGBA8 bytes, включая RGB при alpha=0. Это доказывает codec fidelity, но не editor/import/export pipeline.
2. ResourceSaver сохранил external Resource, оставив draft.resource_path пустым; loaded canonical — другой объект. CACHE_MODE_REUSE вернул RAM object, а не disk validation.
3. Повторный ResourceSaver.save(PackedScene) не записал изменённые bytes внешнего .res. Это **не полный тест физического Ctrl+S**: editor может дополнительно сохранять marked external resources. API-проба доказывает, что полагаться только на pack/save нельзя.
4. Embedded bytes пережили новый процесс; local-to-scene дал независимые объекты, но одинаковый serialized surface_id. Поэтому duplicate/instance identity требует scope и explicit fork, а не генерации новых IDs при каждом load.
5. Native Editor API со scene context выполнил undo/redo и save, вызвал _apply_changes, а новый процесс прочитал сохранённые bytes. Thumbnail на headless dummy renderer сначала дал FAIL; тот же API с реальным GL прошёл.
6. Texture2D facade сериализовал ссылку на CPU Resource; его private ImageTexture не попал в facade file. Reload заново построил GPU view на всех трёх backends; CPU fresh process прочитал данные без GPU.

Рекомендация — embedded SurfacePaintData, resource_local_to_scene=true, со stable surface ID и explicit channel table. Reusable MaterialSet — separate external read-only reference, local_to_scene=false, canonical path/UID + schema/content validation. Canonical bytes не читаются из ImageTexture.get_image. Texture2D facade хранит ссылку на те же данные, приватный GPU cache rebuildable; native material можно безопасно сериализовать без второй независимой маски. Полный target+material+facade+data graph round trip и deep-duplicate aliasing остаются implementation acceptance gates, а не уже пройденным integration test.

Один stroke хранит immutable before/after rects, snapshot IDs/revisions/target transform; preview отдельный. LMB release создаёт одну scene action. Undo/Redo меняет CPU bytes и через тот же путь refreshes GPU. Esc/focus/tool/scene/modal/transform/reimport cancel снимает preview, не пишет файлы и не добавляет action. Save while dragging через _apply_changes отменяет pending и сохраняет только committed bytes. Это предложенная политика; настоящего Surface input handler пока нет.

Safely recoverable save: использовать один scene graph и native scene save, не последовательную запись PNG+metadata. Наблюдалось safe_save_on_backup_then_rename=true в disposable editor settings; это не проверка power-loss durability. Перед выпуском MVP нужны fault-injection tests последнего хорошего scene file/backup, отказа записи, Save As и закрытия с несохранёнными изменениями. У _save_external_data() нет error return/veto; нельзя объявлять, что этот hook делает multi-file commit атомарным. Внешний .res с backup/reload/temp rename остаётся более сложной альтернативой, PNG — только будущий export/import.

## 8. UI и будущие правила Foliage

Dock сохраняет нынешний outer ScrollContainer (minimum 260×120) и доступ Inspector/FileSystem/Output. Сверху — mutually exclusive Foliage / Surface; внутри Surface — target/status, MaterialSet, четыре строки layers, Paint/Erase-to-Base, radius/strength/falloff. Материальные настройки подробного уровня — через Inspector. Постоянная большая Studio и перенос существующих docks не нужны.

Mode switching сначала отменяет active session и закрывает принадлежащие ей модальные окна. Один LMB обрабатывается ровно одним controller; Source Creator/picker/Diagnostics modal блокируют painting обоих режимов. Native Alt/Ctrl navigation, RMB/MMB, wheel и shortcuts передаются редактору после cancel pending. Existing Foliage Source palette, selected/mix, Erase, distance, retained sources и Diagnostics остаются доступны в Foliage и не переиспользуются как Material palette. Проверка мышью, размер dock при длинных названиях и реальное взаимодействие с native popups: **NOT_RUN**, будущий owner gate.

Foliage позже получает versioned read-only weight query с explicit target identity/height/revision, immutable snapshot и typed failures. UNKNOWN не превращается в нулевой вес. Surface strokes не знают о GFInstanceRecord и не удаляют существующие растения. Reconcile/Rescatter требует отдельной авторизации, preview и собственного Undo; контракт запроса — в [proposal](TECHNICAL_CONTRACT_PROPOSAL.md).

## 9. Остаточные риски и решение о Stage 04

| Риск | Чего доказательства пока не устанавливают | Обязательный gate |
| --- | --- | --- |
| Target capability validation | Нет production validator projected overlap/topology/collider equivalence | Reject fixtures + реальные approved meshes до включения painting |
| Normal/color/sampler behavior | Flat debug pass не доказывает lit slope или между-backend parity | Lit directional textures, flat/steep slopes, full lighting, declared backend fixtures |
| Durable native saving | Rename PASS не равен crash-safe transaction; full Surface scene graph ещё отсутствует | Failure injection, reopen, Save As, plugin disabled/runtime/export |
| Identity after duplicate/reimport | local_to_scene копирует bytes, но не делает IDs уникальными | Duplicate conflict, explicit Fork Undo, missing/corrupt/future schema сохранность |
| Interactive arbitration | Код Foliage читаем; Surface controller не существует | Owner mouse/navigation/modal/save matrix, regression suite |
| CPU/VRAM/undo costs | Нет sustained brush benchmark, actual VRAM или mobile hardware | 512²/4-target budget, retained delta cap, upload cadence, performance profile |

**Рекомендация: Stage 04 feasible, условно GO после принятия owner-ом** support profile, embedded storage/budgets, shader/material input contract, SurfaceBrush semantics, recovery/identity policy и независимой задачи реализации. Утверждение архитектуры не означает merge PR #19/#20, разрешение установки, release или начало Stage 04. Исследование здесь останавливается.
