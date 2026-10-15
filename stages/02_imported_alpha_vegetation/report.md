# GO_FLORA — STAGE 02: Imported Assets & Alpha Vegetation

Дата: 2026-10-15. Addon: **0.2.0-dev**. Итог: **READY_FOR_MANUAL_QA**. **INTERACTIVE_GUI_QA: NOT_RUN**.

Реализация выполнена по полностью прочитанному [Issue #5](https://github.com/alekseypilishkov-gif/go_flora/issues/5), без комментариев на момент начала. Ветка `codex/stage-02-imported-alpha` создана от актуального принятого `main`, `5c076153e1dea6363b885e82f4ef391808586348`. [ADR A](../../docs/ARCHITECTURE_ADR_0001.md) сохранён. Stage 03, merge и релиз не выполнялись. Предыдущие stage-каталоги и исходные Stage 01 tests не изменены. Рабочий **C:/Dev/TEST_FLORA не читался и не изменялся**; отдельный Blender-проект не использовался.

## Что реализовано

**Собственные модели.** Dock-действие Add Mesh / GLB / Scene сохраняет переиспользуемый Source `.tres` и добавляет его в выбранную палитру с Undo/Redo. Resolver возвращает typed status, diagnostics, references, provider/revision, capabilities и полный список static parts. Настоящий GLB проходит импорт Godot; сохраняются все mesh-части/поверхности, исходные UV/нормали/тангенты, накопленные transform/pivot, bounds и приоритет Material Override → Surface Override → mesh material. Производные Mesh/material bindings принадлежат addon; оригиналы не изменяются.

**Трава/цветы из текстуры.** Create Alpha Plant принимает project PNG/WebP, показывает UV-preview и позволяет выбрать single, crossed или radial 3–4 cards, ширину, вертикальную высоту, splay, threshold, atlas X/Y/W/H в пикселях и inward gutter. Сохраняется редактируемый resource, пригодный для разных VegetationSets. Геометрия детерминирована и кэшируется, pivot Y=0; используются normals/tangents/UV, vertex colors не заполняются. Материал double-sided alpha-scissor, threshold=0,5, clamp, linear-with-mipmaps. Alpha-hash не предлагается: исторический Compatibility FAIL остаётся известным ограничением.

**Сцены с поведением.** Classifier читает SceneState без создания узлов; неизвестные Node scripts не исполняются ради превью. Скрипты, сигналы, группы, коллайдеры и неизвестные свойства нельзя молча отбросить. Для узкого allowlist есть явный opt-in с рассмотренным fingerprint сцены/зависимостей. В редакторе это инертное mesh-превью; в runtime — реальные instances с authored script/ready/process/signal/group/collider. Живые экземпляры сохраняются при перестройке static cache. Дальность/enabled скрывают только geometry и не останавливают gameplay/physics. Изменение файла требует нового review; неподдерживаемые animation/skin/skeleton/blend shapes/lights/particles/tool scripts/nested/inherited scenes остаются заблокированы с причиной. Это не универсальная поддержка произвольных игровых сцен и не sandbox загрузчика ресурсов Godot.

**Сохранность размещений.** Record/layer schema=1, старые numeric enum 0/1/2, IDs, RNG, transforms и palette semantics сохранены. Новые виды добавлены как 3/4; старые unsupported значения не переосмысляются. Одна запись даёт несколько batches либо управляемую сцену. Paint/Erase/Single, preview/cancel и scene-bound Undo/Redo используют прежние logical deltas. Источник/reimport изменяет производный кэш, не генерирует позиции заново. Missing/invalid/future data сохраняют записи и выводят диагностику.

**Интерфейс и дальность.** Draw distance (m) остаётся непосредственно под набором; 0=unlimited, set B независим. Обновляются существующие части импортированных моделей, карточек и fallback geometry; IDs/count/transforms прежние. Static MultiMesh culling действует на ячейку. Scroll dock сохраняет принятый минимум 260×120 px/default slot, saved local layout не переписывается. Native Control regression выполнен отдельно от ручного GUI.

Подробности: [контракты](../../docs/STAGE_02_SOURCE_CONTRACTS.md), [руководство addon](../../addons/go_flora/README.md).

## Автоматическая проверка и реальные GPU-кадры

Engine **4.7.2.stable.official.ed1daf0bf**, полный commit `ed1daf0bf001b61586d9930840f2f1394092c079`. SHA-256 фактически запущенного Windows x86_64 executable: `ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424`. GPU: **NVIDIA GeForce RTX 5060 Ti**, Compatibility OpenGL 3.3 / NVIDIA 616.56 и Vulkan Mobile/Forward+. Headless timers — CPU cache construction, без GPU/FPS выводов.

| Проверка | Итог / предел |
| --- | --- |
| Stage 01 regression до изменений и последним native suite | PASS: исходные tests не ослаблялись; core, fresh process и native Editor API |
| Frozen сцена, сохранённая старым Stage 01 до изменений | PASS: IDs/count/source/set/seed/transforms и batches прежние, tolerance 1e-5 |
| Настоящий оригинальный GLB | PASS: 2 mesh-части, 3 поверхности/материала, вложенные nonuniform transforms, UV/normals/tangents/bounds, immutability |
| Static PackedScene и reviewed authored scene | PASS: корректные overrides; runtime script/signal/group/physics; lifecycle при rebuild; визуальное скрытие не выключает gameplay |
| Cards / PNG / WebP / atlas | PASS: 1/2/3/4 cards, normals/winding/tangents, ground pivot/vertical height/splay, atlas UV и отказ неверных regions/gutters |
| Каждый source kind в Painter/Editor API | PASS: preview/cancel/Single/Erase/native history/distance, один record → все части, новая source `.tres` и palette Undo/Redo |
| Настоящий PNG и GLB file reimport | PASS: изменённый content/revision, новый cache, прежние record ID/transform |
| Missing files / future schema / corrupt coordinates / unsupported features | PASS: точные diagnostics, записи сохраняются; неизвестный @tool Node script не запускался |
| Реальный alpha-scissor GPU pixel test | PASS: **18** случаев (PNG/WebP × 3/12/24 м × 3 backends); transparent texels раскрывают известный фон; mipmaps=true, atlas gutter=8 px |
| Runtime demo screenshot | PASS: 137 logical placements, GLB + PNG/WebP grass/flowers/atlas; настоящее GPU rendering, без mouse acceptance |
| Plugin-only ZIP | PASS: CRC/SHA каждого файла, побитовый rebuild, 3 установки и backup; SHA обеих QA-сцен/config/layout прежние; path traversal отвергнут |
| Standalone disposable import/runtime | PASS: Stage 02 demo и копия существующей Stage 01 сцены |
| INTERACTIVE_GUI_QA | **NOT_RUN**: обязательная [ручная приёмка владельца](manual_qa.md) до merge |
| Clean export / новая машина / другие GPU / large-forest FPS | NOT_RUN |

Машиночитаемые итоги, числа assertions и CPU/memory timings: [results.json](evidence/results.json). Точные команды/exit codes, исходные hashes, raw logs, backend/hardware metadata и снимки: [evidence](evidence/README.md). Реальные runtime-кадры: [общий](evidence/screenshots/demo_gpu.png), [крупный план](evidence/screenshots/demo_gpu_close.png). Это не скриншоты интерактивной работы мышью.

## Производительность и границы

Выполнены по одному CPU-замеру для **1 000 / 5 000 records** crossed cards и импортированного GLB (соответственно 2 000 / 10 000 part instances). Записи подготовлены до таймера, `rebuild_now()` измеряет cache/MultiMesh/AABB construction; static memory delta также записана. Конкретные миллисекунды/число batches — в results.json. Это не среднее/percentile и не обещание FPS. Source classification ограничен 256 узлами; work budget brush сохранён. Incremental dirty cells, LOD, ветер и большой лес не реализованы.

Поддержка fallback намеренно ограничена рассмотренным примером и allowlist. При удалении/замене source node освобождается, произвольное script runtime state не сохраняется. В editor preview нет authored collisions. Для альфа-атласа нужен подготовленный gutter; mipmaps пользователь включает в Import, глобальные settings addon не меняет. Pixel tests не гарантируют отсутствие bleeding на любых исходниках/расстояниях. Новый install не меняет project.godot, plugin нужно включить вручную.

## Пакет, ошибки разработки и остановка

Локальный ZIP **0.2.0-dev** и adjacent manifest/SHA находятся в `stages/02_imported_alpha_vegetation/.scratch/packages/`; точное имя/content digest — в [package manifest](evidence/package_manifest.json). Архив содержит только addon + MIT, без demo/fixtures/tests/Tree3D/native dependencies. Используется воспроизводимый ZIP_STORED с сортировкой, фиксированной датой/permissions. Исходные и демонстрационные ассеты оригинальные MIT; сторонние условия из licensing inventory не изменены.

Для необязательного ручного обновления: сохранить сцены, закрыть Godot, проверить SHA ZIP, вызвать `tools/install_stage02.py --project <выбранный проект> --archive <ZIP>`. Скрипт сохраняет предыдущий addon в timestamped `.scratch/go_flora_updates/.../previous/go_flora`, меняет только addon и не пишет scenes/config/layout. Во время разработки он запускался только на disposable project. TEST_FLORA не устанавливался автоматически.

Разработка содержала реальные FAIL: warning-as-error в тесте; ArrayMesh-only метод на BoxMesh; зависшие early tests после script error; сравнение transform без допуска сериализации; `_process` до нужного frame; первый demo save без `.scratch`; неверное имя свойства AcceptDialog и конфликт двух exclusive dialogs в одном frame. Исправлены тип/API guard, раннее завершение ошибочного probe, tolerance 1e-5 (как Stage 01), ожидание трёх frames при том же требовании ticks>before, output directory, `dialog_hide_on_ok` и явное hide перед deferred free окна. Failure logs сохранены; финальные PASS их не заменяют. Начальный git fetch не прошёл ограничение записи `.git`; разрешённый fetch/создание ветки затем выполнены успешно.

В исходной рабочей папке был один чужой untracked WebP (141 254 байта). Он не читался как изображение, не добавлялся в PR, не перемещался и не удалялся. Поэтому буквальный gate «полностью пустой git status» ограничен этим ранее существовавшим файлом; изменения Stage 02 должны быть полностью committed/pushed. Итоги whitespace/repository/PR-base gates и CI фиксируются в отдельном evidence после commit/push.

Работа останавливается на **одном PR к main** и этом отчёте для владельца. Общий PASS ручной приёмке не присвоен. Merge, release и Stage 03 не выполняются.

## Зафиксированная поставка и PR

[Draft PR #6](https://github.com/alekseypilishkov-gif/go_flora/pull/6), `codex/stage-02-imported-alpha` → `main`. Implementation/source commit: `4186d6b0dfaad9185dac34c57b19a1d7eda9b6ce`. Проверка Git blob SHA подтвердила все файлы ZIP и **89** исходных source/fixture/test hashes; это отдельный source identity gate, не вывод из одного имени версии. Метаданные после него меняют только отчёт/evidence.

ZIP: `GO_FLORA_stage02_0.2.0-dev_a88c71c9.zip`, SHA-256 **`889d21cc229afeefc48336893928bfc77f8bdf7501870ae54e04f51345a1f664`**. [Manifest](evidence/package_manifest.json) содержит полный список и `source_commit_verified`. Локальный архив с adjacent `.json`/`.sha256` подготовлен в `.scratch/packages/` текущего этапа.

Финальные native Stage 02: **87 core assertions + 62 Editor API assertions — PASS**. Итоговый один CPU-замер (headless, без FPS):

| Источник | Records / part instances | Batches | Cache ms | Static memory delta, bytes |
| --- | --- | --- | --- | --- |
| Crossed card | 1 000 / 1 000 | 26 | 11,464 | 126 156 |
| Crossed card | 5 000 / 5 000 | 91 | 53,945 | 718 024 |
| GLB | 1 000 / 2 000 | 52 | 20,813 | 248 772 |
| GLB | 5 000 / 10 000 | 182 | 94,393 | 1 269 412 |

GitHub Actions на source commit: [repository static](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/38686977548) **PASS**, [Stage 01 native](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/38686977629) **PASS**, [Stage 02 native/package](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/38686977542) **PASS**. Это Linux headless automation, не Linux GUI/export. [CI metadata](evidence/ci_summary.json), [CI artifact](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/38686977542/artifacts/11950762113).

[Quality gates](evidence/quality_gates.json): working/staged/committed PR-base whitespace, repository validation и source identity **PASS**. Первый staged whitespace дал FAIL из-за trailing spaces в stdout Godot: readable logs нормализованы, исходные bytes/content/hash сохранены в adjacent `.raw.json`. Полный `git status` **FAIL** только из-за ранее существовавшего чужого untracked WebP; task changes committed/pushed. Ничего постороннего ради пустого status не удалялось.

**INTERACTIVE_GUI_QA: NOT_RUN; READY_FOR_MANUAL_QA.** Следующий шаг — ручная приёмка владельцем по manual_qa.md. PR остаётся draft, merge/release/Stage 03 не выполняются.

Дополнение после ручной проверки владельца: [Stage 02.1 / Issue #7 — Palette & Dock UX, 0.2.1-dev](updates/01_palette_dock_ux/report.md). Исторические результаты 0.2.0-dev выше сохранены; новая палитра, правый dock, ZIP и повторные проверки находятся только в каталоге дополнения.

Hotfix после подтверждённого владельцем конфликта окон: [Stage 02.2 / Issue #8 — Resource Picker Modal Fix, 0.2.2-dev](updates/02_resource_picker_modal_fix/report.md). Предыдущие отчёты/evidence сохранены; новый ZIP и повторные проверки находятся в отдельном каталоге обновления.
