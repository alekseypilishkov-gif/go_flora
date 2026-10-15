# Контролируемая интеграция Stage 02 — проверка перед merge

15 октября 2026. Существующий [PR #6](https://github.com/alekseypilishkov-gif/go_flora/pull/6), ветка `codex/stage-02-imported-alpha`. Начальный origin/main: `5c076153e1dea6363b885e82f4ef391808586348`. Локальный main отставал: `8cbac98f0705a16f5746baa07f37ec2b2bae75b6`; его старый SHA не считается актуальным GitHub main. Реальный PR HEAD до документационного коммита: `53ef07b76578f508a7fafb332a949f25ca90189c`.

## Объём и история

В PR присутствуют восемь исходных коммитов Stage 02–02.3, включая импорт GLB/PackedScene и AlphaCard, именованную палитру/Mix/Selected/Inspector, ResourcePicker fix, непрерывный Erase и сохранённые render-only источники. [Инвентарь путей](evidence/implementation_inventory.json) — source inspection PASS; он не подменяет runtime evidence. [Исходный Git](evidence/initial-git.json) и [GitHub snapshot](evidence/github_before.json) фиксируют ветки, SHA и CI. История не переписывается; требуется merge commit.

Tracked/staged изменения до задачи отсутствовали. Единственный посторонний файл — пользовательский `Изображение ChatGPT 15 окт. 2026 г., 08_28_48.webp`; он не включается в Git, не удаляется и не перезаписывается. В PR нет `.scratch`, ZIP, бинарников или импортных кешей. TEST_FLORA и GAME_FLORA не читаются и не изменяются.

## Повторные автоматические проверки

Использованы существующие тесты без изменения assertions. Новый wrapper в ignored `.scratch/integration-20261015/run_checks.py` перенаправляет только output существующего `tools/run_stage023_tests.py` в текущий integration-каталог. Данные/тестовые проекты и профили изолированы в `.scratch`; raw команды и результаты — в `runs/premerge/<phase>/summary.json`.

| Проверка | Результат |
| --- | --- |
| Stage 01 core / native Editor API и fresh reopen | PASS 45 / 27 |
| Stage 02 core / native Editor API и fresh reopen | PASS 87 / 62 |
| Stage 02.1 core / native Editor API и fresh reopen | PASS 28 / 99; ранее согласованные владельцем duplicate-ID assertions не менялись в этой задаче |
| Stage 02.2 ResourcePicker и fresh reopen | PASS 274 native assertions |
| Stage 02.3 core / retained catalog | PASS 41 / 26 |
| Stage 02.3 headless Editor API и separate-process reopen | PASS; GPU в headless явно NOT_RUN |
| Реальные alpha-scissor pixels Compatibility/Mobile/Forward+ | PASS 18 |

Godot `4.7.2.stable.official.ed1daf0bf`, SHA-256 `ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424`. Engine hash также записан каждым runner. Новый код и новые сцены не создавались. Полные прошлые GPU/native suites остаются в исходном Stage 02.3 evidence, новые прогоны находятся только в этом integration-каталоге.

Три GitHub workflow на начальном HEAD `53ef07b` — PASS. После документационного коммита статуса необходимо дождаться трёх новых workflow на его точном SHA перед merge; успешный старый CI не подменяет эту проверку. Итоговые merge SHA и ссылки CI будут опубликованы в integration-отчёте и GitHub PR.

## Статусы приёмки

**Stage 02.3 — FINALIZED / OWNER GUI PASS**, [подробное подтверждение](owner_acceptance.md). Issue #9 CLOSED.

Общий Stage 02 ещё не полностью принят: ручные GLB/PackedScene, UV-atlas и другие интеграционные случаи остаются NOT_RUN / READY_FOR_MANUAL_QA. После merge: **INTEGRATED, BUT MANUAL ACCEPTANCE INCOMPLETE**. Владелец прямо разрешил именно эту интеграцию несмотря на незавершённую общую приёмку; это не автоматическое признание Stage 02 завершённым. Issue #5 и #8 не закрываются как полностью принятые.

Существующие evidence и исходные FAIL/NOT_RUN логи не редактируются. Читаемые новые `.log` нормализуют концевые пробелы; точный декодированный Output сохранён в соответствующих `.raw.json`.
