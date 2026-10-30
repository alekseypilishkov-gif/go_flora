# Surface 03.00 — Evidence inventory

Дата: 23.10.2026. Source inspection, native runtime, GPU pixels, Editor API и owner GUI учитываются отдельно. **CONFIRMED** означает только указанный узкий scope. **INFERRED** — проектная оценка/решение. **UNKNOWN / NOT_TESTED** — доказательств пока нет.

## 1. Findings и степень уверенности

| ID | Finding | Класс / evidence |
| --- | --- | --- |
| E01 | Remote main d911087, PR #20 Draft 6fefe29, PR #19 open 7093b07 | CONFIRMED, live GitHub connector metadata, [context](evidence/context.json). Owner GUI state PR19 — reported metadata, не повторная QA |
| E02 | GFBrush/GFStroke/GFSurfaceTarget зависят от Foliage data/layer/set; native undo context — layer | CONFIRMED source inspection на main, [audit](SURFACE_03_00_ARCHITECTURE_REPORT.md), [source SHA256](evidence/source_identity.json). Это не Foliage runtime regression suite |
| E03 | PNG codec сохранил bytes всех каналов при alpha=0 | CONFIRMED native headless, [storage](evidence/runs/cpu-02/storage.log) |
| E04 | save draft → path пуст, canonical load другой object | CONFIRMED native headless, тот же storage log. Reproduces general Issue18 class, не повторный полный Source Creator test |
| E05 | PackedScene ResourceSaver.save не flushes изменённый external Resource; REUSE возвращает RAM | CONFIRMED narrow API test, storage log. Физический Ctrl+S внешнего .res НЕ тестировался |
| E06 | Embedded Resource bytes сохраняются, fresh process load exact, local_to_scene isolates objects | CONFIRMED, [fresh reopen](evidence/runs/cpu-02/fresh_reopen.log), serialized [embedded scene text](evidence/runs/cpu-02/embedded.tscn.txt) |
| E07 | Duplicated local Resources retain identical authored surface_id | CONFIRMED observation fresh reopen; explicit fork/scope — INFERRED design consequence |
| E08 | One complete byte transaction Undo/Redo restores exact bytes | CONFIRMED core UndoRedo, storage log; Surface gesture controller отсутствует |
| E09 | Native EditorUndoRedoManager scene context + undo/redo, _apply_changes on save, reopened bytes | CONFIRMED graphical native Editor API, [editor log](evidence/runs/editor-02/editor_api.log), [new process](evidence/runs/editor-02/editor_fresh_reopen.log); не mouse GUI |
| E10 | Local affine inverse, non-uniform brush metric, negative floor math | CONFIRMED arithmetic in Godot, [mapping](evidence/runs/cpu-02/mapping.log). Physical non-uniform support NOT_TESTED |
| E11 | Physics hit не даёт UV; TriangleMesh plane BVH hit; 0.3 m collider mismatch detectable; stacked floors alias XZ | CONFIRMED limited plane/math fixture, mapping log. Arbitrary topology validator NOT_IMPLEMENTED |
| E12 | 4 channel + zero fallback + normalized mix + roughness/flat-normal debug sampler values | CONFIRMED GPU on RTX 5060 Ti, [final GPU run](evidence/runs/gpu-04/summary.json) and per-renderer logs/JSON |
| E13 | ImageTexture.update меняет GPU, не source PNG bytes | CONFIRMED native GPU/disk hash, gpu-04 logs. Не export/import pipeline proof |
| E14 | Serialized Texture2D facade содержит CPU data, private GPU ImageTexture отсутствует; reload renders | CONFIRMED scratch adapter, gpu-04 logs, [facade text](evidence/runs/gpu-04/facade_forward_plus.tres.txt), [fresh CPU process](evidence/runs/gpu-04/facade_fresh_process.log) |
| E15 | GL vs Vulkan output differs for same blend | CONFIRMED observed pixels in gpu-04, ~0.502/0.498 vs ~0.737/0.733. Не identical visual parity |
| E16 | Per-instance surface override сохраняет shared source material; null restores | CONFIRMED simple native API test, storage log. Full attach/restore conflicts NOT_TESTED |
| E17 | 256/512/1024 embedded raw vs scene sizes/time | CONFIRMED single-run measurement, [storage JSON](evidence/runs/cpu-02/storage.json). Не distribution/p95/RSS/FPS |
| E18 | Same-directory .res replacement succeeds, bypass reload sees new bytes | CONFIRMED ordinary native filesystem case, storage log. Atomic crash/power-loss guarantee UNKNOWN |
| E19 | Embedded CPU graph + facade — safest bounded MVP option | INFERRED architecture judgement, [matrix](DECISION_MATRIX.md), exact contract proposed |
| E20 | 13 samplers support production lit materials/low-end/mobile devices | UNKNOWN / NOT_TESTED. Только narrow desktop debug API pass |
| E21 | Native failed-save recovery, full target/material graph, export/runtime disabled plugin | UNKNOWN / NOT_TESTED — Stage04 mandatory gates |
| E22 | Esc/focus/modal/mode/scene switch Surface input, compact UI mouse acceptance | NOT_RUN — controllers/UI не реализованы; Foliage paths inspected only |
| E23 | Main owner checkout hashes/status unchanged | CONFIRMED bounded file manifest, [owner integrity](evidence/owner_integrity.json). Ignored caches/Git administrative metadata excluded; TEST_FLORA и PR19 worktree не инспектировались |
| E24 | Old addon/docs/tests/tools/historical stage bytes unchanged on research branch | CONFIRMED scope/identity gate, [quality](evidence/quality.json), [addon manifest](evidence/source_identity.json) |
| E25 | Future Foliage query не удаляет placements; proposed weights filtering | INFERRED contract, implementation NOT_RUN |

## 2. Что исполнялось и где точные команды

Каждый run summary содержит argv, exit code, PASS/FAIL и duration; соседний log — полный stdout/stderr. Общие reusable wrapper commands выполнялись из research root:

```text
python .scratch/surface0300/snapshot.py before
python .scratch/surface0300/run.py --phase cpu --label cpu-01
python .scratch/surface0300/run.py --phase cpu --label cpu-02
python .scratch/surface0300/run.py --phase gpu --label gpu-01
python .scratch/surface0300/run.py --phase gpu --renderer forward_plus --label gpu-02
python .scratch/surface0300/run.py --phase editor --label editor-01
python .scratch/surface0300/run.py --phase editor --editor-gpu --label editor-02
python .scratch/surface0300/run.py --phase gpu --label gpu-03
python .scratch/surface0300/run.py --phase gpu --label gpu-04
python .scratch/surface0300/snapshot.py after
python .scratch/surface0300/finalize.py
```

На этой машине python вызван через bundled runtime; Godot argv использует **repo-relative** `.scratch/godot/godot.exe` и disposable project path. Engine copied из уже имеющегося owner ignored binary **read-only**, без установки/скачивания packages. APPDATA/LOCALAPPDATA всех Godot процессов направлены в research scratch profiles. GPU/native Editor API запускались вне экрана; реальные mouse/navigation действия не выполнялись.

| Attempt | Результат процесса/причина | Evidence |
| --- | --- | --- |
| cpu-01 | FAIL storage на shutdown: scratch harness не освободил UndoRedo Object; semantic assertions прошли. Остальные 3 cases PASS | [summary](evidence/runs/cpu-01/summary.json), [FAIL log](evidence/runs/cpu-01/storage.log) |
| cpu-02 | **PASS 5/5 cases**, после clear_history/free UndoRedo; PNG load warning об export сохранён | [summary](evidence/runs/cpu-02/summary.json) |
| gpu-01 | GL/Mobile PASS; Forward+ FAIL из-за создания длинных shader-cache paths при shutdown, exit 0 не считался PASS | [summary](evidence/runs/gpu-01/summary.json), [FAIL log](evidence/runs/gpu-01/forward_plus.log) |
| gpu-02 | **PASS Forward+**, только failed backend повторён; shader/pipeline disk cache выключен в scratch project, пользовательские settings не менялись | [summary](evidence/runs/gpu-02/summary.json) |
| editor-01 | Import PASS, save API assertions прошли, но dummy renderer thumbnail ERROR → overall FAIL | [summary](evidence/runs/editor-01/summary.json), [FAIL log](evidence/runs/editor-01/editor_api.log) |
| editor-02 | **PASS 3/3**, real GL native Editor API + fresh process | [summary](evidence/runs/editor-02/summary.json) |
| gpu-03 | FAIL 3/3: harness ошибочно требовал отсутствия всех ImageTexture во всём ShaderMaterial, хотя 12 detail fixtures именно ImageTexture | [summary](evidence/runs/gpu-03/summary.json) |
| gpu-04 | **PASS 4/4**: проверяется отдельно facade serialization; 3 GPU backends + fresh-process CPU facade read | [summary](evidence/runs/gpu-04/summary.json) |

Итог relevant final process cases: **12 PASS** (cpu-02 + editor-02 + gpu-04). Сохранились **6 FAIL** ранних process cases; их причины исправлены только в disposable harness/config, логи не переписаны. Overall “all attempts PASS” не заявляется.

Raw GPU JSON относится к pixel assertions, а process summary дополнительно учитывает shutdown errors: поэтому в ранних attempts JSON мог содержать PASS при overall FAIL. Приоритет классификации — summary + полный log, а не последняя строка PASS. Build/compiler timing и shader disk cache behavior не оценивались как performance.

Первый static repository gate дал FAIL: quality.json ещё не был создан, а ссылки на него уже существовали. Сохранены [первичный quality result](evidence/quality-initial.json) и [log](evidence/quality/repository.log). После формирования файла gate повторяется с новым label; это ошибка порядка формирования evidence, не addon defect. Финальные команды: `python .scratch/surface0300/finalize.py final-01` и после первого commit `python .scratch/surface0300/finalize.py post-commit`.

## 3. Reproduction и граница source listings

[Probe source listings](evidence/probe_sources/run.py.txt), [storage](evidence/probe_sources/storage.gd.txt), [mapping](evidence/probe_sources/mapping.gd.txt), [GPU harness](evidence/probe_sources/gpu.gd.txt), [shader](evidence/probe_sources/mix.gdshader.txt), [facade](evidence/probe_sources/facade.gd.txt), [Editor API harness](evidence/probe_sources/editor_probe.gd.txt). SHA-256 финальных листингов: [manifest](evidence/probe_sources_manifest.json). Это **текстовые evidence final harness**, не код addon и не готовая Surface implementation. Early FAIL scripts отличались исправлениями, описанными в таблице; финальные листинги не объявляются byte-identical ранним attempts.

Для воспроизведения создать disposable `.scratch/surface0300/project/`, восстановить имена файлов из *.txt: run.py/snapshot.py/editor_probe.gd/editor_reopen.gd → `.scratch/surface0300/`; остальные *.gd, *.gdshader и project.godot → project/. Положить engine с указанным SHA в `.scratch/godot/godot.exe`. Запустить cpu с новым label, затем gpu и editor --editor-gpu с новыми labels. Не запускать against TEST_FLORA/owner scenes. Existing run labels immutable; runner отказывает overwrite output.

Serialization excerpts хранятся с расширением .txt; PNG screenshots — generated synthetic fixture, не UI/mockup и не owner evidence. Codec input PNG load warnings объясняют, почему чтение filesystem PNG не служит proof exported asset availability. Прямых зависимости от .scratch в продукте или production code нет.

## 4. Source/API reference inventory

| Reference | Что использовано | Ограничение |
| --- | --- | --- |
| [Godot 4.7.2 release](https://github.com/godotengine/godot/releases/tag/4.7.2-stable) | Official release context; run version и checksum закреплены отдельно | Archive supply-chain redownload NOT_RUN |
| [Image](https://docs.godotengine.org/en/4.7/classes/class_image.html) / [ImageTexture](https://docs.godotengine.org/en/4.7/classes/class_imagetexture.html) | CPU RGBA8, image data, GPU update API | update ≠ external save |
| [Resource](https://docs.godotengine.org/en/4.7/classes/class_resource.html) / [ResourceLoader](https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html) | local-to-scene, explicit change notification, cache modes | Instance equality не cross-process identity |
| [ResourceSaver](https://docs.godotengine.org/en/4.7/classes/class_resourcesaver.html) / [DirAccess](https://docs.godotengine.org/en/4.7/classes/class_diraccess.html) | Native serialized resources, compressed binary candidate, rename/replace | Документация rename не обещает power-loss transaction |
| [Texture2D](https://docs.godotengine.org/en/4.7/classes/class_texture2d.html) | Serialized texture bridge with private GPU implementation; inherited Resource RID API | Runtime proof — scratch facade, не complete addon |
| [EditorPlugin](https://docs.godotengine.org/en/4.7/classes/class_editorplugin.html) / [EditorInterface](https://docs.godotengine.org/en/4.7/classes/class_editorinterface.html) | Input return policies, apply/save lifecycle, native scene save/dirty | Hooks с void return не save veto |
| [EditorUndoRedoManager](https://docs.godotengine.org/en/4.7/classes/class_editorundoredomanager.html) | Custom context avoids global external-resource history | Exact Surface gesture lifecycle NOT_IMPLEMENTED |
| [PhysicsDirectSpaceState3D](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectspacestate3d.html) / [TriangleMesh](https://docs.godotengine.org/en/4.7/classes/class_trianglemesh.html) | Collider hit vs actual render triangle BVH refinement | Surface support не следует из collision |
| [ConcavePolygonShape3D](https://docs.godotengine.org/en/4.7/classes/class_concavepolygonshape3d.html) / [PhysicsBody3D](https://docs.godotengine.org/en/4.7/classes/class_physicsbody3d.html) | Static trimesh intended use, non-uniform-scale warning | Arbitrary transformed collision NOT_TESTED |
| [MeshDataTool](https://docs.godotengine.org/en/4.7/classes/class_meshdatatool.html) | Native vertex data alternative | Vertex-paint probe NOT_RUN, imported mesh writes rejected by design |
| [Spatial shader](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html) / [Shading language](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/shading_language.html) | NORMAL_MAP, ALBEDO, ROUGHNESS, sampler/color hints | 4.7 docs are minor-version API reference; patch-specific behavior подтверждают runs |
| [Renderer overview](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html) | Forward+/Mobile/Compatibility backend families | Desktop Mobile renderer не mobile hardware coverage |
| [MeshInstance3D](https://docs.godotengine.org/en/4.7/classes/class_meshinstance3d.html) / [GeometryInstance3D](https://docs.godotengine.org/en/4.7/classes/class_geometryinstance3d.html) | Owned instance overrides и restoration boundary | Simple API ownership test, сложные bindings future gate |
| [EditorSettings](https://docs.godotengine.org/en/4.7/classes/class_editorsettings.html) | Settings API; safe_save flag наблюдался в native probe | Setting=true не filesystem failure-injection evidence |

Primary APIs/browser sources прочитаны 23.10.2026. Source redistribution из Godot/Epic/других addon не выполнялась; harness и synthetic fixtures авторские по root MIT. Unreal — только workflow direction от owner docs, не источник переносимого shader кода.

## 5. NOT_RUN / UNKNOWN inventory

INTERACTIVE_GUI_QA: **NOT_RUN / READY_FOR_MANUAL_QA**. Полного Surface addon/UI нет, owner mouse acceptance невозможна в рамках research. Foliage regression suites заново не запускались: addon и tests не менялись, scope/hash gates обеспечивают только byte preservation. Их прошлые PASS не переименовываются в новые runtime результаты.

Также NOT_RUN: full lit PBR/slope/parity, actual mobile/low-end/Web/other OS, frame time/RSS/VRAM, sustained large-map strokes, real Surface cancel/undo transactions, full graph duplicate/fork/reimport, native failed-save injection/power-loss, export, packaging/ZIP/installation, owner scene changes. Они перечислены как необходимые gates будущего [MVP](STAGE_04_MVP_PROPOSAL.md), не как незавершённая разрешённая реализация.

Read-only preflight environment issues: PowerShell provider warning; local git ls-remote DNS failure; sandboxed linked-worktree git cwd access denied, повтор в разрешённом scoped execution прошёл; первый quoted cmd python invocation failed before execution; source-display helper encoding error исправлен на UTF-8. Они не являются Godot product defects. Точное состояние и качество итогового deliverable — [delivery](DELIVERY.md) и [quality JSON](evidence/quality.json).
