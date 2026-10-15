# Evidence Stage 02.2

Подтверждённый владельцем old-build failure: [Issue #8 snapshot](issue_08.json). [Все attempts](run_index.json), [выбранные финальные результаты](results.json). `runs/<id>/summary.json` хранит фактические commands/exit/status; `.log` нормализован только по trailing whitespace/EOF, а adjacent `.raw.json` сохраняет точный UTF-8 captured content и SHA исходного log file. FAIL не удаляются. Owner observation, source inspection, native runtime и неизвестная interactive acceptance различаются.

Команды **для разработчиков из корня репозитория**, не инструкция установки владельцу:

```text
python tools/run_stage022_tests.py --godot .scratch/godot-portable/godot.exe --phase repro
python tools/run_stage022_tests.py --godot .scratch/godot-portable/godot.exe --phase repro --gpu-editor
python tools/run_stage022_tests.py --godot .scratch/godot-portable/godot.exe --phase regression
python tools/run_stage022_tests.py --godot .scratch/godot-portable/godot.exe --phase modal
python tools/run_stage022_tests.py --godot .scratch/godot-portable/godot.exe --phase modal --gpu-editor
python tools/run_stage02_gpu.py --godot .scratch/godot-portable/godot.exe --output stages/02_imported_alpha_vegetation/updates/02_resource_picker_modal_fix/evidence/.scratch/alpha-gpu-final
python tests/test_stage02_package.py --godot .scratch/godot-portable/godot.exe --output stages/02_imported_alpha_vegetation/updates/02_resource_picker_modal_fix/evidence/.scratch/package-final --package-output stages/02_imported_alpha_vegetation/updates/02_resource_picker_modal_fix/.scratch/packages
python tools/collect_stage022_evidence.py
python tools/verify_repository.py
git diff --check
git diff --cached --check
git diff --check origin/main...HEAD
```

`repro` восстанавливает только addon из pinned `1c61bf1fcd059cfb4d559eeabac806c684ecfddb` в новую проверенную `.scratch` копию. Legacy case **остаётся FAIL** в summary, reproduction_probe=PASS означает, что нужный старый дефект действительно наблюдался; fixed tests не допускают ERROR/SCRIPT ERROR. Первая headless reproduction выполнена до изменения addon; последующая GPU reproduction восстановлена из Git. Переключение ветки/изменение рабочего addon для этого не требуется.

Регрессии выполняют прежние Stage 01/02/02.1 tests без изменений. Новый modal harness использует настоящие picker menu, поиск Quick Open и native Enter handler, выделение file list и Open, Save FileDialog callback, native Undo/Redo. Переопределения ресурса напрямую вместо выбора файла нет. Чтобы native Quick Open индексировал старые hand-authored PackedScene fixtures, UID headers сохраняются только в disposable copies. Числовые inputs используют допустимую сетку min+step.

GPU captures — viewport каждого отдельного окна (без рамки ОС), не desktop screenshots/мышиная QA. GPU alpha pixels — отдельные probes трёх renderer, не источник утверждений о ручной GUI приёмке. Windows-профили/кеши короткие и isolated в ignored .scratch. Полная mouse/keyboard acceptance — **INTERACTIVE_GUI_QA: NOT_RUN**.

CI сохраняет три workflows; Stage 02 job включает новые modal/reopen tests и ZIP 0.2.2-dev artifact. Linux engine ZIP pinned SHA `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`. Локально использован bundled Python runtime приложения, потому что system python alias не работает; переносимые команды выше используют python.
