# GUI-13.5 — переход из Source Diagnostics в Inspector

**READY_FOR_MANUAL_QA. INTERACTIVE_GUI_QA: NOT_RUN.**

## Причина и изменение

Владелец сообщил, что после Edit selected Source in Inspector приходится вручную закрывать Diagnostics и переключать вкладку. [Замечание владельца](https://github.com/alekseypilishkov-gif/go_flora/pull/14#issuecomment-6283075413) относится к PR #14, исходный HEAD eaa43d991d88c8459c4e276a1b412bb28fd3d735. Полный текст сохранён в [owner_request.json](evidence/gui135/owner_request.json).

Обработчик теперь сохраняет точный GFVegetationSource из sources[picker.selected], скрывает окно, вызывает queue_free(), очищает ссылку _source_details и отложенно вызывает существующий inspect_resource(source). Этот helper уже использует inspect_object() и EditorDock.make_visible(); он не изменён. Объект выбирается по индексу, а не по display_name. Отложенный вызов выполняет переход после снятия фокуса popup.

Производственное изменение ограничено обработчиком кнопки в addons/go_flora/editor/plugin.gd. Новая система вкладок не создавалась. Данные Source, Renderer, Resolver, Scene Fallback, fingerprint, allowlist, схемы и placement records не менялись. TEST_FLORA и его layout в этом задании не открывались и не редактировались. Новая проверка выполняется в изолированных проектах .scratch/qa013 с отдельными профилями.

## Регрессионная проверка

Расширен tests/editor_diagnostics_harness/plugin.gd. Два созданных тестом источника имеют одинаковое display_name authored_plant и один asset, но разные source_id и разные объекты; первый REVIEWED_READY, второй REVIEW_REQUIRED. Последовательность выбора — второй, первый, второй. Для каждого цикла проверяются:

- Возврат в GO_FLORA публичным EditorDock.make_visible(), открытие Diagnostics и переключение selector.
- Copy revision остаётся привязан к выбранному источнику.
- Немедленное скрытие и постановка окна на удаление, отсутствие живого Diagnostics/modal после обработки очереди.
- Точное равенство объекта в Inspector и выбранного source_id; Inspector автоматически видим.
- Повторное открытие, закрытие через canceled/confirmed, сохранение dock topology, экспортированных данных Sources и records.

Открытие/возврат через native Editor API не заменяет физический Ctrl+Alt+G и работу мышью. Эти действия включены в owner checklist ниже.

## Результаты локальных проб

| Проверка | Результат | Свидетельство |
| --- | --- | --- |
| Финальный regression harness + прежний pinned plugin.gd | FAIL ожидаемо: 9 navigation assertions; exact source identity и данные PASS | [Red confirmation](evidence/runs/gui135-red-confirmed/summary.json), [лог](evidence/runs/gui135-red-confirmed/editor_navigation.log) |
| Полный tools/run_issue13_tests.py после исправления | PASS: 20/20 probes | [Green summary](evidence/runs/gui135-green/summary.json) |
| Diagnostics Editor API | PASS: 55/55 assertions, включая два одинаковых имени | [Assertions](evidence/runs/gui135-green/issue13_editor_results.json), [лог](evidence/runs/gui135-green/editor_diagnostics.log) |
| Все пять diagnostic states, hard blockers и Copy | PASS | [Contract](evidence/runs/gui135-green/issue13_diagnostics_results.json) |
| Resolver parity с pinned main fecf4fc9dd3e04aa79bf0d7b390dc24b3ab6511b | PASS: status, revision, parts, scene, capabilities | [Summary](evidence/runs/gui135-green/summary.json) |
| Stage 01 / 02 / 02.1 / 02.3, save/reopen и прежний modal lifecycle | PASS | [Команды и логи](evidence/runs/gui135-green/summary.json) |
| Работа мышью, физический clipboard, Ctrl+Alt+G, сохранение исходного TEST_FLORA | NOT_RUN | Требуется owner GUI retest |

Команда полного green-прогона из корня репозитория:

~~~text
python tools/run_issue13_tests.py --godot .scratch/godot-portable/godot.exe --label gui135-green
~~~

Godot: 4.7.2.stable.official.ed1daf0bf. SHA-256 локального бинарника: ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424.

Первая red-попытка также выявила ошибку самой проверки: var_to_str(Source) захватывал изменяемый lazy resolver cache. Snapshot теста ограничен экспортированными Source-полями; повторный red на прежнем коде оставил ровно 9 ожидаемых navigation failures. Обе попытки сохранены отдельно, старые evidence не перезаписаны: [первая попытка](evidence/runs/gui135-red/summary.json), [подтверждённая регрессия](evidence/runs/gui135-red-confirmed/summary.json).

Локальная Bash whitespace-проба: первая попытка FAIL из-за отсутствия bash в PATH; повтор с явным Git Bash заблокирован ограничением MSYS NtCreateDirectoryObject (0xC0000022). Эти ошибки окружения сохранены в evidence/gui135. Повтор штатной пробы вне sandbox — PASS, все 5 cases; [результат](evidence/gui135/whitespace_regression_pass.json). Прямые working/staged и committed PR-base diff whitespace checks — PASS; [gates кодового commit](evidence/gui135/code_commit_gates.json).

## CI и поставка

В Stage 02 workflow добавлен запуск Issue #13 suite, поэтому новый navigation regression выполняется в CI. Первый Linux прогон выявил отсутствие pinned baseline при стандартном shallow checkout: git ls-tree завершился до Godot-проб. Для Resolver parity добавлен fetch-depth: 0; addon не изменён. [CI bootstrap failure](evidence/runs/gui135-ci-bootstrap/summary.json), [точный лог](evidence/runs/gui135-ci-bootstrap/failure.log). Три workflow — Repository static checks, Stage 01 Godot automatic checks, Stage 02 imported assets automatic checks — запускаются на push. Их финальное состояние проверяется на опубликованном HEAD перед завершением задания; ссылки и SHA сообщаются в delivery.

После commit/push исправления **9b8cbbae1b1f5dc4985779d95ad3c0658d1b494f** сформирован plugin-only ZIP:

- Файл: `.scratch/packages/GO_FLORA_stage02_0.2.4-dev_571da0b2.zip` относительно каталога этого update.
- SHA-256: `7906d2ae7b5195b6cd0f066da5a2ece829f23a022ba82782f69619cc98905667`.
- 55 файлов только в addons/go_flora; **0.2.4-dev**; ZIP не содержит scenes, fixtures, tests, caches и исполняемых зависимостей.
- [Полный manifest](evidence/package/gui135_manifest.json), [SHA-256](evidence/package/gui135_archive.sha256).
- [Package validation](evidence/gui135/package_validation.json): PASS CRC/SHA, побайтная воспроизводимость, три установки с сохранением scene/config/layout checksum, запрет traversal, standalone import и runtime Stage 01/02. [Import log](evidence/runs/gui135-package/standalone_import.log), [Stage 02](evidence/runs/gui135-package/stage02_runtime.log), [Stage 01](evidence/runs/gui135-package/stage01_runtime.log).

Package manifest привязан к кодовому commit 9b8cbba. Последующая доставка меняет только documentation/evidence; addon blobs проверяются по manifest на финальном HEAD. Установка в TEST_FLORA остаётся ручной задачей владельца. PR #14 остаётся открытым; merge/release не выполняются.

## Owner GUI retest

1. Установить новую сборку вручную после проверки её SHA-256; не менять сохранённую раскладку.
2. В Source Diagnostics выбрать второй authored_plant, сверив его полный source_id, и нажать Edit selected Source in Inspector один раз.
3. Убедиться, что Diagnostics закрыто, вкладка Inspector активна и показывает именно выбранный GFVegetationSource; Allow Scene Fallback и Reviewed Scene Revision остались прежними.
4. Вернуться в GO_FLORA через Ctrl+Alt+G. Повторить открытие и переход для первого одноимённого Source, затем снова для второго. Проверить закрытие Diagnostics через Escape и OK.
5. Проверить Copy revision и ранее проверенные diagnostics states. Не включать fallback и не менять данные только ради проверки навигации.

Итог автоматической проверки — READY_FOR_MANUAL_QA; GUI-13.5 OWNER_GUI_PASS может поставить только владелец после реального retest.
