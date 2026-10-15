# Stage 02 — evidence index

**READY_FOR_MANUAL_QA; INTERACTIVE_GUI_QA: NOT_RUN.** Все engine-проверки выполнены настоящим Godot 4.7.2; разные виды evidence не подменяют друг друга. [Issue snapshot](issue_05.json), [итоги](results.json), [точные subprocess commands / exit codes](commands.json), [fingerprints исходников](source_hashes.json), [package manifest](package_manifest.json).

## Воспроизведение

Из корня репозитория; локальный Python был bundled runtime Codex, engine `.scratch/godot-portable/godot.exe`. Точные абсолютные команды каждого engine-процесса сохранены в commands.json.

```text
python tools/run_stage02_tests.py --godot .scratch/godot-portable/godot.exe --phase baseline
python tools/run_stage02_tests.py --godot .scratch/godot-portable/godot.exe --phase stage02 --label=-verified
python tools/run_stage02_gpu.py --godot .scratch/godot-portable/godot.exe
python tools/prepare_stage02.py --godot .scratch/godot-portable/godot.exe --build-demo
python tools/capture_stage02_demo.py --godot .scratch/godot-portable/godot.exe
python tests/test_stage02_package.py --godot .scratch/godot-portable/godot.exe
python tools/run_stage02_tests.py --godot .scratch/godot-portable/godot.exe --phase final
python tools/capture_stage02_evidence.py
python tools/verify_repository.py
git diff --check
git diff --cached --check
git diff --check origin/main...HEAD
```

Baseline был выполнен до изменения addon от принятого main `5c076153e1dea6363b885e82f4ef391808586348`. Повтор baseline на текущей ветке проверит уже новый addon; frozen `demo/fixtures/stage01_saved.tscn` и `stage01_expected.json` сохраняют исходный результат старого кода. Изолированные рабочие копии/профили/импорт находятся в текущем stage `.scratch`, рабочий TEST_FLORA не использовался.

## Виды доказательств

| Evidence | Что подтверждено |
| --- | --- |
| baseline/final summaries + stage01 core/editor JSON | Неизменённые Stage 01 tests, отдельное сохранение/повторный процесс, native Editor Undo/Redo/dock geometry |
| stage02_core.json | Реальный GLB-import, все части/материалы/UV/bounds, alpha geometry, frozen old scene, deterministic mixed strokes, fallback processing/signals/groups/physics, missing/future/corrupt data, CPU cache timings |
| stage02_editor.json | Native editor source creator/UV preview/save/palette Undo/Redo, each source kind preview/cancel/single/erase/history/distance, настоящие PNG/GLB reimports, удалённые файлы |
| gpu/*.json + logs/gpu | Реальные Compatibility OpenGL / Mobile Vulkan / Forward+ Vulkan пиксели, NVIDIA GeForce RTX 5060 Ti; PNG и WebP, mipmaps=true, gutter=8 px, 3/12/24 m |
| screenshots/demo_gpu*.png | Реальный runtime-кадр авторской сцены с GLB/grass/flower; без mouse/GUI acceptance |
| package_summary.json | ZIP_STORED побитовая воспроизводимость, CRC/SHA каждого файла, три установки, SHA сцен/config/layout, backup, traversal rejection и native smoke обеих сцен |

Logs находятся в `logs/`. Файлы `.log` нормализованы по завершающим пробелам/переводам строк для Git whitespace gate; рядом `.raw.json` сохраняет исходный UTF-8 content с точным SHA-256 байтов, включая ANSI/CRLF/trailing spaces. Скриншоты diagnostic atlas находятся в `screenshots/`; прозрачные участки раскрывают известный красный фон, opaque texels зелёные. Это узкий pixel test, не полная художественная оценка и не гарантия для любого атласа.

Первичный API source review: [SceneState](https://docs.godotengine.org/en/stable/classes/class_scenestate.html), [BaseMaterial3D](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html). Runtime results подтверждаются logs/JSON отдельно. Данные устройства взяты из текущих GPU logs, engine SHA — из фактически запущенного бинарного файла; утверждения upstream о других платформах здесь не проверялись.

Разработка включала FAIL-прогоны, сохранённые отдельно в `development_failures/`: типизация теста; вызов ArrayMesh-only API на BoxMesh; early timeout после ошибочного теста; сравнение сериализованных transform без допуска; `_process` до завершения нужного frame; отсутствие `.scratch` при первой сборке demo. Исправления/пределы описаны в [отчёте](../report.md). Финальные PASS не переписывают эти ошибки. GPU/FPS большого леса, чистый export и ручная мышь/навигация — NOT_RUN. Исторический alpha-hash Compatibility FAIL Stage 00 не менялся и здесь не перепроверялся.
