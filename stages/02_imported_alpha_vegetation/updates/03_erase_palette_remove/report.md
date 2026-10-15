# GO_FLORA 02.3 — Continuous Erase и безопасная палитра

Актуализация 15 октября 2026: **Stage 02.3 — FINALIZED / OWNER GUI PASS**, Issue #9 CLOSED. Владелец отдельно принял Continuous Erase, оба варианта удаления, Undo/Redo каждого и save/reopen после безопасного удаления, без ошибок в проверенных сценариях. [Подробная запись владельца и границы приёмки](../../integration/2026-10-15/owner_acceptance.md). Общий Stage 02 ещё не полностью принят. Следующий текст и исходные автоматические логи сохраняют состояние на момент первоначальной поставки; их NOT_RUN не отменяет последующую owner GUI acceptance.

Дата: 15 октября 2026. Задача: [Issue #9](https://github.com/alekseypilishkov-gif/go_flora/issues/9), существующая ветка `codex/stage-02-imported-alpha`, [Draft PR #6](https://github.com/alekseypilishkov-gif/go_flora/pull/6). Версия **0.2.3-dev**. **READY_FOR_MANUAL_QA; INTERACTIVE_GUI_QA: NOT_RUN.** Физическая приёмка владельцем ещё необходима.

## Что изменилось

**Erase.** Старый код начинал просмотр records с нуля на каждом stamp, расходовал общий лимит 2000 даже на чужие/далёкие записи и прекращал обработку до отпускания. Это подтверждено исходниками и отдельным запуском старой версии `f8917186ce7cdbfd1177a2a80610e500280d81d3` в disposable-копии. Новый временный world-space grid индексирует незаблокированные записи активного набора. Поиск проверяет точное расстояние до полного пути кисти; порядок массива, быстрые движения, высота и поворот/неравномерный масштаб слоя не обрезают покрытие. Для длинных редких проходов проверяются занятые ячейки; пустой индекс завершается сразу.

Обработка очереди ограничена 512 операциями / до 4 мс на шаг; input добавляет путь, `_process` выполняет один шаг в кадре. При отпускании есть ещё один ограниченный шаг для совместимости небольших Editor API транзакций. Это не обещание 4 мс на весь кадр: окончательный delta, Undo и финальная перестройка рендера синхронны. Если работа ещё осталась, статус показывает завершение очереди; один Undo создаётся только после полной обработки. Esc отменяет весь мазок, отпускание за viewport отменяет его. Навигация, смена сцены/набора/слоя, потеря фокуса, изменение transform или сигнал изменения data также отменяют работу. Последняя позиция MouseUp учитывается. Превью меняет только новые удаляемые MultiMesh slots; полная перестройка на каждом шаге больше не нужна. Paint/Single сохраняют прежний `max_candidates` и выбор Mix/Selected.

**Remove from Palette.** У каждой строки в dock и именованном Inspector есть кнопка **−** с русской подсказкой. Обычное удаление убирает строку из рисования, сохраняя Source в сериализуемом скрытом `render_only_sources`. Размещения остаются видимыми после сохранения/перезапуска. Каталог не участвует в Paint/Single/Mix/Selected. Renderer, material/card/revision observation и reimport учитывают сохранённые ссылки. Stage 01 schema 1 и старые сцены загружаются без миграции; IDs и исходные resources сохраняются. Неиспользуемые ссылки также удерживаются: набор может быть общим с закрытой сценой.

С размещениями диалог показывает точное количество в конкретном слое. **Удалить и размещения…** открывает отдельное подтверждение; оно удаляет только соответствующие `set_id + source_id` этого слоя, включая заблокированные записи, одним Undo/Redo без изменения serial. Другие источники/наборы остаются. Устаревший контекст/счётчик отвергается. Без размещений строка удаляется сразу, Undo возвращает прежний entry/порядок/вес/enabled. Выбранный ID сохраняется, но Selected явно требует доступное растение; тихого переключения на другое растение нет. Повторное добавление Source возвращает его в палитру и снимает архивную ссылку одной транзакцией. Дубликаты активных ID отвергаются без изменений и Undo. Файлы `.tres`, PNG, WebP, GLB не удаляются и не переписываются.

## Проверки и границы доказательств

Godot Windows: `4.7.2.stable.official.ed1daf0bf`; SHA-256 исполняемого файла: `ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424`. Точные команды и engine hash находятся в `summary.json` каждого запуска, исходники тестов — в `tests/`. [Все попытки](evidence/README.md) сохранены, включая разработческие FAIL.

| Проверка | Результат |
| --- | --- |
| Stage 01 core / native Editor API | PASS 45 / 27; отдельный fresh reopen PASS |
| Stage 02 core / native Editor API | PASS 87 / 62; отдельный fresh reopen PASS |
| Stage 02.1 core / native Editor API | PASS 28 / 99; reopen PASS, два сценария усилены с согласия владельца |
| Stage 02.2 native resource picker | PASS 274 headless / 277 GPU; Quick Load/Load, Save/Cancel, контексты, Undo/Redo, fresh reopen 12 sources/14 entries |
| Stage 02.3 core / catalog | PASS 41 / 26: 1/1000/2001/5000/12000, поздние IDs, чужой prefix, locked, обратный порядок, полный sweep, tiny brush/длинная диагональ, transforms, Undo/serial, GLB/PNG/WebP/reviewed fallback |
| Stage 02.3 native editor + GPU | PASS 41: очередь/отпускание/Escape/outside/смена сцены, реальный viewport callback press/release без Motion, сохранение видимости и material change, dock/Inspector, удаления, подтверждения и Undo/Redo |
| Отдельный процесс после удаления строки | PASS: source→record resolution, batches и настоящий зелёный GPU pixel после открытия сохранённой сцены |
| Alpha-scissor GPU PNG/WebP | PASS 18: Compatibility, Mobile, Forward+; NVIDIA GeForce RTX 5060 Ti |
| Plugin ZIP / disposable update | PASS: воспроизводимые bytes, CRC, SHA каждого из 55 файлов, три установки с backup; SHA сцен/config/layout неизменны; standalone import + Stage 01/02 runtime PASS |
| Физическая мышь, навигация и сохранение владельцем | **NOT_RUN**, требуется [ручной чек-лист](manual_qa.md) |

В исходном неизменённом Stage 02.1 два сценария ожидали создание дубликата активного source_id; их FAIL сохранён в `regression02`. После явного согласия владельца изменены ровно эти два сценария: отказ не меняет источник/records/Undo. Число 99 сохранено; assertions не ослаблены. Остальные старые тесты не изменялись. Отдельные новые тесты подтверждают успешное добавление архивного Source и его Undo/Redo.

Профиль CPU для одинаковых 61 input и 12000 records: старая версия удалила **101/12000**, новая — **12000/12000**. Старый запуск быстрее именно потому, что бросал работу; сравнивать их как равный объём нельзя. Общие CPU timings и число проверок записаны в `erase_profile.json`. Отдельный native profile 5000 экземпляров измеряет query+preview шаги (в финальном прогоне 20 шагов, максимум 2600 мкс), не FPS и не физическую интерактивную плавность. Не требуется повторно кликать ради обхода первых 2000 records.

**Astra: source review PASS**, после исправления четырёх найденных крайних случаев подтверждённых P1/P2 не осталось. Это независимая проверка кода; runtime запускал основной агент. Детали алгоритма и совместимости: [контракт Stage 02.3](../../../../docs/STAGE_02_3_ERASE_PALETTE.md).

## Архив для владельца

Точный путь:

`C:\Dev\GO_FLORA\stages\02_imported_alpha_vegetation\updates\03_erase_palette_remove\.scratch\packages\GO_FLORA_stage02_0.2.3-dev_2e26e47a.zip`

SHA-256: `42556f0fa6232f73acce7e8c353b851b27d94b7bf266a61b1a342c37549ff034`.

Рядом `.json` manifest и `.sha256`; manifest перечисляет SHA каждого addon-файла. Source digest: `2e26e47a578175dd740aead8af649572d7d5b5a369cfc2e4a468a24382a044f0`. Архив содержит только `addons/go_flora/`, MIT-код/документацию/UID. Сторонних assets, tests, caches и зависимостей нет. Исходники зафиксированы в `30f9feedeef795f929df3eaa2a4d7ed41210bf99`. Повторная сборка после commit сохранила те же ZIP bytes и SHA; [committed manifest](evidence/package/committed-manifest.json) содержит этот source HEAD. Проверка каждого из 55 Git blobs против ZIP прошла.

Установка только владельцем через **Проводник Windows**, без команд: закрыть Godot, сохранить backup прежней папки addon вне проекта, извлечь ZIP во временную папку и скопировать оттуда `addons\go_flora` в `C:\Dev\TEST_FLORA\addons\go_flora` с заменой. Открыть прежнюю сцену и пройти чек-лист. Агент `TEST_FLORA` не читал и не изменял.

## Git и статус поставки

Исходная база задачи — `f8917186ce7cdbfd1177a2a80610e500280d81d3`; база PR — `main` / `5c076153e1dea6363b885e82f4ef391808586348`. Работа продолжается в существующей ветке и обновляет Draft PR #6. Repository validation и whitespace gates выполняются перед commit; три workflow запускаются на push, окончательные ссылки и статус конкретного HEAD публикуются в PR #6. Локальные подробные проверки отделены от CI и ручной приёмки.

На source commit `30f9feedeef795f929df3eaa2a4d7ed41210bf99` все три CI workflow **PASS**: [Repository static](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/38718285058), [Stage 01](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/38718285238), [Stage 02 / 02.1 / 02.2 / 02.3 и ZIP](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/38718285257). [Снимок CI](evidence/ci/source-commit.json), [проверка committed blobs, предыдущих evidence и whitespace](evidence/gates/source-commit.json). Следующий коммит дополняет только отчёт и evidence; addon bytes и ZIP остаются прежними. Три проверки конечного delivery HEAD отдельно проверяются перед передачей и указываются в PR #6.

Предыдущие stage evidence и история Git сохраняются. Известный прежний пользовательский untracked WebP остаётся вне коммитов; чистота tracked/staged изменений проверяется отдельно от этого исключения. Merge, release и Stage 03 не выполняются. `GAME_FLORA` не затрагивался.
