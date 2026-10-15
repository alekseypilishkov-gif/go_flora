# Stage 01 — исправление dock и отдельный тестовый проект

2026-10-15. Версия addon **0.1.1-dev**. Статус **READY_FOR_MANUAL_QA**, **INTERACTIVE_GUI_QA: NOT_RUN**. Исправление продолжает [PR #4](https://github.com/alekseypilishkov-gif/go_flora/pull/4), Stage 02 не начат.

## Наблюдённая ошибка

Владелец предоставил [настоящий скриншот редактора](evidence/owner_gui_before.png): FileSystem/Output и GO_FLORA не видны, Inspector пустой. Это **GUI FAIL до исправления**, а не успешная GUI-приёмка. Файл скопирован без редактирования; [происхождение и SHA-256](evidence/owner_gui_before_provenance.json).

Native headless Editor Control geometry воспроизвела причину: минимальная высота VBox dock GO_FLORA **6 282 px**. Автоматически перенесённые Label до layout могут иметь большую минимальную высоту даже в невыбранной вкладке. Скролл только числовых полей не ограничивал размер всей панели. Общий dock split расширялся вниз, FileSystem начинался на Y=3 246 при фактическом base control 1024×600. Отключение addon возвращало FileSystem внутрь окна. [Измерение до исправления](evidence/layout_before.json).

Весь dock теперь помещён в один ScrollContainer с минимальной высотой **120 px**, а содержимое прокручивается целиком. После исправления FileSystem находится на Y=359…590 внутри того же base control; [измерение после](evidence/layout_after.json). Это проверка настоящих native Control/API в headless Editor, **не** визуальный повторный тест владельца. **GUI layout retest: NOT_RUN**.

Проверка regression не ослаблена: новый harness запущен в изолированном проекте со старым `plugin.gd` из commit `5550ad5`. Старый вариант завершился с exit=1 и провалил ровно две новые проверки высоты/границ; [ожидаемый FAIL baseline](evidence/legacy_regression_expected_fail.log). Исправленный вариант проходит все 19 checks.

## ZIP и установка

По просьбе владельца плагин передаётся локальным ZIP, а ручная работа продолжается в **`C:/Dev/TEST_FLORA`**. Архив содержит только `addons/go_flora/`: 31 собственный файл с MIT, без demo/tests/cache/native зависимостей и без стороннего искусства. SHA-256:

`478debec228a1e3104a5aaf6881ed57ed986120876b025caa70a995938e34b36`

Файл: `stages/01_painter_mvp/.scratch/packages/GO_FLORA_stage01_0.1.1-dev_25317a9d.zip`. Архив и sidecar metadata остаются ignored build outputs; это **не публикация release**. [Манифест содержимого](evidence/package_manifest.json). Сборка воспроизводима: фиксированные ZIP timestamps/порядок, CRC и SHA-256 каждого member проверяются после упаковки.

Две локальные Windows-сборки дали одинаковый SHA выше. У ZIP, созданного Linux CI, контейнерный SHA другой: `53861a7ef3c634bca6c45b2151fe067ec2d176d66ff0d91617b28ab3eba307cc`. Для каждого архива используйте его собственные sidecar SHA/manifest; битовая идентичность ZIP между ОС не заявляется. CI отдельно проверил извлечённые файлы и standalone import/runtime smoke.

В указанный владельцем проект установлен этот ZIP и создана `res://go_flora_stage01_demo/demo.tscn`: два original primitive Mesh, два набора, Ground и наклонная/масштабированная collision surface, жёлтая поверхность без collision. Большая Label3D-подсказка из старой demo убрана, чтобы не заслонять поверхность при стандартном ракурсе редактора. A изначально имеет unlimited distance=0, B=80; после рисования проверяются A=20/B=80. Runtime камеры 1/2 находятся примерно в 10,5/44,8 м от origin. Цвет Mesh не идентифицирует набор — рисуйте A и B в разных местах.

Конфигурация существующего проекта сохранена: Forward Plus, D3D12, Jolt, name/icon/stretch не менялись. Добавлено включение addon и main scene, поскольку ранее main scene отсутствовала. Перед установкой исходный `project.godot` скопирован в workspace backup; [установленные пути, хеши и backup](evidence/owner_project_installation.json). Кэши/раскладка внешнего проекта не редактировались и реальный GUI редактор агентом не управлялся.

Скрипт установки при повторном запуске обновляет addon, делает backup, но **не перезаписывает существующие сцену, камеру и QA helper** владельца. Отдельный regression test добавляет маркер в сцену, повторяет установку и сравнивает SHA-256 сцены. Дальнейшие ZIP-обновления также должны менять только addon, сохраняя рабочую сцену.

## Проверки

| Область | Статус | Доказательство |
| --- | --- | --- |
| Core, physics, deterministic records, deltas, set distance | PASS | 45 прежних assertions повторно выполнены на Godot `4.7.2.stable.official.ed1daf0bf`; [core results](evidence/core_results.json) |
| Native Editor API / lifecycle | PASS | 19 checks, включая новые ограничения min-height и FileSystem bounds; [results](evidence/editor_api_results.json), [log](evidence/editor_api.log) |
| Save → fresh-process reopen | PASS | [fresh_reopen.log](evidence/fresh_reopen.log) |
| ZIP CRC / member SHA-256 | PASS | package script проверил все 31 member; manifest выше |
| Standalone ZIP import / scene smoke | PASS | Изолированная копия конфигурации внешнего проекта, addon извлечён именно из ZIP; [commands/exits](evidence/standalone_zip_validation.json). Это headless smoke, не GPU/visual acceptance |
| Повторное обновление сохраняет QA-сцену | PASS | `tests/test_stage01_package.py` сравнил хеш сцены с маркером до/после повторной установки; отдельный ZIP import/runtime smoke также PASS |
| Установка во внешний проект | PASS | Сравнение всех installed addon file hashes с манифестом; source settings сохранены |
| Actual mouse / GUI layout retest / visible distance | NOT_RUN | Владелец продолжит ручную приёмку в TEST_FLORA |
| GitHub Actions новой версии | PASS | Commit `73cad0427c6037141102bfcf254343cb9c16be2e`: [static checks](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/38678737057) и [Godot + ZIP checks](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/38678737014), все steps success. Linux automation не означает GUI/export acceptance |

Все новые статусы отдельно отражены в [results.json](evidence/results.json). Исходный отчёт/evidence Stage 01 остаются историей версии 0.1.0-dev; Stage 00 не изменён. Логи этой поставки нормализуют ANSI/trailing whitespace без изменения статусов и измерений. Новые CPU cache timings — только headless CPU measurements в core_results; GPU/FPS и взаимодействие с GUI не проверены.

Fix/package implementation commit: [`73cad0427c6037141102bfcf254343cb9c16be2e`](https://github.com/alekseypilishkov-gif/go_flora/commit/73cad0427c6037141102bfcf254343cb9c16be2e). [CI metadata](evidence/ci_summary.json), [artifact с логами и plugin ZIP](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/38678737014/artifacts/11947771763). Последующее изменение документации фиксирует эти результаты; реальные GUI-действия остаются NOT_RUN.

## Воспроизведение

Из корня GO_FLORA:

```text
python tools/prepare_stage01.py
python tools/run_stage01_tests.py --godot <Godot-4.7.2-executable>
python tests/probe_stage01_layout.py
python tools/package_stage01.py
python tests/test_stage01_package.py --godot <Godot-4.7.2-executable>
python tools/install_stage01_test_project.py --project <owner-test-project> --archive <generated-ZIP>
python tools/verify_repository.py
git diff --check
git diff --cached --check
git diff --check origin/main...HEAD
```

`probe_stage01_layout.py` предназначен для данного Windows baseline и локальной portable-копии `.scratch/godot-portable/godot.exe`; CLI resolution — запрос, фактический headless Control size указан в JSON. Скрипт работает только в отдельном ignored probe project. Реальный TEST_FLORA не запускался headless: native-проверки выполнены на его изолированной копии, чтобы не менять кэш открытого проекта владельца.

В старой demo сохранён пользовательский `qa_owner.tscn`; теперь он игнорируется Git как локальный QA output. Посторонний пользовательский WebP в корне репозитория не изменяется и не включается в PR/ZIP. Никакие файлы Blender-проекта не затрагивались.
