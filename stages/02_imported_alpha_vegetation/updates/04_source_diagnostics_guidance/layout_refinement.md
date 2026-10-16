# GUI-13.3 — adaptive Source Diagnostics layout

Дата: 16 октября 2026. Source commit: `3d9bf1970f09395bc2c01921b09c1f421a0995cd`.

## Изменение

Source selector остаётся сверху. Guidance измеряется по фактическим строкам Label и занимает только нужную высоту до `38%` окна; длинный текст остаётся внутри `ScrollContainer`. Toggle `Технические сведения` идёт сразу после visible guidance. Когда details раскрыты, единственный vertical expander — технический `TextEdit`, поэтому он занимает всё оставшееся место до action-row; при сворачивании он исчезает без высокого обязательного gap перед toggle.

Ограничение окна, action-row и штатный OK сохранены. Resolver, typed diagnostic contract, fingerprint/revision, review authorization, persisted records, renderer и TEST_FLORA не менялись.

## Автоматическая проверка

Финальная команда: `python tools/run_issue13_tests.py --godot .scratch/godot-portable/godot.exe --label layoutrefine8`.

- **PASS:** Stage 01, Stage 02/02.1/02.3, legacy resolver parity, пять diagnostic states и modal lifecycle.
- **PASS:** native Editor API cap для 1280×720, 1366×768 и 1920×1080; virtual dialog 1280×720; short/long guidance, two-SHA mismatch, immediate toggle placement, expanded details remaining space, action-row/OK reachability и Source switching.
- **NOT_RUN:** owner interactive GUI QA для этого нового archive. Предыдущий owner GUI-13.3 PASS сохранён в [evidence/gui_13_3_owner_pass.md](evidence/gui_13_3_owner_pass.md); он не заменяет retest новой сборки.

Промежуточные isolated FAIL и их причины сохранены в [evidence/layout_refinement_attempts.md](evidence/layout_refinement_attempts.md); финальный PASS — [runs/layoutrefine8/summary.json](evidence/runs/layoutrefine8/summary.json).

## Plugin-only ZIP

Архив: `GO_FLORA_stage02_0.2.4-dev_a0f7ea1c.zip` в `updates/04_source_diagnostics_guidance/.scratch/packages/`.

SHA-256: `22a3a2957f0bfcb6ade623c3aa4c369d1b4b23f715c561ce2e5e8ed8d9a551b4`.

Manifest: `GO_FLORA_stage02_0.2.4-dev_a0f7ea1c.json`; source digest: `a0f7ea1c5e1dd53a67708b40350f6b354099080c57e626e8510097e704675a9e`. Архив содержит 55 файлов только из `addons/go_flora/`; CRC и SHA-256 каждого файла проверены packaging script. Установка через Windows Explorer: [manual_qa.md](manual_qa.md).
