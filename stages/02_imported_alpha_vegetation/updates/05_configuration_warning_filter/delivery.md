# Поставка Issue #16

**READY_FOR_MANUAL_QA. INTERACTIVE_GUI_QA: NOT_RUN.**

[Stacked PR #17](https://github.com/alekseypilishkov-gif/go_flora/pull/17) открыт к codex/issue-13-source-diagnostics-guidance. Исходная база PR #14: ce3391049e4427625c70b6ffe145b2aaa7ab91dc. Code commit: **40123ebc7a78e5c6b42afa7cce8bb4137f3ab1ae**. Последующий delivery commit меняет только отчёт/evidence; addon не меняется.

## Проверки

| Проверка | Результат | Свидетельство |
|---|---|---|
| Локальный полный набор Issue #16 + регрессии | PASS 25/25 probes | [summary](evidence/runs/all-green/summary.json) |
| Источник тестов = addon code commit | PASS 57/57 файлов | [identity](evidence/test_source_identity.json) |
| Контракты Data/Sources/Core = база PR #14 | PASS 30/30 файлов | [scope audit](evidence/scope_audit.json) |
| Repository static CI | SUCCESS | [run 39381212132](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/39381212132) |
| Stage 01 CI | SUCCESS | [run 39381212127](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/39381212127) |
| Stage 02 CI, включая новый Issue #16 step | SUCCESS | [run 39381212169](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/39381212169), [steps](evidence/ci_code_jobs.json), [Issue16 log excerpt](evidence/runs/ci-code/stage02-issue16-excerpt.log) |
| Package integrity/reproducibility, 3 installs, standalone import, Stage01/02 runtime | PASS 6/6 | [package summary](evidence/runs/package-green/summary.json) |
| Working/staged/committed whitespace, Bash gate regression, repository validation | PASS | [реестр точных команд](evidence/probe_registry.json), evidence/runs/quality/ |
| Приёмка мышью владельцем | NOT_RUN | [manual QA](manual_qa.md) |

CI выше относится к code commit 40123eb; после доставки evidence повторно проверяется финальный HEAD, актуальные checks доступны в PR #17. [Снимок результатов code CI](evidence/ci_code_commit.json).

## Локальный plugin-only ZIP

Версия **0.2.5-dev**. Архив создан после успешных трёх CI code commit.

Локальный путь от корня репозитория:

~~~text
stages/02_imported_alpha_vegetation/updates/05_configuration_warning_filter/.scratch/packages/GO_FLORA_stage02_0.2.5-dev_af470b7a.zip
~~~

SHA-256:

~~~text
e96589795d7152085e1b80c55ba5a0ff1a7d944f5b3bee6bcc2d8cc4c2bbbf1c
~~~

[Полный manifest](evidence/package_manifest.json) содержит SHA-256 каждого из **57** файлов addons/go_flora/. [SHA sidecar](evidence/package.sha256). ZIP, соседние .json/.sha256 и disposable установки остаются в игнорируемой .scratch; в Git включены отчёт и evidence. Это локальная сборка, публикации release нет.

После прерывания первого вызова package-test тайм-аутом инструмента частичная копия сохранена под .scratch/package-test; результат помечен FAIL/interrupted в реестре. Повтор в новой .scratch/package-retry завершён PASS. Сам ZIP и код от этого не менялись.

Автоматической установки в TEST_FLORA нет. Для владельца: сохранить сцены, закрыть Godot, сделать резервную копию и проверить manifest/SHA перед установкой только addons/go_flora. Сцены, Source и project.godot не пересохранять ради удаления значка. Затем выполнить manual_qa.md и зафиксировать PASS/FAIL отдельно от автоматических тестов.

PR #14 и предыдущие tracked stage evidence сохранены. Пользовательский untracked WEBP в корне не включён в commit и не изменён. Merge/release/Stage 03 не выполнялись.
