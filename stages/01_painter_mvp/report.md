# GO_FLORA — STAGE 01: Foliage Painter MVP

Дата: 2026-10-14. Итог: **READY_FOR_MANUAL_QA**. **INTERACTIVE_GUI_QA: NOT_RUN**.

Реализован начальный устанавливаемый GDScript Foliage Painter по [Issue #3](https://github.com/alekseypilishkov-gif/go_flora/issues/3). Автоматические проверки выполнены в настоящих процессах Godot; интерактивную приёмку мышью владелец оставил себе. Этап останавливается на отдельном PR, без merge, релиза и Stage 02.

## Основание и границы

Ветка `codex/stage-01-painter-mvp` создана от актуального `main` — `8cbac98f0705a16f5746baa07f37ec2b2bae75b6`, принятого Stage 00 / [PR #2](https://github.com/alekseypilishkov-gif/go_flora/pull/2). [ADR 0001](../../docs/ARCHITECTURE_ADR_0001.md) отмечен ACCEPTED ADR A со ссылкой на решение владельца. Все файлы `stages/00_source_audit/` сохранены без изменений.

Реализация находится в `addons/go_flora/`, тесты — `tests/`, результаты и оригинальная демонстрация — только в этом stage-каталоге. Собственный код, документация, сцена и материалы — MIT; addon содержит полную копию корневой лицензии. Отдельные условия сторонних компонентов в [licensing inventory](../../docs/LICENSING_DECISION.md) сохранены. Tree3D, конкурентный код, внешние модели/текстуры и native библиотеки не включены.

## Реализация

- Типизированные Resource: static `GFVegetationSource`, weighted `GFVegetationSet`/`GFPaletteEntry`, versioned `GFVegetationLayerData`/`GFInstanceRecord`, `GFBrush`. Источники сцен/генераторов и отсутствующие Mesh диагностируются без потери записей.
- Авторитетные logical records хранят стабильные ID source/set/layer/stroke, schema, resolved revision, local transform/normal, seed/candidate/cell/flags/algorithm/target. Рендер и курсор — disposable internal caches, не сохранённые MultiMesh slots или authored nodes.
- SHA-256 counter RNG с независимыми purpose для выбора source, radius/angle/yaw/scale. Пространственная дискретизация пути зависит от world length, а не частоты кадров/events. Rejected candidates не сдвигают последующие случайные решения. Все samples и stamps имеют budget.
- Dock с layer/set, native Mesh-превью, Navigate/Paint/Erase/Single, controls brush radius/density/spacing/seed/yaw/scale/normal/slope/world-or-layer-height/mask/ray/budget, include/exclude selected collider. Настоящий `_forward_3d_gui_input` использует editor Camera3D и Godot Physics raycast; hover ring и pending preview не меняют persistent records.
- Завершённый stroke — один scene-bound EditorUndoRedoManager action с record deltas и serial. Esc, смена сцены/слоя/режима, disable, смена трансформации/data слоя, потеря фокуса и release вне 3D отменяют pending state. Часть этих путей проверена через API; физические действия остаются manual QA.
- MultiMesh batches сгруппированы по layer/set/local XZ cell/source/revision/Mesh/effective materials. Negative cells используют floor, transforms и AABB локальны для batch. Draw distance обновляет **те же существующие** узлы выбранного набора, другой набор и logical records не меняются; 0 — unlimited, fade OFF.
- Scene persistence и runtime используют обычные @tool data/layer/render scripts без зависимости от EditorPlugin. Отдельные colliders для растений, LOD, ветер, импорт GLB/сцен, генераторы, Select/Lasso/Reapply не реализованы.

Точный текущий контракт и отличия от будущих ADR-предложений: [STAGE_01_DATA_CONTRACTS.md](../../docs/STAGE_01_DATA_CONTRACTS.md). Установка: [addon README](../../addons/go_flora/README.md). Демонстрация: [demo README](demo/README.md), две разноцветные primitive Mesh, два независимых набора, Ground, rotated/scaled collider surface и отдельная visual-only surface.

## Окружение и команды

Фактически выполнено на Windows 11 Pro `10.0.26200`, x86_64, Intel Core i5-13400F (10 cores / 16 logical), ~32 GiB RAM, NVIDIA GeForce RTX 5060 Ti / driver `32.0.16.1656`. [Hardware capture](evidence/hardware.json). В headless-замерах display driver=`headless`; графическая производительность GPU не измерялась.

Engine: **`4.7.2.stable.official.ed1daf0bf`**, полный engine commit `ed1daf0bf001b61586d9930840f2f1394092c079`. Исполняемый файл — локальная portable-копия установленного Godot; SHA-256 `ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424`. Приложение GUI действительно запущено с Compatibility/OpenGL 3.3 NVIDIA 616.56 и включённым addon; [startup log](evidence/editor_gui_startup.log) подтверждает только запуск.

Из корня репозитория:

```text
python tools/prepare_stage01.py
python tools/run_stage01_tests.py --godot .scratch/godot-portable/godot.exe
python tools/verify_repository.py
python stages/00_source_audit/evidence/whitespace_probe.py
git diff --check
git diff --cached --check
git diff --check origin/main...HEAD
```

Локально Python — bundled runtime Codex. Точные absolute commands и exit codes каждого Godot subprocess: [commands.json](evidence/commands.json). Runner создаёт отдельные ignored test/editor project copies; авторская demo-сцена и ручная работа владельца не перезаписываются. Для импорта используется `--headless --editor --import`, ожидающий окончания scan/import; тесты не выдают ранний quit за завершённый import.

## Матрица проверки

| Область | Статус | Фактическое доказательство / предел |
| --- | --- | --- |
| Source/contracts/repository structure | PASS | Реализация ADR A, изолированные stage outputs, MIT и отсутствие distributed native/art dependencies; static gate отдельно от Godot |
| Engine identity / actual addon import | PASS | Version subprocess и завершённый настоящий headless Editor import с marker `GO_FLORA_PLUGIN_ENABLED`, без parse/errors |
| Deterministic core | PASS | 45 assertions: same seed/path, event-rate-independent spacing, different seed, rejection stability, invalid inputs, budgets, Single target exit/reentry, unambiguous set/source ID pairs; weighted sample 760 cone / 264 box из 1 024 при 3:1 |
| Actual physics / transforms | PASS | Ground и rotated/scaled collider raycasts, no-collision mesh, mask/slope/world-height/layer-height/include/exclude, nonuniform layer math и нормали |
| Logical deltas / native scene histories | PASS | Core paint/erase/single/cancel; 17 headless native Editor API checks, реальные scene history A/B, один undo для multi-sample Paint и Erase, точные ID/order при redo/undo |
| Scene round trip | PASS | Core сохраняет сцену, процесс заканчивается; отдельный свежий процесс открывает её, сравнивает IDs/count/seed/set/schema/revision/target/cells/serial/transform/normal с допуском 1e-5; один rebuilt cache |
| Set distance / material ownership API | PASS | Без repaint: все существующие A batch nodes получают 12 м, B не меняется, snapshot logical records прежний; затем 0 unlimited. Cells видимы независимо. Material override не мутирует оригинал |
| Missing/unsupported/future schema | PASS | Records остаются сохранены, actionable diagnostics; future schema suppresses rendering и запрещает редактирование, не очищая data |
| Lifecycle / repeated operations via API | PASS | Реальный Editor disable/enable; сохраняются records и cache; 30 undo/rebuild циклов без duplicate records/node growth; focus/release cancellation direct API, без физических событий |
| Native visible GUI startup | PASS | Открытый реальный Godot, Compatibility GPU log, addon marker; взаимодействие и видимый результат рисования этим не проверены |
| INTERACTIVE_GUI_QA / visual set-distance / actual editor close-reopen | NOT_RUN | Владелец выполняет [manual_qa.md](manual_qa.md); синтетические callbacks и headless API не подтверждают mouse workflow |
| CPU cache construction benchmark | PASS | Реально построенные 1 024 и 5 000 records, counts/timings ниже; не FPS |
| GPU/FPS / large forest / clean-machine install/export / other GUI platforms | NOT_RUN | Такие проверки не выполнены, широкая совместимость не заявлена |
| GitHub Actions | NOT_RUN до публикации PR | Два workflow подготовлены; актуальный CI результат и ссылки будут зафиксированы после push |

Все автоматические final Godot subprocess завершились с exit=0. Raw logs, machine-readable assertions и fingerprints входных scripts/scene: [evidence index](evidence/README.md), [results.json](evidence/results.json). Source analysis отдельно от runtime. Наблюдённый первоначальный parse FAIL исправлен без ослабления теста; прочие фактические ошибки среды перечислены в [development_failures.md](evidence/development_failures.md). Исторический Stage 00 alpha-hash Compatibility FAIL сохранён; alpha cards вне этого этапа.

## Производительность

Последний зафиксированный Windows прогон, один замер на размер, `Time.get_ticks_usec()` вокруг `rebuild_now()`. Записи подготовлены до начала таймера, cell size=8, обе static Mesh разновидности одного weighted set, grid X=0…99; измеряется создание render cache/MultiMeshes/AABB. Число nodes включает layer + cache root + batches, без demo/harness/editor. Режим `headless`, rendering method string=`gl_compatibility`.

| Persistent records | Spatial/source batches | Nodes | CPU rebuild |
| --- | --- | --- | --- |
| 1 024 | 51 | 53 | 8,131 мс |
| 5 000 | 182 | 184 | 42,736 мс |

Это не среднее/percentile, не GPU render и не обещание FPS. В MVP record/topology changes coalesce один полный cache rebuild на frame; incremental dirty cells и масштабное профилирование оставлены последующим этапам. Erase ограничивает также просмотренные records; default budget 2 000, max 20 000. Для больших слоёв возможно достижение budget до конца списка; это явно показано в dock и руководстве.

## Ручная приёмка и остановка

Windows Computer Use попытался получить управление Godot и вернул **FAIL: `Computer Use app approval timed out`**. Ни mouse strokes, ни скриншоты/видео не были выполнены. Владелец выбрал **«Оставить GUI-приёмку мне»**. Поэтому продуктовая приёмка — **READY_FOR_MANUAL_QA**, обязательные GUI-шаги — **NOT_RUN**; общего PASS этапу не присвоено.

Владельцу нужно пройти Paint/Erase/Single, navigation/Esc/pending scene switch, реальный save/close/reopen, enable/disable и видимую дальность A/B на двух расстояниях по [manual QA](manual_qa.md). Опциональный read-only EditorScript позволяет снять ID/transform/batch-settings до/после этих настоящих действий. После этого владелец принимает workflow и решает о merge PR. Других новых решений о лицензиях или интеграциях этот этап не запрашивает.

PR и implementation commit будут внесены после публикации ветки; база уже зафиксирована выше, точные проверенные source fingerprints — в results.json. **Не выполнять auto-merge, не публиковать release, не начинать Stage 02.**
