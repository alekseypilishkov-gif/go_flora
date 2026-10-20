# GUI-13.1 — исправление layout Source Diagnostics

Дата: 16 октября 2026. Source commit: `bd7eb5d432488baf5f808a8d90df48f297d86d69`.

## Изменение

Диалог получает preferred bound `680×620` logical pixels и рассчитывает доступный размер от viewport редактора с запасом `48×64`; координаты viewport сохраняют согласованность с текущим DPI масштаба Godot. Selector, action-row и штатный OK остаются вне прокручиваемого guidance body. Длинная инструкция прокручивается в `ScrollContainer`; Technical Details свёрнуты по умолчанию и при открытии остаются ограниченным `112 px` `TextEdit` со своей прокруткой.

Resolver, typed diagnostic contract, revision/fingerprint, persisted resources, records, renderer и TEST_FLORA не менялись.

## Автоматическая проверка

Команда: `python tools/run_issue13_tests.py --godot .scratch/godot-portable/godot.exe --label layoutfix2`.

- **PASS:** Stage 01, Stage 02/02.1/02.3, legacy resolver parity и все пять diagnostic states.
- **PASS:** native Editor API layout cap для `1280×720`, `1366×768`, `1920×1080`; actual `Window.size`, child boundaries, selector/actions/OK, two-SHA Revision Mismatch, collapse/expand Technical Details, Copy/Inspector binding и modal lifecycle.
- **NOT_RUN:** owner interactive mouse/navigation/save GUI QA. Historical owner FAIL: [evidence/gui_13_1_owner_fail.md](evidence/gui_13_1_owner_fail.md). Ранний harness parse FAIL сохранён в `evidence/runs/layoutfix1/`; финальный run — [layoutfix2](evidence/runs/layoutfix2/summary.json).

## Plugin-only ZIP

Архив: `GO_FLORA_stage02_0.2.4-dev_fb68ff81.zip` в `updates/04_source_diagnostics_guidance/.scratch/packages/`.

SHA-256: `9ef3628739b294207a88d5b5b529784c8e9409c1a560f3abc974031ffdeea689`.

Manifest: `GO_FLORA_stage02_0.2.4-dev_fb68ff81.json`; source digest: `fb68ff8105310c876d18731c274436d46cab70f454880b8052679c3446783d11`. Архив содержит 55 файлов только из `addons/go_flora/`; CRC и SHA-256 каждого файла проверены packaging script. Инструкция ручной установки через Windows Explorer обновлена в [manual_qa.md](manual_qa.md).
