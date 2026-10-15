# Evidence 0.2.1-dev

[Issue #7 snapshot](issue_07.json), [результаты](results.json), [индекс всех запусков, включая FAIL](run_index.json). Каждый `runs/<id>/summary.json` содержит точные выполненные command/exit/status; рядом нормализованный readable `.log` и `.raw.json` с точным UTF-8 captured content и SHA-256 исходного log file. Нормализация удаляет только trailing whitespace/лишние пустые EOF для git diff --check; raw evidence сохраняется. Вложенные `*_results.json` содержат отдельные assertions/benchmarks. Старые Stage 01/02 evidence не переписаны.

Все проекты под текущим update/evidence/.scratch, engine под корневым ignored .scratch. Локальные runtime команды, из корня репозитория:

```text
python tools/run_stage021_tests.py --godot .scratch/godot-portable/godot.exe --phase baseline
python tools/run_stage021_tests.py --godot .scratch/godot-portable/godot.exe --phase final
python tools/run_stage021_tests.py --godot .scratch/godot-portable/godot.exe --phase ux
python tools/run_stage021_tests.py --godot .scratch/godot-portable/godot.exe --phase ux --editor-capture
python tools/run_stage02_gpu.py --godot .scratch/godot-portable/godot.exe --output stages/02_imported_alpha_vegetation/updates/01_palette_dock_ux/evidence/.scratch/gpu-short-profile
python tests/test_stage02_package.py --godot .scratch/godot-portable/godot.exe --output stages/02_imported_alpha_vegetation/updates/01_palette_dock_ux/evidence/.scratch/package-final --package-output stages/02_imported_alpha_vegetation/updates/01_palette_dock_ux/.scratch/packages
python tools/collect_stage021_evidence.py
python tools/verify_repository.py
git diff --check
git diff --cached --check
git diff --check origin/main...HEAD
```

Baseline 1792045111708956800 исполнялся **до изменения addon** на исходном 875e2ea. Повтор baseline на новом addon является новым regression run, не восстановлением исторического результата. Выбранные финальные runs указаны в results.json; промежуточные FAIL не скрыты. Source APIs и документированная семантика не считаются runtime PASS. GPU captures выполнены кодом через native Editor API и просмотрены; реальные GUI мышь/drag/navigation/manual save — **NOT_RUN**. Драйвер указан в GPU logs. Package fixture sentinel layout проверяется SHA до/после installer, без открытия owner project.

В PowerShell локально использовался Python runtime приложения (system python alias не работает); summary содержит точные Godot child commands. Переносимые команды выше используют `python` и repository-relative paths. CI использует Linux pinned ZIP с SHA `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`; ручная QA не заменяется CI.
