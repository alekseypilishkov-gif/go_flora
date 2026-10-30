# GO_FLORA — выполненные задачи и полный пакет результатов

**Дата сводки:** 30 октября 2026 года.
**Период выполнения исходных задач:** 23 октября 2026 года.
**Охват:** выполненные задачи этого чата — Stage 03.00 Architecture & Feasibility Research, Git-доставка и загрузка результатов на Google Диск.

**Итог исходного этапа: READY_FOR_OWNER_ARCHITECTURE_REVIEW.** Исследование завершено; Surface Painter в addon не реализовывался. `INTERACTIVE_GUI_QA: NOT_RUN`. В этом чате разрешение на Stage 04 implementation, merge, installation или release не выдавалось.

В одном файле собраны сводка задач, выводы, Git-идентичность, результаты всех исторических запусков проб, ссылки на Google Диск, индекс evidence и **полные тексты всех семи исходных документов**. Исходный пакет закреплён коммитом `afeae8b50e581639f4d86b65340da78c9dcb3545`.

30.10.2026 повторно проверены статусы GitHub PR/CI и наличие файлов на Диске. Godot-пробы заново не запускались: их результаты относятся к сохранённому evidence от 23.10.2026. В приложениях сохранены исторические формулировки; актуальный снимок внешних статусов приведён отдельно.

## Содержание

- [1. Реестр выполненных задач](#tasks)
- [2. Исходные условия и границы](#scope)
- [3. Архитектурный результат](#architecture)
- [4. Проверки и доказательства](#checks)
- [5. Git-доставка и PR](#git)
- [6. Google Диск](#drive)
- [7. Что требуется утвердить](#decisions)
- [8. Команды всех исторических проб](#commands)
- [9. Полные тексты семи документов](#documents)
- [10. Индекс всех файлов исходного research-пакета](#inventory)

<a id="tasks"></a>

## 1. Реестр выполненных задач

| Задача | Дата | Выполненный результат | Статус |
| --- | --- | --- | --- |
| Архитектурный аудит GO_FLORA | 23.10.2026 | Проверены GFBrush, GFStroke, GFSurfaceTarget, VegetationLayer3D, editor input, UndoRedo, persistence, materials и Source Identity contracts | DONE — research only |
| Исследование Surface Painting | 23.10.2026 | Сравнены mapping, storage, shaders/rendering, ownership, UI и future Surface→Foliage API | DONE — предложения до review |
| Изолированные технические пробы | 23.10.2026 | 12 релевантных финальных process cases PASS; ранние шесть FAIL сохранены с причинами | DONE — не owner GUI |
| Документация | 23.10.2026 | Архитектурный отчёт, decision matrix, contract proposal, Stage 04 proposal, evidence inventory, README и delivery | DONE |
| Git-доставка | 23.10.2026 | Ветка от проверенного main, два коммита, push, Draft PR #21; три CI success | DONE — PR не merged |
| Загрузка на Google Диск | 23.10.2026 | Семь Markdown-файлов и ZIP полного пакета в проектной папке; readback восьми файлов | DONE |
| Единый Markdown по выполненным задачам | 30.10.2026 | Настоящая сводка с полными текстами, актуальными ссылками и индексом исходных результатов | DONE |

<a id="scope"></a>

## 2. Исходные условия и границы

Исходная задача: **Stage 03 — Surface Material Painting; substage 03.00 — Architecture & Feasibility Research; AUTHORIZED_FOR_RESEARCH; IMPLEMENTATION NOT AUTHORIZED**.

- Репозиторий: [alekseypilishkov-gif/go_flora](https://github.com/alekseypilishkov-gif/go_flora).
- Основная задача: [Issue #10](https://github.com/alekseypilishkov-gif/go_flora/issues/10).
- Текущее направление из [Draft PR #20](https://github.com/alekseypilishkov-gif/go_flora/pull/20) принято как product direction; технические классы и contracts остаются proposal.
- Исследовалась terrain-independent архитектура на Godot 4.7.2: supported ground mesh, reusable prepared material layers, blended weight painting, erase/replace, save/reopen и Undo/Redo полного мазка.
- Foliage/Object Painter сохраняется; Surface Painting — следующая основная система; Surface→Foliage и Mesh Paint отложены.
- Tree Generator/Tree3D provider, texture generation, atlas baking и полный PBR asset pipeline исключены из активного scope.

Работа выполнена в isolated worktree. Основной checkout владельца не синхронизировался; existing untracked-файлы не удалялись. TEST_FLORA, его сцена и worktree PR #19 не модифицировались. Пробы запускались в disposable `.scratch` без постоянных manual QA scenes.

| Идентичность | Значение |
| --- | --- |
| Проверенный main исследования | `d911087157ecaa9e3ab2b92d95049f2999aebab1` |
| Research branch | `codex/stage-03-surface-00-research` |
| Worktree | `C:\Users\pial\.codex\worktrees\surface-03-00-research\GO_FLORA` |
| Main addon | `0.2.5-dev` |
| Отдельный Source Identity candidate PR #19 | `0.2.6-dev`; не установлен в рамках этого чата |
| Движок проб | `4.7.2.stable.official.ed1daf0bf` |
| SHA-256 Godot binary | `ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424` |
| GPU | NVIDIA GeForce RTX 5060 Ti |
| Graphics API | OpenGL 3.3 NVIDIA 616.56 / Vulkan 1.4.351 |
| Исторический addon identity gate | 57 файлов совпали с pinned main по Git-normalized identity |
| Исторический primary checkout integrity gate | 2478 файлов, HEAD и status совпали до/после исследования |
| Новая проверка официального release archive | NOT_RUN; локальный binary hash и self-reported version проверены |

2478 файлов — результат исходного integrity-аудита 23.10.2026. Повторный hash-аудит этого checkout не объявляется выполненным 30.10.2026. ZIP на Google Диске — архив research-документации/evidence, не plugin installation ZIP.

<a id="architecture"></a>

## 3. Архитектурный результат

### Подтверждённые выводы

- `GFSurfaceTarget` зависит от `GFBrush` и `VegetationLayer3D`; `GFStroke` ориентирован на foliage records. Готовым независимым Surface API эти классы не являются.
- Для Surface нужны отдельные persistent data, target identity, material ownership и byte-transaction boundaries. Shared BrushBase/framework дал бы небольшой выигрыш при риске регрессий Foliage.
- Collision hit сам по себе не подтверждает корректность material addressing. Local XZ alias-ит stacked floors/overhangs; physics hit не предоставляет render UV.
- `ImageTexture.update()` меняет GPU, но не сохраняет source PNG. CACHE_MODE_REUSE может вернуть RAM resource вместо проверенного дискового состояния.
- ResourceSaver может оставить draft без canonical path; публикация draft вместо validated persisted resource воспроизводит класс риска Issue #18.
- Embedded CPU Resource прошёл save/reopen в новом процессе. Scene UndoRedo context, native save hook и точные bytes проверены отдельной Editor API-пробой.
- Texture2D facade может сериализовать ссылку на CPU Resource, оставляя private ImageTexture пересоздаваемым cache.
- Минимальный debug shader работал в трёх desktop renderer. Наблюдалось различие color output GL/Vulkan; lit PBR parity не доказана.

### Рекомендуемая архитектура — proposal

| Область | Рекомендация |
| --- | --- |
| Subsystem | Surface рядом с Foliage, отдельные data/controller; GFInstanceRecord/GFVegetationSet schema 1 не менять |
| Target | Static ground-like single-valued XZ sheet, один mesh surface/material slot, matching static trimesh collider |
| Mapping | Local XZ, explicit frozen origin/extent, geometry revision и physics/render BVH agreement |
| Transform profile | Candidate translation/yaw/positive uniform scale; reject non-uniform/negative scale, shear, pitch/roll |
| Weights | Четыре stable normalized RGBA8-канала, включая base в R; CPU sum(bytes)=255 |
| Authority | Scene-embedded SurfacePaintData — единственный authored source of weights |
| MaterialSet | Reusable prepared external resource; индивидуальные masks не разделяются targets |
| Rendering | Owned opaque ShaderMaterial, serialized Texture2D facade и private GPU cache |
| Brush | Paint, strength=1 Replace, Erase to Base; world radius/falloff/distance resampling |
| Transactions | Immutable before/after dirty rects, одна scene Undo/Redo action на gesture, отдельный preview |
| UI | Exclusive Foliage/Surface modes, compact dock, доступ native navigation/Inspector/FileSystem/Output |
| Future integration | Immutable read-only weight query для новых placements; существующие records не удаляются |

Предложены guards: default 256² / max 512² mask, до четырёх targets/scene, один active target/gesture, validator cap 20,000 triangles, retained Surface delta payload 64 MiB. Это проектные ограничения до review/profiling.

Цена embedded storage: 512² — 1 MiB raw weights и примерно 1.40 MB текста .tscn. Separate albedo/normal/roughness для четырёх layers + mask дают 13 bindings; prepared packed roughness profile может снизить их до 9.

В bounded MVP не включены walls, caves, overhangs, stacked/projected-overlap surfaces, multiple slots, arbitrary ShaderMaterials, UV/vertex paint, external mutable masks, overlays, height blend и cross-target seamless painting.

<a id="checks"></a>

## 4. Проверки и доказательства

| Релевантный финальный attempt | Scope | Process cases | Результат |
| --- | --- | --- | --- |
| cpu-02 | Native headless version/import/storage/fresh reopen/mapping | 5 | PASS |
| editor-02 | Native Editor API с real GL renderer и fresh reopen | 3 | PASS |
| gpu-04 | Compatibility/Mobile/Forward+ debug fixture + fresh-process facade | 4 | PASS |
| **Всего** | | **12** | **PASS** |

Весь исторический набор: **25 process cases — 19 PASS / 6 FAIL**. Первый static repository FAIL учитывается отдельно от 25 Godot process cases.

### Ранние FAIL и исправления

| Attempt | FAIL cases | Причина и решение |
| --- | --- | --- |
| cpu-01 | storage | Scratch UndoRedo Object не освобождён при shutdown; clear_history/free в harness, cpu-02 PASS |
| gpu-01 | forward_plus | Ошибки создания длинных shader-cache paths при shutdown; scratch disk shader/pipeline cache выключен, gpu-02 PASS |
| editor-01 | editor_api | Thumbnail texture на headless dummy renderer; real graphical GL Editor API, editor-02 PASS |
| gpu-03 | gl_compatibility / mobile / forward_plus | Неверный harness assertion об отсутствии всех ImageTexture во всём material; выделенная facade-only проверка, gpu-04 PASS |
| initial repository gate | Отдельный static FAIL | quality.json ещё не создан, ссылки уже существовали; сохранён FAIL, после формирования evidence повтор PASS |

Ошибки исправлялись только в disposable harness/configuration. Production addon не менялся. Exit code 0 сам по себе не означал PASS — учитывались semantic markers и shutdown ERROR.

### Что подтвердили native probes

- Lossless PNG round trip всех RGBA8 bytes, включая RGB при alpha=0.
- Draft/canonical Resource divergence; REUSE не является disk validation.
- Narrow PackedScene ResourceSaver.save не flushes изменённый external .res.
- Embedded bytes exact после fresh-process load; local-to-scene isolates objects, но сохраняет одинаковый authored surface_id.
- Whole-byte Undo/Redo и scene-context EditorUndoRedoManager.
- Native save вызывает _apply_changes; новый процесс читает сохранённые bytes.
- Affine inverse/brush metric/negative coordinates math; plane BVH/physics hit и detectable collider offset.
- Четыре shader channels, normalization/base fallback, flat normal и roughness debug values.
- GPU update не пишет source PNG.
- Facade сериализует CPU data без private GPU ImageTexture; reload восстанавливает GPU view.
- Simple instance override сохраняет shared source material; null restore работает.
- Ordinary same-directory replace и bypass reload работают; power-loss atomicity не доказана.

### Quality и границы доказательств

Исходная доставка прошла working/staged/committed whitespace, repository validation, scope и checksum gates; после push research worktree был clean.

`INTERACTIVE_GUI_QA: NOT_RUN / READY_FOR_MANUAL_QA`. Физическая owner приёмка мышью/навигацией/save не выполнялась. Surface addon/UI не реализованы.

NOT_RUN / NOT_TESTED: full lit PBR slopes/parity, actual mobile/low-end hardware, FPS/RSS/VRAM, full topology validator, complete target/material graph duplicate/fork, failed-save injection/power loss, Surface input/cancel UI, runtime/export qualification и Stage 04 implementation.

<a id="git"></a>

## 5. Git-доставка и PR

Research branch: `codex/stage-03-surface-00-research`. Target PR: `main`.

| Исходный commit | Назначение |
| --- | --- |
| `c8089db947f36aaae37d64a18ed7feceea64de7b` | Архитектурный research package Stage 03.00 |
| `afeae8b50e581639f4d86b65340da78c9dcb3545` | Post-commit quality/integrity evidence; закреплённый research snapshot |

Исходный PR содержал 112 файлов и 4573 additions только в Stage 03.00 documentation/evidence. Production addon, прежние tests/docs/stages не менялись. Настоящая сводка составлена позже и не входит в исходный архив afeae8b. Её последующее добавление в ту же ветку не меняет identity исходного research snapshot.

| PR | Статус на 30.10.2026 перед добавлением сводки | Research/context head |
| --- | --- | --- |
| [#21](https://github.com/alekseypilishkov-gif/go_flora/pull/21) | OPEN / DRAFT / NOT MERGED | `afeae8b50e581639f4d86b65340da78c9dcb3545` |
| [#19](https://github.com/alekseypilishkov-gif/go_flora/pull/19) | OPEN / NOT MERGED | `7093b07922999778d01b3afa49ebc4272cc10cde` |
| [#20](https://github.com/alekseypilishkov-gif/go_flora/pull/20) | OPEN / DRAFT / NOT MERGED | `6fefe29cad6fbfbb1437b21681a2d31bf576def3` |

PR #19 — отдельная Source Identity работа, а не реализация этого чата. PR #20 — product direction documentation. Они не изменялись и не сливались в рамках исследования.

### CI на исходном research SHA afeae8b

| Workflow | Статус | Ссылка |
| --- | --- | --- |
| Stage 01 Godot automatic checks | completed / success | [39936384677](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/39936384677) |
| Repository static checks | completed / success | [39936384723](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/39936384723) |
| Stage 02 imported assets automatic checks | completed / success | [39936384806](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/39936384806) |

Все три workflow — completed/success по API readback 30.10.2026. Эти результаты относятся к исходному research SHA, не к новым будущим коммитам и не к Surface implementation.

<a id="drive"></a>

## 6. Google Диск

Проект: [_go_flora](https://drive.google.com/drive/folders/1MAQk0EH3tQQcSU0VGk2_hwu3cZrUSM-P).

Результаты: [Stage 03.00 — Surface Material Painting — аудит 2026-10-23](https://drive.google.com/drive/folders/1DCUbacHArlKAwHQBSHRN9PEI_TzCgEHm).

23.10.2026 загружены семь Markdown-файлов и ZIP полного research/evidence package. Native Google Docs conversion **не выполнялась**. Первоначальный план конвертации заменён сохранением исходных Markdown из-за отсутствия локального renderer для проверки fidelity.

30.10.2026 folder readback снова подтвердил восемь файлов, названия, MIME и размеры. Размеры семи MD совпадают с локальными оригиналами. API не вернул remote checksums; cryptographic equality скачанных с Диска bytes не заявляется.

| Файл | MIME | Bytes | Google Диск |
| --- | --- | --- | --- |
| README.md | text/markdown | 2409 | [Открыть](https://drive.google.com/file/d/1vkCNBO4uRwgFaDCjrR4OyyrumPBwkeku/view?usp=drivesdk) |
| SURFACE_03_00_ARCHITECTURE_REPORT.md | text/markdown | 26338 | [Открыть](https://drive.google.com/file/d/1NGCdkzx0SWz6nn4e5oxR3u9NRWX-QBPL/view?usp=drivesdk) |
| DECISION_MATRIX.md | text/markdown | 14568 | [Открыть](https://drive.google.com/file/d/1prXJ8gGlxBJmxZrchS9UgW7yjwGxo9pn/view?usp=drivesdk) |
| TECHNICAL_CONTRACT_PROPOSAL.md | text/markdown | 23435 | [Открыть](https://drive.google.com/file/d/1WgyGHWJ411KIyxnxW54E7Ku_-5lE_P7R/view?usp=drivesdk) |
| STAGE_04_MVP_PROPOSAL.md | text/markdown | 15689 | [Открыть](https://drive.google.com/file/d/1dCgvkzzo2CudlGIrwX5O-5c8OcYD-xJE/view?usp=drivesdk) |
| EVIDENCE_INVENTORY.md | text/markdown | 17881 | [Открыть](https://drive.google.com/file/d/1W4kb0Th_jWPT3KiQ5scxRqYxOekqQ1mH/view?usp=drivesdk) |
| DELIVERY.md | text/markdown | 3339 | [Открыть](https://drive.google.com/file/d/10pBtpNASemgOfId8x0Jr7uAYBMt3VAbW/view?usp=drivesdk) |
| GO_FLORA_Surface_03_00_Audit_afeae8b.zip | application/zip | 220483 | [Открыть](https://drive.google.com/file/d/1YTch19KZapSAiGjeCR2_qJWAzHnt00kW/view?usp=drivesdk) |

Архив `GO_FLORA_Surface_03_00_Audit_afeae8b.zip` — **220483 bytes**. SHA-256 локального источника:

```text
fe65669faa3dbb24ee33c6bbfae9f3d37415944f937ebd0ff710a913b94e0603
```

Local archive hash повторно проверен 30.10.2026. В ZIP 129 entries, включая directories; содержательных research files — 112. Архив создан из pinned Git snapshot. Новая сводка в прежний ZIP не добавлялась; файлы на Диске при её составлении не менялись.

<a id="decisions"></a>

## 7. Что требуется утвердить

**Stage 04 feasible в ограниченном scope после отдельного owner approval.** Готовность архитектурного пакета не является разрешением implementation.

До старта нужны решения владельца по:

1. Supported ground profile и unsupported scenarios.
2. Четырём stable channels, base fallback, Paint/Replace/Erase-to-Base.
3. Embedded CPU storage, limits/Undo budget и Texture2D bridge.
4. Prepared material inputs, normal encoding, color-space policy и renderer qualification.
5. Collider/geometry validation, identity/fork/reimport и original binding restoration.
6. Save/error/recovery, full graph serialization и export.
7. Compact UI/input arbitration, regressions и отдельной owner GUI acceptance.
8. Независимой implementation issue/branch и точному authorization scope.

Surface painting не должно автоматически удалять, переносить или пересоздавать Foliage records. Future read-only query применяется к новым placements. Reconcile/Rescatter требует explicit action, preview, Undo и отдельной авторизации.

**Точка остановки:** review владельца. Merge, release, installation, user-resource migration и Stage 04 addon implementation в этом чате не выполнялись.

<a id="commands"></a>

## 8. Команды всех исторических проб

Точные argv из сохранённых summary.json. Запуски относятся к 23.10.2026; приведённые команды не выполнялись заново при создании сводки. Для повторения сначала нужно восстановить disposable harness и использовать проверенный engine.

| Attempt / case | Статус | Exit | Seconds | Log |
| --- | --- | --- | --- | --- |
| cpu-01 / version | PASS | 0 | 1.548 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/version.log) |
| cpu-01 / import | PASS | 0 | 2.765 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/import.log) |
| cpu-01 / storage | FAIL | 0 | 0.777 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/storage.log) |
| cpu-01 / mapping | PASS | 0 | 0.299 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/mapping.log) |
| cpu-02 / version | PASS | 0 | 0.078 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/version.log) |
| cpu-02 / import | PASS | 0 | 2.769 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/import.log) |
| cpu-02 / storage | PASS | 0 | 0.758 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/storage.log) |
| cpu-02 / fresh_reopen | PASS | 0 | 0.208 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/fresh_reopen.log) |
| cpu-02 / mapping | PASS | 0 | 0.303 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/mapping.log) |
| editor-01 / editor_import | PASS | 0 | 2.786 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-01/editor_import.log) |
| editor-01 / editor_api | FAIL | 0 | 2.5 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-01/editor_api.log) |
| editor-02 / editor_import | PASS | 0 | 2.585 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-02/editor_import.log) |
| editor-02 / editor_api | PASS | 0 | 3.825 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-02/editor_api.log) |
| editor-02 / editor_fresh_reopen | PASS | 0 | 0.23 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-02/editor_fresh_reopen.log) |
| gpu-01 / gl_compatibility | PASS | 0 | 3.0 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/gl_compatibility.log) |
| gpu-01 / mobile | PASS | 0 | 4.653 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/mobile.log) |
| gpu-01 / forward_plus | FAIL | 0 | 4.668 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/forward_plus.log) |
| gpu-02 / forward_plus | PASS | 0 | 3.514 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-02/forward_plus.log) |
| gpu-03 / gl_compatibility | FAIL | 1 | 2.782 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/gl_compatibility.log) |
| gpu-03 / mobile | FAIL | 1 | 3.563 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/mobile.log) |
| gpu-03 / forward_plus | FAIL | 1 | 3.539 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/forward_plus.log) |
| gpu-04 / gl_compatibility | PASS | 0 | 2.884 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/gl_compatibility.log) |
| gpu-04 / mobile | PASS | 0 | 3.65 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/mobile.log) |
| gpu-04 / forward_plus | PASS | 0 | 3.586 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/forward_plus.log) |
| gpu-04 / facade_fresh_process | PASS | 0 | 0.215 | [stdout/stderr](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/facade_fresh_process.log) |

### cpu-01 / version — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --headless --version
```

### cpu-01 / import — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --headless --editor --import
```

### cpu-01 / storage — FAIL

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --headless --script res://storage.gd
```

### cpu-01 / mapping — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --headless --script res://mapping.gd
```

### cpu-02 / version — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --headless --version
```

### cpu-02 / import — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --headless --editor --import
```

### cpu-02 / storage — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --headless --script res://storage.gd
```

### cpu-02 / fresh_reopen — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --headless --script res://reopen.gd
```

### cpu-02 / mapping — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --headless --script res://mapping.gd
```

### editor-01 / editor_import — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\editor_project --headless --editor --import
```

### editor-01 / editor_api — FAIL

```text
.scratch\godot\godot.exe --path .scratch\surface0300\editor_project --headless --editor res://out/embedded.tscn
```

### editor-02 / editor_import — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\editor_project_editor-02 --headless --editor --import
```

### editor-02 / editor_api — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\editor_project_editor-02 --editor --position -12000,-12000 res://out/embedded.tscn
```

### editor-02 / editor_fresh_reopen — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\editor_project_editor-02 --headless --script res://editor_reopen.gd
```

### gpu-01 / gl_compatibility — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --rendering-method gl_compatibility --position -12000,-12000 --script res://gpu.gd -- gl_compatibility
```

### gpu-01 / mobile — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --rendering-method mobile --position -12000,-12000 --script res://gpu.gd -- mobile
```

### gpu-01 / forward_plus — FAIL

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --rendering-method forward_plus --position -12000,-12000 --script res://gpu.gd -- forward_plus
```

### gpu-02 / forward_plus — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --rendering-method forward_plus --position -12000,-12000 --script res://gpu.gd -- forward_plus
```

### gpu-03 / gl_compatibility — FAIL

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --rendering-method gl_compatibility --position -12000,-12000 --script res://gpu.gd -- gl_compatibility
```

### gpu-03 / mobile — FAIL

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --rendering-method mobile --position -12000,-12000 --script res://gpu.gd -- mobile
```

### gpu-03 / forward_plus — FAIL

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --rendering-method forward_plus --position -12000,-12000 --script res://gpu.gd -- forward_plus
```

### gpu-04 / gl_compatibility — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --rendering-method gl_compatibility --position -12000,-12000 --script res://gpu.gd -- gl_compatibility
```

### gpu-04 / mobile — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --rendering-method mobile --position -12000,-12000 --script res://gpu.gd -- mobile
```

### gpu-04 / forward_plus — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --rendering-method forward_plus --position -12000,-12000 --script res://gpu.gd -- forward_plus
```

### gpu-04 / facade_fresh_process — PASS

```text
.scratch\godot\godot.exe --path .scratch\surface0300\project --headless --script res://facade_reopen.gd
```

<a id="documents"></a>

## 9. Полные тексты семи исходных документов

Исторические тексты snapshot 23.10.2026. Содержание, tables, code blocks и status qualifications сохранены. Изменены только уровни headings и относительные links: между семью документами — внутренние ссылки на приложения, остальные — pinned GitHub source. Статусы 30.10.2026 указаны в начале сводки.

<a id="doc-index"></a>

### Приложение 1. Навигация

Оригинал: `README.md`; SHA-256: `64e526bd90798cd4718b9a2bd69cd4bbdf49e5b08bc54d28d0de5885fed6369c`.

<!-- BEGIN ORIGINAL README.md -->

#### Stage 03.00 — Surface Material Painting: architecture research

Дата: 23.10.2026. **RESEARCH ONLY. Implementation: NOT AUTHORIZED / NOT STARTED.**

Пакет для review владельца по [Issue #10](https://github.com/alekseypilishkov-gif/go_flora/issues/10). Технические решения ниже — предложения, не принятый ADR.

| Deliverable | Документ |
| --- | --- |
| A. Аудит и рекомендация | [SURFACE_03_00_ARCHITECTURE_REPORT.md](#doc-report) |
| B. Матрица вариантов | [DECISION_MATRIX.md](#doc-matrix) |
| C. Предлагаемый технический контракт | [TECHNICAL_CONTRACT_PROPOSAL.md](#doc-contract) |
| D. Ограниченный Stage 04 | [STAGE_04_MVP_PROPOSAL.md](#doc-mvp) |
| E. CONFIRMED / INFERRED / UNKNOWN, источники, команды, FAIL | [EVIDENCE_INVENTORY.md](#doc-evidence) |
| Git, quality gates, stop point | [DELIVERY.md](#doc-delivery) |

Рекомендация: отдельный Surface subsystem, локальная XZ mask mapping для проверенного ground mesh, четыре устойчиво назначенных канала RGBA8; CPU Resource внутри сцены — единственный источник весов. Собственный ShaderMaterial и сериализуемая Texture2D-обёртка с пересоздаваемым GPU-кэшем. Внешние PNG/.res маски и общий brush framework отложить.

Все исполнявшиеся эксперименты находятся в игнорируемой `.scratch/surface0300/`. В Git включены только отчёты, логи, контрольные суммы и текстовые листинги проб/сериализации; постоянной ручной QA-сцены нет.

**INTERACTIVE_GUI_QA: NOT_RUN. READY_FOR_MANUAL_QA** относится только к будущей интерактивной приёмке, а не к утверждению существования Surface продукта. Итог исследования: **READY_FOR_OWNER_ARCHITECTURE_REVIEW**, с открытыми implementation gates из proposal. Stage 04 требует отдельной задачи владельца.

<!-- END ORIGINAL README.md -->

<a id="doc-report"></a>

### Приложение 2. Архитектурный отчёт

Оригинал: `SURFACE_03_00_ARCHITECTURE_REPORT.md`; SHA-256: `9a694978ac5266357d80772bdd5d1c5e39446e952a8026090f6e459bfc2c5adf`.

<!-- BEGIN ORIGINAL SURFACE_03_00_ARCHITECTURE_REPORT.md -->

#### Surface 03.00 — Architecture & Feasibility Report

23.10.2026. **READY_FOR_OWNER_ARCHITECTURE_REVIEW. Исследование; addon implementation не разрешена.**

##### 1. Вывод для решения владельца

Ограниченный Surface Painter технически реализуем на Godot 4.7.2. Рекомендуется отдельный subsystem рядом с существующим Foliage: scene-owned CPU RGBA8 weights, один supported ground mesh на жест, reusable MaterialSet без индивидуальных масок, собственный ShaderMaterial и scene Undo/Redo. Начальный профиль — статическая однозначная heightfield-поверхность с одной material surface, совпадающим trimesh collider, UV0/нормалями/тангентами и положительным uniform scale; перемещение и yaw допускаются как кандидат поддержки.

Для первого MVP рекомендую **embedded Resource**, а не writable external PNG/.res. Это осознанное уточнение исходной гипотезы, требующее owner approval. Маска 512² — 1 MiB сырых данных и около 1.40 MB текста сцены; четыре таких targets — 4 MiB raw. Ограничение масштаба уменьшает риск расхождения сцены и внешних файлов. Сам по себе успех API-проб не доказывает готовность production save/cancel/UI, сложных склонов или всех GPU.

Отклонить на первом проходе: arbitrary topology, multi-floor/caves, multi-slot materials, blending чужих ShaderMaterials, независимые overlays, автоматическое удаление Foliage, shared universal brush refactor. Полный scope, budgets и критерии: [Stage 04 proposal](#doc-mvp). Точный draft API: [contract](#doc-contract); сравнения: [matrix](#doc-matrix).

##### 2. Проверенная база и действующее направление

| Источник | Закреплённая идентичность / статус |
| --- | --- |
| Удалённый main, GitHub API | `d911087157ecaa9e3ab2b92d95049f2999aebab1`, 0.2.5-dev, PR #14/#17 уже merged |
| Research branch | `codex/stage-03-surface-00-research`, создана от этого main в отдельном managed worktree |
| Основной checkout владельца | `3d043d3ee48578501a2249c13db331b43aee9c37`, другая ветка и существующие untracked; не синхронизировался |
| Draft PR #20 | [product pivot](https://github.com/alekseypilishkov-gif/go_flora/pull/20), OPEN / DRAFT / NOT MERGED, head `6fefe29cad6fbfbb1437b21681a2d31bf576def3` |
| PR #19 / Issue #18 | [canonical Source candidate](https://github.com/alekseypilishkov-gif/go_flora/pull/19), OPEN / NOT MERGED, head `7093b07922999778d01b3afa49ebc4272cc10cde`, 0.2.6-dev, owner GUI NOT_RUN |
| Движок проб | `4.7.2.stable.official.ed1daf0bf`; SHA-256 `ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424` |
| GPU | Windows, NVIDIA RTX 5060 Ti; OpenGL 3.3 NVIDIA 616.56 / Vulkan 1.4.351 |

main проверен через connected GitHub API после DNS FAIL у локального git ls-remote. Исследовательский worktree совпал с API main; локальная ветка main владельца не обновлялась. [Снимок контекста](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/context.json), [защита checkout](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/owner_integrity.json), [исходный hash manifest](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/owner_before.json).

Прочитаны именно версии PR #20: [Product Direction](https://github.com/alekseypilishkov-gif/go_flora/blob/6fefe29cad6fbfbb1437b21681a2d31bf576def3/docs/PRODUCT_DIRECTION_20261023.md), [Roadmap](https://github.com/alekseypilishkov-gif/go_flora/blob/6fefe29cad6fbfbb1437b21681a2d31bf576def3/docs/ROADMAP.md), [Surface draft](https://github.com/alekseypilishkov-gif/go_flora/blob/6fefe29cad6fbfbb1437b21681a2d31bf576def3/docs/SURFACE_MATERIAL_PAINTING_DRAFT.md), а также main [ADR 0001](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/docs/ARCHITECTURE_ADR_0001.md) и [Source contracts](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/docs/STAGE_02_SOURCE_CONTRACTS.md). Старые Tree3D/Stage 03 формулировки в main/ADR остаются историей и не задают текущий scope. PR #20 не переносился в research branch, не изменялся и не сливался. Никакая отменённая генерация не исследовалась как задача реализации.

Binary checksum совпадает с уже закреплённым репозиторным Stage 00 environment; версия подтверждена новым запуском. Независимая загрузка/проверка официального release archive в этом исследовании NOT_RUN; self-reported official build не равен новой supply-chain аттестации.

##### 3. Фактическая архитектура Foliage

**CONFIRMED / source inspection**, addon bytes закреплены [manifest](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/source_identity.json); runtime assertions Surface отдельно перечислены в [inventory](#doc-evidence).

| Узел | Проверенный контракт и сцепление | Решение для Surface |
| --- | --- | --- |
| [plugin.gd](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/addons/go_flora/editor/plugin.gd), L51–159, L949–1076 | Один EditorPlugin владеет dock, всегда включённым forwarding, Foliage tool enum, active layer/set, GFStroke и preview. Esc, outside release, focus out, scene changes отменяют pending. L120 следит за layer transform/data | Сохранить единый вход, добавить явный диспетчер mode ownership. Новая Surface session; существующие enum значения и Foliage маршруты не переписывать |
| [GFSurfaceTarget](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/addons/go_flora/editor/surface_target.gd), L5–28 | Physics ray query использует GFBrush.collision_mask, GFBrush.accepts_hit и VegetationLayer3D.global_transform; исключает go_flora_owned и descendants layer. Результат — collider path, не mesh/material identity | API целиком не переиспользовать. Camera ray arithmetic и исключение owned previews можно вынести в маленький helper только при доказанном выигрыше и parity-тестах |
| [GFBrush](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/addons/go_flora/data/brush.gd), L5–69 | Radius/spacing/filter fields смешаны с density, placement yaw/scale/seed; height может быть layer-relative. accepts_hit не проверяет соответствие render topology | Новый компактный SurfaceBrushSettings. Похожие поля не являются причиной наследовать Foliage Resource |
| [GFStroke](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/addons/go_flora/core/stroke.gd), L30–176 | begin требует GFVegetationLayerData и GFVegetationSet. Resampling по world distance; random placement, source choice, erase queue и результат GFRecordDelta | Переиспользовать принцип distance resampling/break-path/bounded work, не сам класс. Маски требуют opacity, quantization, byte deltas и ownership другого типа |
| [GFPlacement](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/addons/go_flora/core/placement.gd), L5–50 | SHA counter source selection, floor для отрицательных cells; inverse transform для positions, transpose для normals; создаёт GFInstanceRecord | Не использовать для weights. Только математические правила как проверяемые примеры; native Surface sampling независимо от vegetation RNG |
| [GFRecordDelta](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/addons/go_flora/core/record_delta.gd) | Stable record IDs, added/removed arrays, исходные индексы, serial, emit_changed | Сохранить Foliage контракт. Новый immutable mask rect delta, одна native history action на весь gesture |
| [GFVegetationLayerData](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/addons/go_flora/data/layer_data.gd) | Schema 1, records/sets/serial persistent; resource_local_to_scene=true; invalid/future schema disables edits | Не расширять для Surface. Separate schema, IDs, diagnostics и bytes |
| [VegetationLayer3D](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/addons/go_flora/vegetation_layer_3d.gd), L53–127, L129–197 | Resource.changed bindings, signature, deferred coalesced rebuild; internal unowned caches; authoritative records не меняются preview | Принципы ownership/derived cache применимы. MultiMesh renderer, cache roots, placement slots к материалам не относятся |
| [Source Creator](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/addons/go_flora/editor/source_creator.gd), L231–252 и plugin L852–862 | main сохраняет draft и затем публикует тот же объект. PR #19 fix ещё отсутствует | Не копировать этот flow. При любых новых внешних MaterialSet assets: validate → save → disk validate/reload → canonical bind; embedded masks вообще не имеют второго external edit identity |
| plugin L864–877 и [resolver](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/addons/go_flora/sources/source_resolver.gd) | Reimport отменяет pending, CACHE_MODE_REPLACE обновляет источники, инвалидируются render caches | Для Surface отдельно: reimport geometry invalidates mapping; texture reimport refreshes owned rendering, не weights |

В plugin L1071–1074 create_action(... MERGE_DISABLE, layer) явно закрепляет scene context. Palette operations используют собственный set/context и сохраняют render-only references; рисование Surface не должно вызывать эти операции. Source Diagnostics имеет typed status/reason, а не анализ свободного текста; новый Surface validator должен следовать этому принципу, не вызывать vegetation resolver ради ground mesh.

##### 4. Какие общие части оправданы

Немедленный общий BrushBase дал бы зависимости Resource schema, active set/layer, mode values и cancel semantics двум разным транзакциям. Польза в текущем MVP мала: одинаковы лишь ray setup, несколько lifecycle events и distance resampling. Риск — регрессии Foliage Erase queue, outside-release cancellation, selected-source mode и history routing.

Предлагаемая граница: один EditorPlugin владеет input dispatch и modal registry; Foliage controller остаётся прежним, Surface controller получает собственную session. Общий низкоуровневый ray helper возможен после отдельного characterization/parity теста, без изменения публичных GFBrush/GFStroke/GFSurfaceTarget сигнатур. В Stage 04 сначала допустимо несколько строк дублированной camera-ray математики. Полноценный framework не является зависимостью Surface MVP.

##### 5. Targeting и координаты

Local XZ mapping однозначно адресует terrain-like sheet, но два треугольника на разных Y с одинаковыми XZ используют одни texels. Наличие collision не исправляет этот alias. Изолированная проба подтвердила alias и отсутствие UV в physics hit; mesh BVH дал свой face index/position, а сдвиг collider на 0.3 m был обнаружен сравнением позиций. Это plane probe, не валидация любой поверхности.

Поэтому target binding указывает конкретный MeshInstance3D и collider shape; проверяет static triangles, one surface, normals/UV0/tangents, invertible transform, geometry revision и отсутствие projected triangle overlaps (общие рёбра допустимы). Physics hit служит выбором/occlusion guard; тот же camera segment уточняется в локальном TriangleMesh BVH render mesh, расстояние до physics hit проверяется с tolerance. Collider face_index не считается render face_index: importer/physics может иначе упорядочить faces. При несовпадении — diagnostic и никакой записи.

Mapping: affine_inverse(world hit), затем сохранённые origin/extent → [0,1]²; отрицательные coordinates не оборачиваются через fract. World-radius brush проверяет длину преобразованного локального смещения. Математика произвольного nonsingular affine transform прошла probe; реальный physics under non-uniform scale НЕ проверен, а Godot [предупреждает об этом масштабе](https://docs.godotengine.org/en/4.7/classes/class_physicsbody3d.html). Начальный профиль его отвергает.

Точное сравнение mapping alternatives, seams, walls/caves/overlap и границы transformed targets находятся в [matrix](#doc-matrix). В MVP один active target на stroke; cross-target stitching не обещается. Shape mismatch, missing collision, imported geometry revision change, unsupported parent transform — блокирующие причины, не повод незаметно пересоздать карту.

##### 6. Материалы и шейдер

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

##### 7. Persistence, canonical identity и Undo

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

##### 8. UI и будущие правила Foliage

Dock сохраняет нынешний outer ScrollContainer (minimum 260×120) и доступ Inspector/FileSystem/Output. Сверху — mutually exclusive Foliage / Surface; внутри Surface — target/status, MaterialSet, четыре строки layers, Paint/Erase-to-Base, radius/strength/falloff. Материальные настройки подробного уровня — через Inspector. Постоянная большая Studio и перенос существующих docks не нужны.

Mode switching сначала отменяет active session и закрывает принадлежащие ей модальные окна. Один LMB обрабатывается ровно одним controller; Source Creator/picker/Diagnostics modal блокируют painting обоих режимов. Native Alt/Ctrl navigation, RMB/MMB, wheel и shortcuts передаются редактору после cancel pending. Existing Foliage Source palette, selected/mix, Erase, distance, retained sources и Diagnostics остаются доступны в Foliage и не переиспользуются как Material palette. Проверка мышью, размер dock при длинных названиях и реальное взаимодействие с native popups: **NOT_RUN**, будущий owner gate.

Foliage позже получает versioned read-only weight query с explicit target identity/height/revision, immutable snapshot и typed failures. UNKNOWN не превращается в нулевой вес. Surface strokes не знают о GFInstanceRecord и не удаляют существующие растения. Reconcile/Rescatter требует отдельной авторизации, preview и собственного Undo; контракт запроса — в [proposal](#doc-contract).

##### 9. Остаточные риски и решение о Stage 04

| Риск | Чего доказательства пока не устанавливают | Обязательный gate |
| --- | --- | --- |
| Target capability validation | Нет production validator projected overlap/topology/collider equivalence | Reject fixtures + реальные approved meshes до включения painting |
| Normal/color/sampler behavior | Flat debug pass не доказывает lit slope или между-backend parity | Lit directional textures, flat/steep slopes, full lighting, declared backend fixtures |
| Durable native saving | Rename PASS не равен crash-safe transaction; full Surface scene graph ещё отсутствует | Failure injection, reopen, Save As, plugin disabled/runtime/export |
| Identity after duplicate/reimport | local_to_scene копирует bytes, но не делает IDs уникальными | Duplicate conflict, explicit Fork Undo, missing/corrupt/future schema сохранность |
| Interactive arbitration | Код Foliage читаем; Surface controller не существует | Owner mouse/navigation/modal/save matrix, regression suite |
| CPU/VRAM/undo costs | Нет sustained brush benchmark, actual VRAM или mobile hardware | 512²/4-target budget, retained delta cap, upload cadence, performance profile |

**Рекомендация: Stage 04 feasible, условно GO после принятия owner-ом** support profile, embedded storage/budgets, shader/material input contract, SurfaceBrush semantics, recovery/identity policy и независимой задачи реализации. Утверждение архитектуры не означает merge PR #19/#20, разрешение установки, release или начало Stage 04. Исследование здесь останавливается.

<!-- END ORIGINAL SURFACE_03_00_ARCHITECTURE_REPORT.md -->

<a id="doc-matrix"></a>

### Приложение 3. Матрица решений

Оригинал: `DECISION_MATRIX.md`; SHA-256: `ca15066dd92147428f60c144f46b53d853fe11339307b696ff4e9da9c8b3f676`.

<!-- BEGIN ORIGINAL DECISION_MATRIX.md -->

#### Surface 03.00 — Decision matrix

Все cost/complexity оценки ниже — **INFERRED relative estimates**, не измеренные сроки разработки. L/M/H = low/medium/high. Runtime evidence указано отдельно; proposed support не выдаётся за PASS.

##### 1. Mapping / topology

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

##### 2. Storage / authority

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

##### 3. Rendering / material strategy

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

##### 4. Оценки памяти и цены мазка

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

<!-- END ORIGINAL DECISION_MATRIX.md -->

<a id="doc-contract"></a>

### Приложение 4. Технический контракт proposal

Оригинал: `TECHNICAL_CONTRACT_PROPOSAL.md`; SHA-256: `44cba630117c77fb9ff5e47926d65d77272148e380caa4820475edb50705c307`.

<!-- BEGIN ORIGINAL TECHNICAL_CONTRACT_PROPOSAL.md -->

#### Surface 03.00 — Technical contract proposal

**PROPOSED / NOT IMPLEMENTED / NOT ACCEPTED ADR.** Names, schema fields, limits и brush behavior требуют owner review. Текущие GFInstanceRecord, GFVegetationSet, GFBrush и Source Kind значения не меняются.

##### 1. Candidate objects и зависимости

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

Adapter suitability подтверждена [GPU probes](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/summary.json), но whole scene graph alias preservation, inspector duplication и packed export ещё не tested. Stage 04 должен доказать, что сценовая сериализация сохраняет data единожды, обе references после load указывают на один authored object, а private GPU object не попал в serialized graph.

##### 2. Target capability contract

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

##### 3. Mapping, addressing и stable IDs

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

##### 4. Четыре веса и channel table

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

##### 5. Material ownership и runtime loading

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

##### 6. Brush transaction и история

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

##### 7. Dirty state, save, recovery и cache

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

##### 8. Future read-only Surface→Foliage query

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

<!-- END ORIGINAL TECHNICAL_CONTRACT_PROPOSAL.md -->

<a id="doc-mvp"></a>

### Приложение 5. Предложение Stage 04 MVP

Оригинал: `STAGE_04_MVP_PROPOSAL.md`; SHA-256: `6c1aa9f37a14988c2ba209d698ea89f74e0c1a642b53202283be460ff7cb73a2`.

<!-- BEGIN ORIGINAL STAGE_04_MVP_PROPOSAL.md -->

#### Stage 04 — bounded Surface Painter MVP proposal

**NOT AUTHORIZED / NOT STARTED.** Это review-ready предложение будущей задачи. Stage 03 исследование не санкционирует код, установку ZIP, merge или release.

##### 1. Точный рекомендуемый scope

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

##### 2. Unsupported / excluded

Walls, near-vertical cliffs, caves/overhangs, multi-level or projected-overlap targets, negative/non-uniform scale, shear/pitch/roll, multiple material slots, CSG/GridMap/Terrain3D adapters, skinned/deforming meshes, inherited/instanced authoring, cross-target seamless strokes, UV-space painting, vertex-color writes, mask resize/remap, external mutable mask authoring, 8+ layers, independent snow/puddle overlays, height blend, texture packing/generation, Studio, runtime player painting, Surface→Foliage filters и Reconcile.

Соседние независимые targets допустимы в пределах лимита; автоматическое совпадение border weights/UV tiles не входит в support. Для неподдержанного случая — объяснение и сохранение data, без скрытого “best effort” paint.

##### 3. Implementation decomposition и stop gates

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

##### 4. Главные regression risks

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

##### 5. Test requirements

###### Автоматические isolated tests, не owner GUI

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

###### Физическая owner acceptance

После отдельной implementation/installation authorization использовать согласованный owner project/scene. Новые постоянные manual scenes не создавать автоматически; существующий TEST_FLORA в исследовании не открывался и не менялся. В будущей задаче владелец подтверждает один согласованный шаг за раз.

1. Source palette/Diagnostics в Foliage доступны; camera orbit/pan/zoom, Inspector, FileSystem и Output работают.
2. Surface attach на approved ground явно показывает original binding/reversibility и неподдержанные target diagnostics.
3. Выбрать Grass/Dirt/Rock/Mud, провести видимый blended stroke; один Undo убирает весь мазок, один Redo возвращает.
4. Erase to Base/Replace соответствуют названиям. Во время мазка Esc/focus/mode/popup/scene switch не оставляют частичный результат.
5. Native Save/Save As/полное закрытие и повторное открытие сохраняют masks, MaterialSet refs и исходные assets; plugin disable/runtime ground остаётся корректным.
6. Отдельно подтвердить normal/roughness/color appearance на согласованных backends и stable dock при длинных labels.

До выполнения: **INTERACTIVE_GUI_QA: NOT_RUN / READY_FOR_MANUAL_QA**. Native/headless/GPU evidence этого статуса не меняет.

##### 6. Acceptance criteria будущей реализации

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

##### 7. Что именно требуется утвердить до старта

Владелец принимает support profile и отказ от arbitrary mesh claims; четыре stable channels и Erase-to-Base behavior; embedded scene storage вместо external mutable masks с указанными limits; Texture2D bridge/owned override restoration; texture/normal/color contract и renderer qualification gates; identity/fork/save recovery rules; test/GUI scope и отдельную Stage 04 implementation issue/branch.

Если нужны сразу большие карты, external mask authoring или стены/пещеры, этот bounded MVP нужно пересмотреть **до** кода. До такого решения остаётся только текущий research Draft PR. Stage 04 здесь не начат.

<!-- END ORIGINAL STAGE_04_MVP_PROPOSAL.md -->

<a id="doc-evidence"></a>

### Приложение 6. Evidence inventory

Оригинал: `EVIDENCE_INVENTORY.md`; SHA-256: `f5e9965a221d27336d968d153ea2a76bcdefda96208b37d5a1ab3b24f5f193d7`.

<!-- BEGIN ORIGINAL EVIDENCE_INVENTORY.md -->

#### Surface 03.00 — Evidence inventory

Дата: 23.10.2026. Source inspection, native runtime, GPU pixels, Editor API и owner GUI учитываются отдельно. **CONFIRMED** означает только указанный узкий scope. **INFERRED** — проектная оценка/решение. **UNKNOWN / NOT_TESTED** — доказательств пока нет.

##### 1. Findings и степень уверенности

| ID | Finding | Класс / evidence |
| --- | --- | --- |
| E01 | Remote main d911087, PR #20 Draft 6fefe29, PR #19 open 7093b07 | CONFIRMED, live GitHub connector metadata, [context](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/context.json). Owner GUI state PR19 — reported metadata, не повторная QA |
| E02 | GFBrush/GFStroke/GFSurfaceTarget зависят от Foliage data/layer/set; native undo context — layer | CONFIRMED source inspection на main, [audit](#doc-report), [source SHA256](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/source_identity.json). Это не Foliage runtime regression suite |
| E03 | PNG codec сохранил bytes всех каналов при alpha=0 | CONFIRMED native headless, [storage](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/storage.log) |
| E04 | save draft → path пуст, canonical load другой object | CONFIRMED native headless, тот же storage log. Reproduces general Issue18 class, не повторный полный Source Creator test |
| E05 | PackedScene ResourceSaver.save не flushes изменённый external Resource; REUSE возвращает RAM | CONFIRMED narrow API test, storage log. Физический Ctrl+S внешнего .res НЕ тестировался |
| E06 | Embedded Resource bytes сохраняются, fresh process load exact, local_to_scene isolates objects | CONFIRMED, [fresh reopen](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/fresh_reopen.log), serialized [embedded scene text](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/embedded.tscn.txt) |
| E07 | Duplicated local Resources retain identical authored surface_id | CONFIRMED observation fresh reopen; explicit fork/scope — INFERRED design consequence |
| E08 | One complete byte transaction Undo/Redo restores exact bytes | CONFIRMED core UndoRedo, storage log; Surface gesture controller отсутствует |
| E09 | Native EditorUndoRedoManager scene context + undo/redo, _apply_changes on save, reopened bytes | CONFIRMED graphical native Editor API, [editor log](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-02/editor_api.log), [new process](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-02/editor_fresh_reopen.log); не mouse GUI |
| E10 | Local affine inverse, non-uniform brush metric, negative floor math | CONFIRMED arithmetic in Godot, [mapping](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/mapping.log). Physical non-uniform support NOT_TESTED |
| E11 | Physics hit не даёт UV; TriangleMesh plane BVH hit; 0.3 m collider mismatch detectable; stacked floors alias XZ | CONFIRMED limited plane/math fixture, mapping log. Arbitrary topology validator NOT_IMPLEMENTED |
| E12 | 4 channel + zero fallback + normalized mix + roughness/flat-normal debug sampler values | CONFIRMED GPU on RTX 5060 Ti, [final GPU run](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/summary.json) and per-renderer logs/JSON |
| E13 | ImageTexture.update меняет GPU, не source PNG bytes | CONFIRMED native GPU/disk hash, gpu-04 logs. Не export/import pipeline proof |
| E14 | Serialized Texture2D facade содержит CPU data, private GPU ImageTexture отсутствует; reload renders | CONFIRMED scratch adapter, gpu-04 logs, [facade text](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/facade_forward_plus.tres.txt), [fresh CPU process](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/facade_fresh_process.log) |
| E15 | GL vs Vulkan output differs for same blend | CONFIRMED observed pixels in gpu-04, ~0.502/0.498 vs ~0.737/0.733. Не identical visual parity |
| E16 | Per-instance surface override сохраняет shared source material; null restores | CONFIRMED simple native API test, storage log. Full attach/restore conflicts NOT_TESTED |
| E17 | 256/512/1024 embedded raw vs scene sizes/time | CONFIRMED single-run measurement, [storage JSON](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/storage.json). Не distribution/p95/RSS/FPS |
| E18 | Same-directory .res replacement succeeds, bypass reload sees new bytes | CONFIRMED ordinary native filesystem case, storage log. Atomic crash/power-loss guarantee UNKNOWN |
| E19 | Embedded CPU graph + facade — safest bounded MVP option | INFERRED architecture judgement, [matrix](#doc-matrix), exact contract proposed |
| E20 | 13 samplers support production lit materials/low-end/mobile devices | UNKNOWN / NOT_TESTED. Только narrow desktop debug API pass |
| E21 | Native failed-save recovery, full target/material graph, export/runtime disabled plugin | UNKNOWN / NOT_TESTED — Stage04 mandatory gates |
| E22 | Esc/focus/modal/mode/scene switch Surface input, compact UI mouse acceptance | NOT_RUN — controllers/UI не реализованы; Foliage paths inspected only |
| E23 | Main owner checkout hashes/status unchanged | CONFIRMED bounded file manifest, [owner integrity](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/owner_integrity.json). Ignored caches/Git administrative metadata excluded; TEST_FLORA и PR19 worktree не инспектировались |
| E24 | Old addon/docs/tests/tools/historical stage bytes unchanged on research branch | CONFIRMED scope/identity gate, [quality](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality.json), [addon manifest](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/source_identity.json) |
| E25 | Future Foliage query не удаляет placements; proposed weights filtering | INFERRED contract, implementation NOT_RUN |

##### 2. Что исполнялось и где точные команды

Каждый run summary содержит argv, exit code, PASS/FAIL и duration; соседний log — полный stdout/stderr. Общие reusable wrapper commands выполнялись из research root:

```text
python .scratch/surface0300/snapshot.py before
python .scratch/surface0300/run.py --phase cpu --label cpu-01
python .scratch/surface0300/run.py --phase cpu --label cpu-02
python .scratch/surface0300/run.py --phase gpu --label gpu-01
python .scratch/surface0300/run.py --phase gpu --renderer forward_plus --label gpu-02
python .scratch/surface0300/run.py --phase editor --label editor-01
python .scratch/surface0300/run.py --phase editor --editor-gpu --label editor-02
python .scratch/surface0300/run.py --phase gpu --label gpu-03
python .scratch/surface0300/run.py --phase gpu --label gpu-04
python .scratch/surface0300/snapshot.py after
python .scratch/surface0300/finalize.py
```

На этой машине python вызван через bundled runtime; Godot argv использует **repo-relative** `.scratch/godot/godot.exe` и disposable project path. Engine copied из уже имеющегося owner ignored binary **read-only**, без установки/скачивания packages. APPDATA/LOCALAPPDATA всех Godot процессов направлены в research scratch profiles. GPU/native Editor API запускались вне экрана; реальные mouse/navigation действия не выполнялись.

| Attempt | Результат процесса/причина | Evidence |
| --- | --- | --- |
| cpu-01 | FAIL storage на shutdown: scratch harness не освободил UndoRedo Object; semantic assertions прошли. Остальные 3 cases PASS | [summary](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/summary.json), [FAIL log](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/storage.log) |
| cpu-02 | **PASS 5/5 cases**, после clear_history/free UndoRedo; PNG load warning об export сохранён | [summary](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/summary.json) |
| gpu-01 | GL/Mobile PASS; Forward+ FAIL из-за создания длинных shader-cache paths при shutdown, exit 0 не считался PASS | [summary](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/summary.json), [FAIL log](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/forward_plus.log) |
| gpu-02 | **PASS Forward+**, только failed backend повторён; shader/pipeline disk cache выключен в scratch project, пользовательские settings не менялись | [summary](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-02/summary.json) |
| editor-01 | Import PASS, save API assertions прошли, но dummy renderer thumbnail ERROR → overall FAIL | [summary](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-01/summary.json), [FAIL log](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-01/editor_api.log) |
| editor-02 | **PASS 3/3**, real GL native Editor API + fresh process | [summary](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-02/summary.json) |
| gpu-03 | FAIL 3/3: harness ошибочно требовал отсутствия всех ImageTexture во всём ShaderMaterial, хотя 12 detail fixtures именно ImageTexture | [summary](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/summary.json) |
| gpu-04 | **PASS 4/4**: проверяется отдельно facade serialization; 3 GPU backends + fresh-process CPU facade read | [summary](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/summary.json) |

Итог relevant final process cases: **12 PASS** (cpu-02 + editor-02 + gpu-04). Сохранились **6 FAIL** ранних process cases; их причины исправлены только в disposable harness/config, логи не переписаны. Overall “all attempts PASS” не заявляется.

Raw GPU JSON относится к pixel assertions, а process summary дополнительно учитывает shutdown errors: поэтому в ранних attempts JSON мог содержать PASS при overall FAIL. Приоритет классификации — summary + полный log, а не последняя строка PASS. Build/compiler timing и shader disk cache behavior не оценивались как performance.

Первый static repository gate дал FAIL: quality.json ещё не был создан, а ссылки на него уже существовали. Сохранены [первичный quality result](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality-initial.json) и [log](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/repository.log). После формирования файла gate повторяется с новым label; это ошибка порядка формирования evidence, не addon defect. Финальные команды: `python .scratch/surface0300/finalize.py final-01` и после первого commit `python .scratch/surface0300/finalize.py post-commit`.

##### 3. Reproduction и граница source listings

[Probe source listings](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/run.py.txt), [storage](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/storage.gd.txt), [mapping](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/mapping.gd.txt), [GPU harness](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/gpu.gd.txt), [shader](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/mix.gdshader.txt), [facade](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/facade.gd.txt), [Editor API harness](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/editor_probe.gd.txt). SHA-256 финальных листингов: [manifest](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources_manifest.json). Это **текстовые evidence final harness**, не код addon и не готовая Surface implementation. Early FAIL scripts отличались исправлениями, описанными в таблице; финальные листинги не объявляются byte-identical ранним attempts.

Для воспроизведения создать disposable `.scratch/surface0300/project/`, восстановить имена файлов из *.txt: run.py/snapshot.py/editor_probe.gd/editor_reopen.gd → `.scratch/surface0300/`; остальные *.gd, *.gdshader и project.godot → project/. Положить engine с указанным SHA в `.scratch/godot/godot.exe`. Запустить cpu с новым label, затем gpu и editor --editor-gpu с новыми labels. Не запускать against TEST_FLORA/owner scenes. Existing run labels immutable; runner отказывает overwrite output.

Serialization excerpts хранятся с расширением .txt; PNG screenshots — generated synthetic fixture, не UI/mockup и не owner evidence. Codec input PNG load warnings объясняют, почему чтение filesystem PNG не служит proof exported asset availability. Прямых зависимости от .scratch в продукте или production code нет.

##### 4. Source/API reference inventory

| Reference | Что использовано | Ограничение |
| --- | --- | --- |
| [Godot 4.7.2 release](https://github.com/godotengine/godot/releases/tag/4.7.2-stable) | Official release context; run version и checksum закреплены отдельно | Archive supply-chain redownload NOT_RUN |
| [Image](https://docs.godotengine.org/en/4.7/classes/class_image.html) / [ImageTexture](https://docs.godotengine.org/en/4.7/classes/class_imagetexture.html) | CPU RGBA8, image data, GPU update API | update ≠ external save |
| [Resource](https://docs.godotengine.org/en/4.7/classes/class_resource.html) / [ResourceLoader](https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html) | local-to-scene, explicit change notification, cache modes | Instance equality не cross-process identity |
| [ResourceSaver](https://docs.godotengine.org/en/4.7/classes/class_resourcesaver.html) / [DirAccess](https://docs.godotengine.org/en/4.7/classes/class_diraccess.html) | Native serialized resources, compressed binary candidate, rename/replace | Документация rename не обещает power-loss transaction |
| [Texture2D](https://docs.godotengine.org/en/4.7/classes/class_texture2d.html) | Serialized texture bridge with private GPU implementation; inherited Resource RID API | Runtime proof — scratch facade, не complete addon |
| [EditorPlugin](https://docs.godotengine.org/en/4.7/classes/class_editorplugin.html) / [EditorInterface](https://docs.godotengine.org/en/4.7/classes/class_editorinterface.html) | Input return policies, apply/save lifecycle, native scene save/dirty | Hooks с void return не save veto |
| [EditorUndoRedoManager](https://docs.godotengine.org/en/4.7/classes/class_editorundoredomanager.html) | Custom context avoids global external-resource history | Exact Surface gesture lifecycle NOT_IMPLEMENTED |
| [PhysicsDirectSpaceState3D](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectspacestate3d.html) / [TriangleMesh](https://docs.godotengine.org/en/4.7/classes/class_trianglemesh.html) | Collider hit vs actual render triangle BVH refinement | Surface support не следует из collision |
| [ConcavePolygonShape3D](https://docs.godotengine.org/en/4.7/classes/class_concavepolygonshape3d.html) / [PhysicsBody3D](https://docs.godotengine.org/en/4.7/classes/class_physicsbody3d.html) | Static trimesh intended use, non-uniform-scale warning | Arbitrary transformed collision NOT_TESTED |
| [MeshDataTool](https://docs.godotengine.org/en/4.7/classes/class_meshdatatool.html) | Native vertex data alternative | Vertex-paint probe NOT_RUN, imported mesh writes rejected by design |
| [Spatial shader](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html) / [Shading language](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/shading_language.html) | NORMAL_MAP, ALBEDO, ROUGHNESS, sampler/color hints | 4.7 docs are minor-version API reference; patch-specific behavior подтверждают runs |
| [Renderer overview](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html) | Forward+/Mobile/Compatibility backend families | Desktop Mobile renderer не mobile hardware coverage |
| [MeshInstance3D](https://docs.godotengine.org/en/4.7/classes/class_meshinstance3d.html) / [GeometryInstance3D](https://docs.godotengine.org/en/4.7/classes/class_geometryinstance3d.html) | Owned instance overrides и restoration boundary | Simple API ownership test, сложные bindings future gate |
| [EditorSettings](https://docs.godotengine.org/en/4.7/classes/class_editorsettings.html) | Settings API; safe_save flag наблюдался в native probe | Setting=true не filesystem failure-injection evidence |

Primary APIs/browser sources прочитаны 23.10.2026. Source redistribution из Godot/Epic/других addon не выполнялась; harness и synthetic fixtures авторские по root MIT. Unreal — только workflow direction от owner docs, не источник переносимого shader кода.

##### 5. NOT_RUN / UNKNOWN inventory

INTERACTIVE_GUI_QA: **NOT_RUN / READY_FOR_MANUAL_QA**. Полного Surface addon/UI нет, owner mouse acceptance невозможна в рамках research. Foliage regression suites заново не запускались: addon и tests не менялись, scope/hash gates обеспечивают только byte preservation. Их прошлые PASS не переименовываются в новые runtime результаты.

Также NOT_RUN: full lit PBR/slope/parity, actual mobile/low-end/Web/other OS, frame time/RSS/VRAM, sustained large-map strokes, real Surface cancel/undo transactions, full graph duplicate/fork/reimport, native failed-save injection/power-loss, export, packaging/ZIP/installation, owner scene changes. Они перечислены как необходимые gates будущего [MVP](#doc-mvp), не как незавершённая разрешённая реализация.

Read-only preflight environment issues: PowerShell provider warning; local git ls-remote DNS failure; sandboxed linked-worktree git cwd access denied, повтор в разрешённом scoped execution прошёл; первый quoted cmd python invocation failed before execution; source-display helper encoding error исправлен на UTF-8. Они не являются Godot product defects. Точное состояние и качество итогового deliverable — [delivery](#doc-delivery) и [quality JSON](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality.json).

<!-- END ORIGINAL EVIDENCE_INVENTORY.md -->

<a id="doc-delivery"></a>

### Приложение 7. Доставка

Оригинал: `DELIVERY.md`; SHA-256: `dd3711954fe152b98e67fd8998e23335e92c66d9e5f2c463ab2316b431d051d9`.

<!-- BEGIN ORIGINAL DELIVERY.md -->

#### Stage 03.00 — Delivery and stop point

**READY_FOR_OWNER_ARCHITECTURE_REVIEW.** Stage 03 research completed. **Surface implementation NOT STARTED / NOT AUTHORIZED. INTERACTIVE_GUI_QA: NOT_RUN / READY_FOR_MANUAL_QA.**

- Research branch: `codex/stage-03-surface-00-research`.
- Baseline: remote main `d911087157ecaa9e3ab2b92d95049f2999aebab1`.
- Isolated worktree: Codex managed `surface-03-00-research/GO_FLORA`; owner's primary checkout and PR #19 checkout retained.
- Exact delivered commit and research Draft PR URL are supplied in the final delivery message and PR head. This file is part of that commit; no self-referential future SHA is invented.
- [Report](#doc-report), [decision matrix](#doc-matrix), [technical contract](#doc-contract), [Stage 04 proposal](#doc-mvp), [evidence inventory](#doc-evidence).

Recommended candidate: dedicated Surface data/controller, local XZ ground-only mapping, four stable normalized RGBA8 channels, scene-embedded CPU authority, reusable prepared MaterialSet, owned ShaderMaterial with Texture2D facade/private GPU cache, and one scene Undo action per entire stroke.

Principal cost: capped map/target sizes and larger text scene files. Principal unresolved risks: lit normal/color parity and full sampler pressure; reliable topology/collider validation; complete target/material serialization and duplicate identity; native failed-save recovery; actual Surface input/UI lifecycle, export and performance. Stage 04 is feasible within the bounded profile after explicit owner approval of the [proposed scope and gates](#doc-mvp).

##### Evidence and quality gates

[Quality command results](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality.json), [owner checkout integrity](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/owner_integrity.json), [pinned addon identity](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/source_identity.json), [probe source checksums](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources_manifest.json).

Final relevant probe cases: CPU 5 PASS, native Editor API 3 PASS, GPU/facade 4 PASS. Earlier 6 FAIL process cases remain recorded with causes in the inventory. No result is presented as owner interactive acceptance. New packages were not installed; no release/ZIP/manual scene was produced.

Working/staged whitespace, static repository validation, historical/source scope checks and committed PR-base diff checks are required for delivery. Post-commit checks are run against the final HEAD; runtime source/listing identity is independent of later documentation-only delivery commits. Source inspection is not relabeled runtime testing.

Only this Stage 03 directory changes in the research PR. Existing addon, tests, docs, previous-stage evidence and MIT/third-party notices remain unchanged. Primary checkout tracked/untracked manifest is compared before/after excluding ignored caches and Git administrative files; no TEST_FLORA/PR19 worktree content was inspected, copied or written.

PR #20 remains the owner-approved direction snapshot, open Draft and unmerged. PR #19 remains separate/open/unmerged; its owner GUI acceptance is not inferred from this work. Research branch is pushed and Draft PR targets main without modifying either existing PR.

**STOP. Await owner architecture decision. No merge, release, installation, resource migration or Stage 04 implementation is authorized by this delivery.**

<!-- END ORIGINAL DELIVERY.md -->

<a id="inventory"></a>

## 10. Индекс всех файлов исходного research-пакета

112 файлов из pinned commit `afeae8b50e581639f4d86b65340da78c9dcb3545`. SHA-256 вычислены по committed bytes из Git archive; line endings JSON/logs могут отличаться от Windows working copy. Новая сводка в этот исходный пакет не входит. Полное содержимое больших hash manifests и сырых logs доступно по pinned links и в исходном ZIP.

| Путь относительно Stage 03.00 | Bytes | SHA-256 committed bytes | Source |
| --- | --- | --- | --- |
| DECISION_MATRIX.md | 14568 | `ca15066dd92147428f60c144f46b53d853fe11339307b696ff4e9da9c8b3f676` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/DECISION_MATRIX.md) |
| DELIVERY.md | 3339 | `dd3711954fe152b98e67fd8998e23335e92c66d9e5f2c463ab2316b431d051d9` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/DELIVERY.md) |
| EVIDENCE_INVENTORY.md | 17881 | `f5e9965a221d27336d968d153ea2a76bcdefda96208b37d5a1ab3b24f5f193d7` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/EVIDENCE_INVENTORY.md) |
| README.md | 2409 | `64e526bd90798cd4718b9a2bd69cd4bbdf49e5b08bc54d28d0de5885fed6369c` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/README.md) |
| STAGE_04_MVP_PROPOSAL.md | 15689 | `6c1aa9f37a14988c2ba209d698ea89f74e0c1a642b53202283be460ff7cb73a2` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/STAGE_04_MVP_PROPOSAL.md) |
| SURFACE_03_00_ARCHITECTURE_REPORT.md | 26338 | `9a694978ac5266357d80772bdd5d1c5e39446e952a8026090f6e459bfc2c5adf` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/SURFACE_03_00_ARCHITECTURE_REPORT.md) |
| TECHNICAL_CONTRACT_PROPOSAL.md | 23435 | `44cba630117c77fb9ff5e47926d65d77272148e380caa4820475edb50705c307` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/TECHNICAL_CONTRACT_PROPOSAL.md) |
| evidence/context.json | 18277 | `71a4a2bb06430c999e523e1e0b401b5b4cb392f4330754792fb353212899f734` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/context.json) |
| evidence/owner_before.json | 504705 | `a824619f6511f687468853bbaf6c23a8a0cf14c3e71114cd89545f70efcb6245` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/owner_before.json) |
| evidence/owner_integrity.json | 244 | `b9cffb4644c24cfb7d350598ccede74421e6d383d0ea3e329ab86b96a553cdb1` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/owner_integrity.json) |
| evidence/probe_sources/editor_probe.gd.txt | 2377 | `9fa569cfbd18d45f739d734b05028c5bb41a8feba3f90daf5f798bd850ea4290` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/editor_probe.gd.txt) |
| evidence/probe_sources/editor_reopen.gd.txt | 415 | `9d961daa5555d3986ee6db494b3e4096c968ad4055c55373e45c8c4db34d34b0` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/editor_reopen.gd.txt) |
| evidence/probe_sources/facade.gd.txt | 641 | `fac08623ce62c8cfe0e2c33884ecd5fb6083b0167ad2fe0905da46f4df09071c` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/facade.gd.txt) |
| evidence/probe_sources/facade_reopen.gd.txt | 381 | `c088530dd58e8a009235709270ddf2c0db4fdc1dccb38b047a73759dc6c2d349` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/facade_reopen.gd.txt) |
| evidence/probe_sources/finalize.py.txt | 4169 | `d0b20ef13fa42eb0c1b38cc773f8431e5de1c8a3838141460ec77d7782ea60b3` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/finalize.py.txt) |
| evidence/probe_sources/gpu.gd.txt | 6430 | `0b4bcaae5555c827877129de3612671e73199ae5e622fca565c5da61a2ce07a7` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/gpu.gd.txt) |
| evidence/probe_sources/holder.gd.txt | 43 | `c88b3e2f086836115c686c1815e4da80a1a3aa9d3d9dd7bd82d221057b4aa7e7` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/holder.gd.txt) |
| evidence/probe_sources/mapping.gd.txt | 2312 | `aa56a567bd806a25090bbf227f45db2bc7d04fde7e81ff73becdfde6edb4dea1` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/mapping.gd.txt) |
| evidence/probe_sources/mask.gd.txt | 322 | `635845bd46044d2696355c3e7bcc6096a8f21be24b4d23fd5750b2386a890ebf` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/mask.gd.txt) |
| evidence/probe_sources/mix.gdshader.txt | 1957 | `d66f29c95069e4c5515b79d76c243c7588994ceb5a730bfac356b1e8b00064e3` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/mix.gdshader.txt) |
| evidence/probe_sources/project.godot.txt | 283 | `ac9e4cd7a0f64baf1067d395bbb0dbc943475701a03e7ca9231e596f70939299` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/project.godot.txt) |
| evidence/probe_sources/reopen.gd.txt | 588 | `d5cbc0727c504ea0d880bb847c03761faa6d0e4861c2e276f5e31289176b0e36` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/reopen.gd.txt) |
| evidence/probe_sources/run.py.txt | 5985 | `7b0d772ad41f8f97b0959010d0f9f568439793c3c4b516bceb4e117366c63fbf` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/run.py.txt) |
| evidence/probe_sources/snapshot.py.txt | 1809 | `70094cedc5084aeb826b77bddf754d4e779d7c21a656af55aec18f231adfd9a8` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/snapshot.py.txt) |
| evidence/probe_sources/storage.gd.txt | 5671 | `1cb0f474680ef9013ffe1554ef86904190cbd9eb12a04b8d3971b153f031b1fb` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources/storage.gd.txt) |
| evidence/probe_sources_manifest.json | 1543 | `e6bef7a2e003b406279093bf9c0af37314ea2f29428ec8e7e30b08636213ce53` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/probe_sources_manifest.json) |
| evidence/quality-initial.json | 1869 | `284ea17526ab0bdbe3cf2adb32b8fbcb506db75d2969b5930b5b529e6d07e26f` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality-initial.json) |
| evidence/quality.json | 1868 | `521acce32fe4a1f767b9d95bd42d9d91c3554959f71c0bf259cb939fa755abc1` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality.json) |
| evidence/quality/committed_whitespace.log | 1 | `01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/committed_whitespace.log) |
| evidence/quality/final-01/committed_whitespace.log | 1 | `01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/final-01/committed_whitespace.log) |
| evidence/quality/final-01/repository.log | 81 | `0cc612349e8fab7df5bee5f0d376af3a8fddc56df157eab7c3d775f532275c39` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/final-01/repository.log) |
| evidence/quality/final-01/scope.log | 1 | `01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/final-01/scope.log) |
| evidence/quality/final-01/staged_whitespace.log | 1 | `01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/final-01/staged_whitespace.log) |
| evidence/quality/final-01/working_whitespace.log | 1 | `01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/final-01/working_whitespace.log) |
| evidence/quality/post-commit/committed_whitespace.log | 1 | `01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/post-commit/committed_whitespace.log) |
| evidence/quality/post-commit/repository.log | 81 | `0cc612349e8fab7df5bee5f0d376af3a8fddc56df157eab7c3d775f532275c39` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/post-commit/repository.log) |
| evidence/quality/post-commit/scope.log | 1 | `01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/post-commit/scope.log) |
| evidence/quality/post-commit/staged_whitespace.log | 1 | `01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/post-commit/staged_whitespace.log) |
| evidence/quality/post-commit/working_whitespace.log | 535 | `2c265e3c2f7c22c00fc60a736d6da9c22dd84252bd9b90d8cc95fc97979317fe` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/post-commit/working_whitespace.log) |
| evidence/quality/repository.log | 353 | `e7212d7d155fc83d09d3cd6734b82b46416420b3a260586cec9220c28775b781` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/repository.log) |
| evidence/quality/scope.log | 1 | `01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/scope.log) |
| evidence/quality/staged_whitespace.log | 1 | `01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/staged_whitespace.log) |
| evidence/quality/working_whitespace.log | 1 | `01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/quality/working_whitespace.log) |
| evidence/runs/cpu-01/embedded.tscn.txt | 5954 | `bff9f981d26e487c8ba9a2577513f7704783016a5919c65451884ea203e84c3e` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/embedded.tscn.txt) |
| evidence/runs/cpu-01/external.tscn.txt | 283 | `a213274594a563cde0f8bfa0b3dc05fc8f05320911cd9a6afdd893517425fc1b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/external.tscn.txt) |
| evidence/runs/cpu-01/import.log | 1753 | `c9ce3b222c5953f3476fa2bc71ec95070738a6f8458a8a2ae4d3de2ca49758ae` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/import.log) |
| evidence/runs/cpu-01/mapping.log | 633 | `4ccf603303530dc768fc23c5885bb8bafdadadaad147f2a99be1ffd579d431bc` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/mapping.log) |
| evidence/runs/cpu-01/storage.json | 3078 | `def650b527be8a9e1fefa5ab63b88c7aac7a367bb184ed0e4e299c4c5d9fc9fc` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/storage.json) |
| evidence/runs/cpu-01/storage.log | 1606 | `8e6e2f9c37d8f08f9f4c43fb1f96486cd2000059a49ad9c7a80e432ebbb96ba3` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/storage.log) |
| evidence/runs/cpu-01/summary.json | 1373 | `b42f2b3108c919b8ca2213d5174349421c3f2bd4afeef55ad36aa169a204ef56` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/summary.json) |
| evidence/runs/cpu-01/version.log | 32 | `edff16c1721dd4ae989cadf29a01f574ae8d51b118221f664725bd6980bbba5d` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-01/version.log) |
| evidence/runs/cpu-02/embedded.tscn.txt | 5952 | `ada4c5ca53bc9e121f7c2bfcf85fc23c5e57064092b8567397103322a07204d3` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/embedded.tscn.txt) |
| evidence/runs/cpu-02/external.tscn.txt | 281 | `8821f41e27d79812f2fb4ea0feb444d7d513d04596340f294b562f58b073dd74` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/external.tscn.txt) |
| evidence/runs/cpu-02/fresh_reopen.log | 523 | `bb68e2ff0b07aca841166e56ae2544b6b56aa4266d58620a8b5f4885a2a350aa` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/fresh_reopen.log) |
| evidence/runs/cpu-02/import.log | 2415 | `dcc96b9c1a45e16def4cf393ba5a848080aa98fc092c4f06ca029d241fc84e3f` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/import.log) |
| evidence/runs/cpu-02/mapping.log | 633 | `4ccf603303530dc768fc23c5885bb8bafdadadaad147f2a99be1ffd579d431bc` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/mapping.log) |
| evidence/runs/cpu-02/storage.json | 3078 | `a24e20e77b13f7d02ada3d665895d4d0b0df752d6fe8030ca6cae07f08f1777d` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/storage.json) |
| evidence/runs/cpu-02/storage.log | 1676 | `291d81c80ea895641ed6c8b94c515427458fc44b41605305c3a92d121d4fd98e` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/storage.log) |
| evidence/runs/cpu-02/summary.json | 1679 | `337ff2812a33b77063b7f65ed0e9528818f48b26a959fbea0a136b3581e17945` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/summary.json) |
| evidence/runs/cpu-02/version.log | 32 | `edff16c1721dd4ae989cadf29a01f574ae8d51b118221f664725bd6980bbba5d` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/cpu-02/version.log) |
| evidence/runs/editor-01/editor_api.log | 2183 | `cabdd5225fd7d3cd7b000827d5a7c2cf1dd16c5338eff57bc78552f6d1c2d2e1` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-01/editor_api.log) |
| evidence/runs/editor-01/editor_import.log | 1695 | `94accd90b172a941ce194f8afb56cda523225afdd32e8bd0a8899b61c6cfd71c` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-01/editor_import.log) |
| evidence/runs/editor-01/embedded.tscn.txt | 6029 | `93a0029b39810ec008b3c507cdc62a57b38393bc299fbb41ed4c6e59c0e29a87` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-01/embedded.tscn.txt) |
| evidence/runs/editor-01/summary.json | 825 | `8a6b4a363a57494fc7b8e1257ee24b3d146ca8a885f1a538fd1efe4e2ca69231` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-01/summary.json) |
| evidence/runs/editor-02/editor_api.log | 553 | `1dc136f9c9bc27ad050595e131114865c38f3b243fd1061a993653a7d4bde4c4` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-02/editor_api.log) |
| evidence/runs/editor-02/editor_fresh_reopen.log | 105 | `3b6d058c4aacdd9650c57ea807eca8de3bd338642a15ecb9f858c447ffb7c597` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-02/editor_fresh_reopen.log) |
| evidence/runs/editor-02/editor_import.log | 1695 | `94accd90b172a941ce194f8afb56cda523225afdd32e8bd0a8899b61c6cfd71c` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-02/editor_import.log) |
| evidence/runs/editor-02/embedded.tscn.txt | 6029 | `93a0029b39810ec008b3c507cdc62a57b38393bc299fbb41ed4c6e59c0e29a87` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-02/embedded.tscn.txt) |
| evidence/runs/editor-02/summary.json | 1208 | `09e30e6b64d0b47e1cb8a003d86e4e2b23a3ee04d7764c4fa13636fae133b2c8` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/editor-02/summary.json) |
| evidence/runs/gpu-01/forward_plus.log | 2756 | `46aa6faee9c26ff391eafd5441387d465b3c343026b92adcb35736c4f8f2c232` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/forward_plus.log) |
| evidence/runs/gpu-01/gl_compatibility.log | 1582 | `aec71761ac75285c928f705d80645f6eebe07443dcdd7b9d1ca67210460e82c0` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/gl_compatibility.log) |
| evidence/runs/gpu-01/gpu_forward_plus.json | 2737 | `a72e3cfe935aec05dfe5bc59381d250ea903e97c3a3ac1d48f4bfd8485d75900` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/gpu_forward_plus.json) |
| evidence/runs/gpu-01/gpu_forward_plus.png | 761 | `16104668ba9ab6346c10cc129c530205b730fe2e2c22e00718b0f2393b5a3afe` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/gpu_forward_plus.png) |
| evidence/runs/gpu-01/gpu_gl_compatibility.json | 2723 | `de0a1a064b9b4d6154b76bcd6309fbba4affee34802170d401272c997c48a63a` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/gpu_gl_compatibility.json) |
| evidence/runs/gpu-01/gpu_gl_compatibility.png | 885 | `fde5c2bcaae5ab532d0f970e06df83795ce2cb8bb8f307c682ccb3aed43aaf98` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/gpu_gl_compatibility.png) |
| evidence/runs/gpu-01/gpu_mask.png | 88 | `d58e208ca250cd13cfe0272ced9e5c6f4c4a4b4f24cac2679afef6655deac5a6` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/gpu_mask.png) |
| evidence/runs/gpu-01/gpu_mobile.json | 2731 | `f0f50a9c34699930faccdaf87fc8a48e78885efbe55b5954843849436ff2e96f` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/gpu_mobile.json) |
| evidence/runs/gpu-01/gpu_mobile.png | 761 | `16104668ba9ab6346c10cc129c530205b730fe2e2c22e00718b0f2393b5a3afe` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/gpu_mobile.png) |
| evidence/runs/gpu-01/mobile.log | 1566 | `a003ca1e8562c06c72d3a3256265003f7b2d99ebb9171eac2afc155754737ddf` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/mobile.log) |
| evidence/runs/gpu-01/summary.json | 1453 | `62f8b6c5cabe565035bb3c7687a539633157ddc5b44a48fcb50f9f7da87158be` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-01/summary.json) |
| evidence/runs/gpu-02/forward_plus.log | 1566 | `1a2babaa037c9599b3424404d9635334b68203489ff6e609bbbc778fa8c3eb66` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-02/forward_plus.log) |
| evidence/runs/gpu-02/gpu_forward_plus.json | 2737 | `a72e3cfe935aec05dfe5bc59381d250ea903e97c3a3ac1d48f4bfd8485d75900` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-02/gpu_forward_plus.json) |
| evidence/runs/gpu-02/gpu_forward_plus.png | 761 | `16104668ba9ab6346c10cc129c530205b730fe2e2c22e00718b0f2393b5a3afe` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-02/gpu_forward_plus.png) |
| evidence/runs/gpu-02/gpu_mask.png | 88 | `d58e208ca250cd13cfe0272ced9e5c6f4c4a4b4f24cac2679afef6655deac5a6` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-02/gpu_mask.png) |
| evidence/runs/gpu-02/summary.json | 621 | `6dff92eb6623749f0a182a8ee558046f9e5610a64223936b54c090e85268dc38` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-02/summary.json) |
| evidence/runs/gpu-03/forward_plus.log | 1938 | `108056be1dff9c860fa57b07e4e9f299d5f7d7483c94d45d2479a5ec22918733` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/forward_plus.log) |
| evidence/runs/gpu-03/gl_compatibility.log | 1954 | `0976fb5d257ff863a306b813d5be56c691802394fdc18d0c70adca01bad69e48` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/gl_compatibility.log) |
| evidence/runs/gpu-03/gpu_forward_plus.json | 3513 | `196c343126dfb39119fae78f50b5ebc66fcd903cbc2fd465012187e8fd5b3c65` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/gpu_forward_plus.json) |
| evidence/runs/gpu-03/gpu_forward_plus.png | 761 | `16104668ba9ab6346c10cc129c530205b730fe2e2c22e00718b0f2393b5a3afe` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/gpu_forward_plus.png) |
| evidence/runs/gpu-03/gpu_gl_compatibility.json | 3499 | `30f4d790596346154637f8d6bd35ec46c03ecbdaf259ec2603f1d5f7f48a0324` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/gpu_gl_compatibility.json) |
| evidence/runs/gpu-03/gpu_gl_compatibility.png | 885 | `fde5c2bcaae5ab532d0f970e06df83795ce2cb8bb8f307c682ccb3aed43aaf98` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/gpu_gl_compatibility.png) |
| evidence/runs/gpu-03/gpu_mask.png | 88 | `d58e208ca250cd13cfe0272ced9e5c6f4c4a4b4f24cac2679afef6655deac5a6` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/gpu_mask.png) |
| evidence/runs/gpu-03/gpu_mobile.json | 3507 | `c8179a72272ab352d41665d47bf09fcab67b4e48db3dbe62dc1755219f549395` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/gpu_mobile.json) |
| evidence/runs/gpu-03/gpu_mobile.png | 761 | `16104668ba9ab6346c10cc129c530205b730fe2e2c22e00718b0f2393b5a3afe` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/gpu_mobile.png) |
| evidence/runs/gpu-03/mobile.log | 1938 | `49c3a4d1e1e8e73c7c8dee67453b84fcde69f446606288e6a56edc3f54d211d6` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/mobile.log) |
| evidence/runs/gpu-03/summary.json | 1455 | `ade032515bc232284ebe0153e5c76cf3dafb1ac43d066c2220d85f7f0c177453` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-03/summary.json) |
| evidence/runs/gpu-04/facade_forward_plus.tres.txt | 873 | `1f9698d95fc7228b140229d597f916b7c6a6c5ce20fd7eda229d02e32d96453b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/facade_forward_plus.tres.txt) |
| evidence/runs/gpu-04/facade_fresh_process.log | 188 | `ee618c1930058ae2fb34089eb32dc0c5a97af769fea337433149e23d8c816593` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/facade_fresh_process.log) |
| evidence/runs/gpu-04/facade_gl_compatibility.tres.txt | 873 | `6ca4eaf7ff9b71896c25b78a0b80fbb4a927ac8f4e0895e8e9d594e7308538df` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/facade_gl_compatibility.tres.txt) |
| evidence/runs/gpu-04/facade_mobile.tres.txt | 873 | `f590871d05ef11f8376802cd1198a46546c97faabb943efc339fc650583f8c8a` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/facade_mobile.tres.txt) |
| evidence/runs/gpu-04/forward_plus.log | 1974 | `9781cbf13af6d79b460f9a23d3fe52a4955bd1febbf3ca551020df0e68d76dd0` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/forward_plus.log) |
| evidence/runs/gpu-04/gl_compatibility.log | 1990 | `9c84a2928ae0e015843c98001036bf0a0d86e11ea7d85160f8758ad9bc59edfa` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/gl_compatibility.log) |
| evidence/runs/gpu-04/gpu_forward_plus.json | 3615 | `2e46370d97dacc4ae64b75db1cce847d97ac35d03152893d4f8ec03d309d9182` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/gpu_forward_plus.json) |
| evidence/runs/gpu-04/gpu_forward_plus.png | 761 | `16104668ba9ab6346c10cc129c530205b730fe2e2c22e00718b0f2393b5a3afe` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/gpu_forward_plus.png) |
| evidence/runs/gpu-04/gpu_gl_compatibility.json | 3601 | `c904777ebac9d7ac85ff448348306225dcb83aa20586bde1c74aff54a9346b2b` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/gpu_gl_compatibility.json) |
| evidence/runs/gpu-04/gpu_gl_compatibility.png | 885 | `fde5c2bcaae5ab532d0f970e06df83795ce2cb8bb8f307c682ccb3aed43aaf98` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/gpu_gl_compatibility.png) |
| evidence/runs/gpu-04/gpu_mask.png | 88 | `d58e208ca250cd13cfe0272ced9e5c6f4c4a4b4f24cac2679afef6655deac5a6` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/gpu_mask.png) |
| evidence/runs/gpu-04/gpu_mobile.json | 3609 | `9df3aecc036db79a5ee6627ac0599633cb5c02acf32a0e558595128871298c6d` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/gpu_mobile.json) |
| evidence/runs/gpu-04/gpu_mobile.png | 761 | `16104668ba9ab6346c10cc129c530205b730fe2e2c22e00718b0f2393b5a3afe` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/gpu_mobile.png) |
| evidence/runs/gpu-04/mobile.log | 1974 | `6936972af9366de5731bf09ecb9ce7c721e120e4483f4ed0646e72a6e7bece61` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/mobile.log) |
| evidence/runs/gpu-04/summary.json | 1775 | `a9e050033c434d77fdfc84846412115d2cf3687d25b8074392e44b780e96f678` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/runs/gpu-04/summary.json) |
| evidence/source_identity.json | 18215 | `6fecf9a62c8b8936b5e81d44a619b26e3496384cb539f382c7e5d5a9ea23256f` | [Открыть](https://github.com/alekseypilishkov-gif/go_flora/blob/afeae8b50e581639f4d86b65340da78c9dcb3545/stages/03_surface_material_painting/03_00_architecture/evidence/source_identity.json) |

## Источники и пределы сводки

Основа — исходные research-документы, сохранённые probe summaries/logs/manifests, Git commit, история этого чата и GitHub/Drive metadata, проверенные 30.10.2026. CONFIRMED, INFERRED и NOT_RUN внутри документов сохранены. Внешние PR прошлых этапов используются как контекст; они не объявляются реализацией этого чата.
