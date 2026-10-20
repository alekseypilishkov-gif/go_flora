# GUI-13.3 layout refinement — attempts

Все прогоны запускались изолированно одной командой: `python tools/run_issue13_tests.py --godot .scratch/godot-portable/godot.exe --label <label>`; `TEST_FLORA` не открывался.

- `runs/layoutrefine1/`: **FAIL** — обращение к несуществующему `AcceptDialog.resized` при первом варианте resize hook; security/Stage probes до Editor API прошли.
- `runs/layoutrefine2/`: **FAIL** — замена на `size_changed` вызвала deferred relayout loop. Raw `editor_diagnostics.log` достиг `895,994,659` bytes и был перемещён в ignored `.scratch/` вместо добавления в репозиторий, чтобы соблюсти repository artifact limit. Остальные сохранённые файлы этой попытки оставлены без изменения.
- `runs/layoutrefine3/`–`runs/layoutrefine7/`: **FAIL** сохранены как отдельные immutable logs: harness последовательно выявил natural-minimum высоту direct dialog body, затем ограничение реального headless viewport и minimum-width feedback. Они не меняли resolver/security logic.
- `runs/layoutrefine8/`: **PASS** — финальный isolated evidence. Подтверждены virtual `1280×720` layout, adaptive short/long guidance, expanded technical remaining space, action/OK reachability, five diagnostic states, selection binding и modal lifecycle.
