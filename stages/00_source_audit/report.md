# GO_FLORA — отчёт STAGE 00

Дата: **14 октября 2026**, Asia/Yekaterinburg. [Issue #1](https://github.com/alekseypilishkov-gif/go_flora/issues/1). Ветка: `codex/stage-00-foundation`. Этап: исследования, аудит источников/лицензий, архитектура и изолированные пробы. Полноценный генератор и Foliage Painter не реализованы; Stage 01 не начат; релиз и слияние не выполняются.

## Окружение и подтверждённые результаты

- Пустой публичный репозиторий/default `main` перепроверен. Минимальный bootstrap: [`6c79285`](https://github.com/alekseypilishkov-gif/go_flora/commit/6c79285) — README, .gitignore, CONTRIBUTING и AGENTS. Результаты этапа находятся в отдельной ветке. Окончательные ссылки на commit и PR добавляются при закрытии этапа.
- Godot фактически сообщает `4.7.2.stable.official.ed1daf0bf`; Windows 11 AMD64. Python 3.12.14, Git 2.55.0.windows.3. GPU: NVIDIA GeForce RTX 5060 Ti; OpenGL 3.3 / Vulkan 1.4.351. Предлагаем зафиксировать **Godot 4.7.2** как начальную проверенную версию; поддержка остальных версий пока не заявлена.
- Visual Studio Community 2022 установлена, но компонент C++ не найден через vswhere; cl.exe также не найден. SCons отсутствует; CMake/Ninja/GCC/Clang/Docker/gh отсутствуют на PATH. Проверка SCons — **FAIL**. Сборка исходного Tree3D — **NOT_RUN** с инструкцией воспроизведения; системные установки не выполнялись.
- Tree3D tag v1.1.0 закреплён на `dfe70274f5fe2a4845f1937fab524f7ee8f2c532`, исследованный main — `e9ec657b0ee3667ac11dddad6133d52274c656f7`. Прочитаны C++ API, производство mesh, Proctree, материалы/коллизии/lifecycle, SConstruct, workflow и история релизов.
- Локальный Tree3D_1.1.zip найден; SHA-256 совпал с Issue: `0d27c9673bd664a2b4a3d17d426f27142e8a1b78c49b72b9f66a806477c4cd72`. Официальный addon v1.1.0 скачан и сверён: `fb12f381ec19d1e9eb6339f8df85da474e9255ba0f86e5251df5d4599cc1b42d`. Все 22 общих addon-файла, включая бинарники, совпадают побайтно; ZIP-контейнеры и дополнительные файлы различаются.

## Реальные пробы и границы выводов

| Проверка | Статус | Что действительно проверено / что осталось |
| --- | --- | --- |
| EditorPlugin и 3D input | PASS / NOT_RUN | Plugin загрузился в headless editor; синтетический прямой вызов callback с camera ray попал в collision PlaneMesh. Настоящая доставка мыши из editor viewport **NOT_RUN** |
| Raycast поверхности | PASS | Physics ray попал в коллизию, созданную из PlaneMesh; точка и нормаль проверены |
| Две соседние MultiMesh-ячейки | PASS | 4 transform, независимое переключение node visibility в обе стороны. GPU culling/большие сцены **NOT_RUN** |
| Логические записи, undo/redo | PASS | Do/undo/redo данных и отдельно EditorUndoRedoManager; PackedScene сохранён; другой процесс Godot заново загрузил ID, seed, transform, normal, cell |
| Собственная alpha-карта | PASS | PNG/WebP alpha, atlas region, pivot у земли, материал и сохранение ресурса |
| Alpha-scissor: Compatibility/Mobile/Forward+ | PASS | Реальные viewport-пиксели, не headless анализ |
| Alpha-hash: Vulkan Mobile/Forward+ | PASS | На настольном GPU; это не проверка мобильного устройства |
| Alpha-hash: Compatibility | **FAIL** | Прозрачная часть дала чёрный RGBA=0 вместо ожидаемого красного фона; сохранены лог и screenshot |
| Tree3D import/extract | PASS | Официальный неизменённый Windows x86_64 debug addon загрузился; два ordinary Mesh (2182/1792 vertices) скопированы, сохранены и назначены MultiMesh после освобождения Tree3D |
| Tree3D native build | **NOT_RUN** | Нет SCons/C++ toolchain/godot-cpp; это не успешная компиляция |
| Tree3D wind/material/collision/lifecycle/export | **NOT_RUN** | Пробы извлечения не доказывают внешний вид, передачу материалов, коллизии или повторные scene-switch/export |
| Linux/macOS/Web и другие Godot | **NOT_RUN** | Поддержка upstream не равна проверке GO_FLORA |
| Обновление draw distance уже размещённых растений | **NOT_RUN** | Контракт спроектирован в ADR; полноценный subsystem намеренно отсутствует |

Начальные sandbox-прогоны были **FAIL** из-за служебных каталогов Godot; ошибки не скрыты. Повтор с portable копией и локальным профилем прошёл. Устранена утечка UndoRedo в тестовом скрипте. [История команд/ошибок](evidence/command_history.md), [результаты по случаям](evidence/results.json), [окружение](evidence/environment.json), [сырые логи](evidence/logs/runtime.log), [инструкции воспроизведения](evidence/README.md).

## Выводы аудита и архитектура

В Tree3D нет публичного bake/get_mesh API, но runtime подтвердил извлечение ordinary Mesh из внутренних MeshInstance3D без изменения C++. Материалы хранятся в surface override дочерних узлов и требуют отдельного захвата. Accurate collision охватывает ствол/ветви; код для twig collision закомментирован. Это результаты анализа исходников, а не успешные тесты коллизий.

Tag v1.1.0 не совпадает с main: release ZIP содержит tier shaders, отсутствующие в tagged source; Proctree также различается. Descriptor и в локальном, и в официальном ZIP сообщает `version = v1.0`. **Соответствие бинарников точному исходнику/build toolchain остаётся UNVERIFIED**, несмотря на подтверждённое равенство локального и официального binary payload. Индивидуальная лицензия demo textures/assets тоже **UNVERIFIED**. MIT Tree3D и BSD-style Proctree рассмотрены отдельно; ничего стороннего не перераспространяется.

Рекомендация [ADR 0001](../../docs/ARCHITECTURE_ADR_0001.md): GDScript EditorPlugin/core + независимые необязательные providers, Tree3D отдельно. Альтернатива C++-центричной архитектуры рассмотрена по переносимости, сборке, упаковке, поддержке и UX. Источник истины — versioned logical InstanceRecord; MultiMesh — перестраиваемый cache. Undo/Reapply работают с ID/seed/данными. Batch key включает set, mesh/material/LOD и spatial cell. Culling/draw distance применяются на уровне ячейки; per-instance MultiMesh culling не обещается. PackedScene с gameplay сохраняется через fallback. Изменения set должны распространяться по индексу существующих batches; fade по умолчанию отключён. Для alpha-карт предлагаем scissor, hash в Compatibility не принимать без дополнительной проверки.

[Матрица конкурентов](competitor_matrix.md) покрывает UE, Spatial Gardener, Terrain3D Instancer, ProtonScatter, TerraBrush, FoliageFlow и MultiMesh+. Implementation inspection, author claims, planned и unknown разделены. Их runtime/performance не тестировались; GitHub ProtonScatter является зеркалом Codeberg, актуальность зеркала относительно canonical head не подтверждена.

## Приёмка и решения владельца

Обязательные документы подготовлены: [vision](../../docs/PRODUCT_VISION.md), [ADR](../../docs/ARCHITECTURE_ADR_0001.md), [лицензии](../../docs/LICENSING_DECISION.md), [roadmap](../../docs/ROADMAP.md), [аудит Tree3D](tree3d_source_audit.md), матрица, evidence и [узкий proposal Stage 01](next_stage_01_proposal.md). Production addon отсутствует; downloads/build caches/.godot/binaries исключены из Git. Базовый процесс: stage branch → проверки → commit → PR → review владельца, без auto-merge/release. CI выполняет только статические проверки репозитория и не выдаёт их за runtime.

Завершающие Git/PR/CI результаты фиксируются после публикации PR. Приёмка аудита допускает честные FAIL/NOT_RUN; она не означает готовность продукта.

Требуется утверждение владельца:

1. Принять архитектуру A и Godot 4.7.2 как начальную версию.
2. Принять MIT для собственного GO_FLORA или выбрать другую лицензию; сейчас решение PENDING и LICENSE не создан.
3. Согласовать отдельный optional Tree3D provider; разрешение на derivative code/бинарную поставку вынести на Stage 03 после notices/provenance review.
4. Принять alpha-scissor по умолчанию и ограничения hash/fade; выполнить/назначить ручную viewport-проверку.
5. Утвердить узкий Stage 01 proposal отдельным заданием; данный PR не разрешает начать следующий этап.

После STAGE 00 работа останавливается для review владельца.
