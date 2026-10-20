# Issue #16 — Configuration Warnings

Статус поставки: **READY_FOR_MANUAL_QA**. **INTERACTIVE_GUI_QA: NOT_RUN**.
Версия: **0.2.5-dev**, Godot **4.7.2.stable.official.ed1daf0bf**.

## Основание и границы

[Issue #16](https://github.com/alekseypilishkov-gif/go_flora/issues/16) и [разрешение владельца на реализацию](https://github.com/alekseypilishkov-gif/go_flora/issues/16#issuecomment-6284614715).
Точные тексты сохранены в [owner_issue.json](evidence/owner_issue.json) и [owner_authorization.json](evidence/owner_authorization.json).
Отдельная ветка: codex/issue-16-warning-filter. База: проверенный HEAD PR #14, **ce3391049e4427625c70b6ffe145b2aaa7ab91dc**. Stacked PR направлен в codex/issue-13-source-diagnostics-guidance. Ветка PR #14 не изменяется.

Владелец сообщил о жёлтом значке после удаления размещений: Saved records: 0, Cells / batches: 0. Это **OWNER_GUI_FAIL, сообщение владельца**; скриншот этого случая в текущем задании локально недоступен. Исходный TEST_FLORA для воспроизведения не открывался и не изменялся.

## Причина и изменение

**SOURCE_INSPECTION:** GFCellRenderer.build() разрешал все Sources из палитры и render_only_sources и добавлял полную диагностику разрешения в общий diagnostics. VegetationLayer3D возвращал этот массив из _get_configuration_warnings(). Поэтому INFO о корректном REVIEWED_READY и проблемы архивов без records становились предупреждениями Node. Ошибка отсутствующего Source дополнительно повторялась на каждую запись.

Теперь добавлен отдельный неперсистентный канал configuration_warnings. Он формируется по фактически неотображаемым records, типизированным Status / DiagnosticState / BlockingReason и факту отсутствующей ссылки. Текст diagnostics не анализируется. Полная render_diagnostics и Source Diagnostics сохранены.

| Сценарий | Новое поведение | Автоматическое свидетельство |
|---|---|---|
| A — пустой корректный слой | Архивы сами по себе не создают Node warning | A_empty_layer_archives_no_warning |
| B — REVIEWED_READY | INFO о скриптах/коллайдерах/Runtime Scene Instances остаётся в Diagnostics; Node без предупреждения | B_reviewed_runtime_scene_no_INFO_warning; Editor B_live_review_ready |
| C — неподдерживаемый архив без records | Архив сохранён, нет Node warning и влияния на Painter | C_unused_hard_and_review_archives_do_not_affect_valid_record |
| D — пропавшие размещения | Set ID, имя/ID Source, typed category, количество records; сами records сохранены | D_*; fresh-process reopen; revision/reimport Editor |
| E — заблокированный MIX | Причина в контексте MIX / Selected и Set; исправный Selected доступен, Node не объявляется неисправным | E_* core и Editor; live weight/enabled/reimport |
| F — повторы | Группировка по Set/Source/категории, максимум 8 групп и сводка остальных | 20 000 records / 2 Sets, 40 групп, длинные имена |

Предупреждение ограничено 512 символами; поля имени/ID — 64. Максимум 8 отдельных групп и одна сводка с числом пропущенных групп и records. Контекст Painter ограничен 800 символами. Полные ID доступны в ресурсах/Inspector и debug diagnostics. Повреждённые записи, неверная конфигурация слоя и будущая schema по-прежнему обрабатываются существующим editing_diagnostic().

Изменены presentation helper, сборка диагностического канала Renderer, передача канала в Layer и отображение статуса Painter. Переход blocked → ready очищает старую причину без перезапуска редактора. Renderer eligibility, геометрия, transforms, сериализация, разрешение Sources, allowlist и ревизии не изменялись. Проверка границ записана в [scope_audit.json](evidence/scope_audit.json).

## Runtime evidence

**AUTOMATIC / HEADLESS / NATIVE EDITOR API**, отдельные disposable проекты и профили под .scratch/qa016/. Это не GUI-приёмка мышью.

Основная команда из корня репозитория:

~~~text
python tools/run_issue16_tests.py --godot .scratch/godot-portable/godot.exe --label all-green --phase all
~~~

**PASS: 25/25 probes**, [summary с точными командами](evidence/runs/all-green/summary.json). Core: 24 assertions; Editor: live status, safe removal/Undo/Redo, approval/revision и реальный PNG reimport. Также Stage 01/02/02.1/02.3, save/reopen, Source Diagnostics, Inspector navigation с одинаковыми display_name и разными source_id, жизненный цикл модальных окон из PR #14.

**PASS renderer parity:** сравнение с pinned ce33910 по MultiMesh transforms/parts/bounds/visibility, Runtime Scene Instances и коллайдерам, record slots, полным legacy diagnostics и количеству records. [База](evidence/runs/all-green/renderer_baseline.json), [кандидат](evidence/runs/all-green/renderer_candidate.json). Равенство снимков доказывает проверенный контракт на этих fixtures; это не доказательство GPU-производительности.

**RED CONFIRMED:** [тот же core на pinned ce33910](evidence/runs/red-baseline/summary.json) вернул ожидаемый FAIL по A/B/C/D/E/F и READY INFO; ID/records/archive safety checks проходили. Базовый addon извлечён git show в disposable копию, ветка PR #14 не менялась. [Точный текст выполненной one-shot пробы](evidence/runs/red-baseline/executed_probe.txt); повторный запуск требует нового output label, поскольку evidence неизменяемы.

Сохранены и неуспешные подготовительные прогоны: core-initial/core-diagnose — FAIL из-за сравнения int с JSON float в проверке reopen; targeted-initial — FAIL из-за ERROR Inconsistent undo history в тестовом harness после прямого clear_history(). Исправлены проверки теста и очистка через EditorUndoRedoManager; all-green прошёл без этих ошибок. Логи и точные команды каждого запуска находятся в evidence/runs/; [реестр команд](evidence/probe_registry.json).

## Поставка и оставшаяся проверка

Три CI code commit завершились SUCCESS; после них собран plugin-only ZIP 0.2.5-dev и пройдены 6/6 package probes. Commit, CI links, ZIP, полный SHA-256 и manifest — в [delivery.md](delivery.md). Установка в TEST_FLORA автоматически не выполняется. Дальнейшие ручные шаги — [manual_qa.md](manual_qa.md), границы доказательств — [known_limitations.md](known_limitations.md).

**INTERACTIVE_GUI_QA: NOT_RUN. READY_FOR_MANUAL_QA.** Merge/release/Stage 03 не выполняются.
