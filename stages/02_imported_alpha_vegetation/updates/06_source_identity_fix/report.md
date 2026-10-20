# Issue #18 — Stage B: Source Identity Fix

Статус: **READY_FOR_MANUAL_QA**. Версия: **0.2.6-dev**. Godot: **4.7.2.stable.official.ed1daf0bf**.

**INTERACTIVE_GUI_QA: NOT_RUN**. Автоматические Editor API, графическое сохранение и ручная приёмка владельцем учитываются отдельно.

## Результат

Реализован согласованный Variant A — Canonical External Source. Новый Source после записи загружается из своего .tres; только успешно проверенный загруженный объект передаётся в существующий путь палитры и Inspector. Сохранённые тестовые сцены используют ExtResource, общий Source виден двум Sets и двум сценам после нового запуска процесса.

Изменения выполнены в отдельном managed worktree на ветке codex/issue-18-source-identity от проверенного main **d911087157ecaa9e3ab2b92d95049f2999aebab1**. Исходный checkout остался на codex/issue-16-warning-filter, HEAD **3d043d3ee48578501a2249c13db331b43aee9c37**. Его 2478 зафиксированных до работы файлов имеют прежние SHA-256. Fetch добавил Git-объекты/refs; содержимое исходной рабочей папки и пользовательские untracked материалы не синхронизировались. TEST_FLORA не открывался, не копировался и не изменялся в Stage B.

Основание: [задание Issue #18](https://github.com/alekseypilishkov-gif/go_flora/issues/18), [согласование владельца](https://github.com/alekseypilishkov-gif/go_flora/issues/18#issuecomment-6289589679). Идентичность базы и Stage A: [base_identity.json](evidence/base_identity.json), [owner_authorization.json](evidence/owner_authorization.json). Исторические материалы Stage A сохранены отдельно без редактирования.

## Причина и исправление

На main ResourceSaver.save(draft, path) записывал файл, но Creator испускал прежний draft с пустым resource_path. Палитра сохраняла его как самостоятельный встроенный SubResource. Совпадение display_name не объясняет эту потерю внешней идентичности; логические ID также не являются основанием для автоматического объединения объектов.

Исходная ошибка воспроизведена **до изменения production-кода**: [red-main/summary.json](evidence/runs/red-main/summary.json), [red-main/assertions.json](evidence/runs/red-main/assertions.json). FAIL фиксирует emitted_is_draft=true и пустой draft_path при наличии записанного .tres.

Изменён только путь создания:

1. source_persistence.gd проверяет нормализованный res:// путь с расширением .tres, отсутствие файла/каталога и ResourceLoader cache binding. Занятое имя отклоняется до записи; предложено новое имя или отдельное открытие существующего Source.
2. Creator фиксирует снимок PROPERTY_USAGE_STORAGE, сохраняет draft и загружает результат через CACHE_MODE_REUSE только после этой проверки свободного пути.
3. Проверяются GFVegetationSource, schema 1, resource_local_to_scene=false, точный внешний resource_path и cache binding. Сравнивается полный граф хранимых свойств: ID, kind, имена, variant, approval, transform, Mesh, материалы, AlphaCard и Texture. Внешние ассеты сравниваются по пути и классу, встроенные — по сериализуемым свойствам. Циклы/общие Resource учитываются по порядку обхода; instance ID не является сохраняемой идентичностью. Числа с плавающей точкой допускают обычную погрешность сериализации Godot.
4. Только после валидации source_saved.emit(persisted) передаёт сохранённый объект. Существующие append, Inspector и Undo/Redo используют его напрямую. Сообщение при смене сцены/Set теперь содержит путь сохранённого файла.
5. Cancel/Esc/X, ошибка записи, отказ загрузки или несовпадение полей не публикуют Source. Если файл уже записан, он остаётся на диске; сообщение содержит точный путь и причину.

Новые два приватных метода записи/загрузки нужны для детерминированных fault probes; экспортируемых настроек или публичной схемы не добавлено. Renderer, Resolver, fingerprint, Erase, render_only_sources, placement records и правила Scene Fallback не изменялись. Legacy embedded Sources не мигрируются и не объединяются по имени/ID. Существующие тесты не переписаны.

## Автоматические свидетельства

Все команды выполнялись из корня worktree. Для повторения нужен новый уникальный label: runner не перезаписывает evidence. Путь к входному Godot задаётся через --godot; Windows runner копирует бинарник и создаёт собственный portable editor_data внутри disposable каталога. Точные абсолютные команды, профили, exit codes, версия и SHA бинарника находятся в каждом summary.json.

| Проверка | Результат | Свидетельство |
|---|---|---|
| Main до исправления | FAIL, ожидаемый regression RED | [red-main](evidence/runs/red-main/summary.json) |
| Полный итоговый запуск | PASS, 31 процесс/probe, включая import/version | [all-green](evidence/runs/all-green/summary.json) |
| Новый native Editor suite | PASS, 80 assertions | [identity/results.json](evidence/runs/identity-evidence-green/identity/results.json) |
| Две сцены, новый процесс | PASS, 2 проверки, все поля и порядок records | [reopen_results.json](evidence/runs/identity-evidence-green/identity/reopen_results.json) |
| Stage 01; 02; 02.1; 02.2; 02.3 | PASS, core/reopen/native Editor harnesses | [all-green](evidence/runs/all-green/summary.json) |
| Issue #13 Diagnostics; Issue #16 Warnings | PASS, runtime и native Editor | [all-green](evidence/runs/all-green/summary.json) |
| Графический native Save As, повторный Save, reopen, thumbnail | PASS, 5 assertions | [graphics_results.json](evidence/runs/graphics-green/graphical_save/graphics_results.json) |
| Ручные мышь/навигация/Save владельца | NOT_RUN | [manual_qa.md](manual_qa.md) |

Основные команды:

~~~text
python -B tools/run_issue18_tests.py --godot <Godot-4.7.2> --label all-green --phase all
python -B tools/run_issue18_tests.py --godot <Godot-4.7.2> --label graphics-green --phase graphics
~~~

Suite покрывает Static Mesh, GLB, статическую PackedScene, PNG/WebP с нестандартными настройками карточки/материала/transform, reviewed и unreviewed сцены, HARD_UNSUPPORTED. Два одноимённых authored_plant имеют разные IDs и открываются как выбранные объекты; Diagnostics/Inspector покрыты также неизменённым Issue #13 suite. Проверены общий Source в двух Sets, ExtResource в двух сценах и правка общего .tres между сохранением и новым процессом.

Дополнительно проверены занятый файл и wrong-type .tres с неизменным SHA, cache-only путь, алиасы нормализации, недопустимые пути, Cancel/Esc/X, реальный Save Error и инъекции отказов загрузки/полей. Проверены смена layer/Set после записи, append Undo/Redo, безопасное удаление с архивом и Undo, реальные PNG/WebP/GLB reimport/restore. Ревизия сцены и недоступный ассет не сбрасывают approval и не переписывают records; устаревшее одобрение остаётся fail closed.

После итогового review facts теста изолирован Dictionary ожиданий начального сравнения от дальнейшего rename/reopen. Последний [identity-evidence-green](evidence/runs/identity-evidence-green/summary.json) повторно подтвердил 80 + 2 assertions с совпадающими snapshot facts; production addon не менялся. Предыдущие evidence сохранены.

GPU-проба использовала GL compatibility, NVIDIA GeForce RTX 5060 Ti и реальные EditorInterface.save_scene_as/save_scene. Получен [PNG thumbnail](evidence/runs/graphics-green/graphical_save/thumbnail.png), 64×64, 3225 bytes, в изолированном editor cache. Скриптовое управление редактором не заменяет ручную GUI-приёмку.

## История промежуточных результатов

| Запуск | Итог и объяснение |
|---|---|
| red-main | FAIL на исходном main: опубликован draft. |
| initial-fix | FAIL: при переносе payload повторно применены только тесты; production ещё baseline. Сбой переноса исправлен. |
| fixed-flow | PASS на начальном canonical regression после фактического применения production fix. |
| matrix-initial | FAIL теста сообщения смены Set: поздний опрос уже видел обновление Painter status. Проверка перенесена к моменту операции. |
| matrix-reimport | FAIL fixture HARD_UNSUPPORTED: in-memory PackedScene не имела пути. Fixture сохранена как отдельный asset в disposable проекте. |
| full-initial | Новый suite PASS, fresh-process FAIL из-за JSON float против schema/kind int. Исправлена нормализация двух enum/int полей в тесте. Все исторические регрессии PASS. |
| graphics-initial | PASS native Save/thumbnail; затем уточнена изоляция portable cache. |
| identity-green | PASS полный новый suite + новый процесс после исправления проверки JSON. |
| all-green / graphics-green | Финальные PASS с отдельной копией Godot и собственным editor_data. |

Ранние пробы использовали общий игнорируемый portable cache инструментария Codex: _sc_ рядом с входным Godot имел приоритет над APPDATA. Оригинальный TEST_FLORA не затрагивался. Runner исправлен на полную изоляцию binary/cache; финальные запуски выполнены заново. Все промежуточные логи сохранены в evidence/runs.

Статические quality gates: [quality-final/summary.json](evidence/runs/quality-final/summary.json). Первый запуск нашёл неверную ссылку Markdown и ограничение Windows для git show с длинным resource path; сохранены [исходный лог](evidence/runs/quality/repository.log) и [отказ scope probe](evidence/runs/quality/scope-probe-failure.json). Ссылка исправлена, сравнение защищённых файлов выполнено через pinned Git blob hashes без длинных аргументов пути. Финальные проверки прошли.

Проверка пакета: первый install-probe в глубоком stage-пути завершился FAIL из-за длины Windows path ([лог](evidence/package/package-tests.log)). В коротком disposable пути тот же неизменённый installer прошёл все шесть проверок ([summary](evidence/package-green/installation-summary.json)); installer в Stage B не исправлялся.

Первый delivery whitespace gate отклонил два сырых runtime-лога из-за пустой строки stdout в EOF ([summary](evidence/runs/delivery-gates-initial/summary.json)). Правило сохранения terminal whitespace ограничено generated .log текущего Stage B evidence, включая package logs; исходный stdout сохранён, проверки кода/документации не отключены.

Static CI на delivery commit 353933d нашёл ссылку на локальный ZIP в игнорируемом .scratch, отсутствующем в чистом clone ([лог](evidence/ci-delivery-initial/failure.log)). Путь в delivery.md теперь указан текстом; manifest остаётся tracked. Валидатор не изменялся. После документационной правки CI запускаются на новом HEAD.

## Поставка и приёмка

Проверки репозитория, упаковки, CI и SHA поставки фиксируются в [delivery.md](delivery.md). Пакет содержит только addons/go_flora, без тестовых сцен и пользовательских ресурсов. Один проект/сцена владельца: C:\Dev\TEST_FLORA и res://go_flora_stage01_demo/demo.tscn. Инструкция: [manual_qa.md](manual_qa.md); границы: [known_limitations.md](known_limitations.md).

Merge/release, Stage 03 и Issue #15 не выполнялись. PR оставляется открытым до ручной приёмки.
