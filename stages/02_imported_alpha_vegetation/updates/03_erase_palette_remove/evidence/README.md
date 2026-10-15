# Evidence Stage 02.3

Все файлы относятся только к Issue #9. `runs/<label>/<phase>/summary.json` содержит PASS/FAIL, точные выполненные команды, путь изолированного профиля и SHA Godot. `*.log` — исходный Output; `*_results.json`/`stage023_*.json` — отдельные assertions. Невыполненная физическая приёмка обозначена **INTERACTIVE_GUI_QA: NOT_RUN**.

- `runs/pinned022/baseline`: реконструкция addon из pinned `f8917186ce7cdbfd1177a2a80610e500280d81d3`, тот же профиль 61 inputs. PASS означает, что измерение выполнено; неполное стирание зафиксировано числами removed.
- `runs/dev01`–`dev05`, `regression01`–`regression03`, `ci-local01`: разработческие попытки; FAIL сохранены. Причины: слишком строгая оценка числа соседних spatial candidates в новом тесте; очистка тестовой истории напрямую вместо EditorUndoRedoManager; ожидание frame_post_draw для offscreen capture; исходный synchronous native контракт малых Erase; два конфликта duplicate-ID со старым Stage 02.1; диагностические сообщения разрешённого scene fallback не равны ошибке; один transient OSError при повторной записи лога старым runner. У не завершившегося runner может отсутствовать итоговый summary; исходные логи сохранены.
- `runs/final03/core`: PASS core 41 + catalog 26 и профиль; `runs/final03/regression`: PASS Stage 01 45/27, Stage 02 87/62, Stage 02.1 28/99, Stage 02.2 274 + отдельные reopen.
- `runs/final04/editor`: PASS 41 native/GPU assertions и независимый процесс reopen; CPU шагов включает query + обновление preview, не FPS. `runs/final04/modal-gpu`: неизменённый Stage 02.2 PASS 277 и fresh reopen. `runs/ci-local02/editor`: native headless CI эквивалент, GPU явно NOT_RUN.
- `package/`: manifest и исходные результаты трёх disposable установок; `gpu/`: 18 настоящих PNG/WebP GPU alpha-scissor проверок.
- `review.json`: отдельный Astra source audit, не runtime/GUI доказательство.

Владелец явно согласовал усиление ровно двух duplicate-ID сценариев Stage 02.1. Их первоначальный неизменённый FAIL остаётся в `runs/regression02/regression/editor_ux_harness.log`. Остальные исторические тесты не изменены. Прежние stage evidence не перезаписываются.

Developer commands используют пути от корня репозитория. Пример: `python tools/run_stage023_tests.py --godot .scratch/godot-portable/godot.exe --phase core --label NEW_LABEL`. Другие фазы: `regression`, `editor`; `--headless-editor` даёт CI native API без GPU claim. Владелец устанавливает ZIP через Проводник по инструкции, запускать команды ему не требуется.

В `.raw.json` сохранён точный Output (после стандартного декодирования UTF-8 и перевода строк Python runner). Читаемые `.log` нормализуют только концевые пробелы, чтобы проходить Git whitespace gate. Ни одно прежнее stage evidence не нормализовалось и не изменялось.
