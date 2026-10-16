# GO_FLORA Issue #13 — контекстные инструкции Source Diagnostics

Дата: 16 октября 2026. Версия: **0.2.4-dev**. База: `main` / `fecf4fc9dd3e04aa79bf0d7b390dc24b3ab6511b`. Реализация: `81e4b07e12ae0fea70af16f68dbd30d0bb4aa629`. Статус: **READY_FOR_MANUAL_QA; INTERACTIVE_GUI_QA: NOT_RUN**.

## Scope и результат

Добавлено пять контекстных состояний Source Diagnostics: `STANDARD`, `REVIEW_REQUIRED`, `REVISION_MISMATCH`, `REVIEWED_READY` и `HARD_UNSUPPORTED`. `GFSourceResolution` содержит их только в памяти вместе с typed `blocking_reason`; прежний `status` и свободная техническая диагностика сохранены.

- Static READY сообщает о готовности без шагов Scene Fallback.
- Review Required показывает шесть шагов ручного review и точные имена контролов.
- Revision Mismatch показывает сохранённую и текущую ревизии и требует повторного изучения содержимого.
- Reviewed READY поясняет отличие инертного Editor preview от полного Runtime Scene Instance.
- Hard UNSUPPORTED показывает typed категорию блокировки, скрывает Copy и прямо исключает копирование revision как обход allowlist.

Технические сведения остаются прокручиваемыми и сворачиваемыми. Copy revision и переход в Inspector остаются привязаны к выбранному Source. Новое окно не меняет allowlist, revision/fingerprint, сохранённые Source fields, schema, record data, renderer или Scene Cache. Оно не включает fallback и не запускает пользовательские scripts в preview.

## Проверки

Финальный isolated run: [`evidence/runs/final1/summary.json`](evidence/runs/final1/summary.json). Godot `4.7.2.stable.official.ed1daf0bf`, executable SHA-256 `ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424`.

- **PASS** pinned-baseline parity: `status`, `revision`, `parts`, `scene`, `capabilities` идентичны `main`.
- **PASS** все пять typed диагностических состояний; `UNAVAILABLE` и `ERROR` не предлагают review.
- **PASS** hard blockers: неразрешённый node, `@tool` script, nested scene, запрещённое property.
- **PASS** смена выбранного Source, Copy/Inspector binding, technical collapse, native Editor API; прежний modal lifecycle и fresh reopen также PASS.
- **PASS** Stage 01, Stage 02, Stage 02.1 и Stage 02.3 automated regressions.
- **PASS** `git diff --check`, staged whitespace и `tools/verify_repository.py` перед source commit.

Ранние попытки `initial` и `retry1` сохранены с честным **FAIL**: были исправлены только disposable test-fixtures/harness для nested Scene и headless clipboard, не security logic. См. [evidence README](evidence/README.md). Целевой архитектурный audit: [PASS](evidence/architecture_audit.md).

## Plugin-only ZIP

Архив: `C:\Dev\GO_FLORA\stages\02_imported_alpha_vegetation\updates\04_source_diagnostics_guidance\.scratch\packages\GO_FLORA_stage02_0.2.4-dev_e3fd7c53.zip`

SHA-256: `3b018796a87abc632df574ef8c759a6e2afc04492d045ab4f47941834833d204`.

Рядом лежат полный `.json` manifest и `.sha256`; manifest подтверждает CRC и SHA-256 каждого из 55 файлов addon. Source digest: `e3fd7c5347f54223f669485c5910f4003d65fd23616ab1b4a0b709aca030f17e`; packaging HEAD: `81e4b07e12ae0fea70af16f68dbd30d0bb4aa629`. Архив содержит только `addons/go_flora/` и не является release.

## Ограничения

Три CI workflow ещё не запускались для будущего PR head и потому имеют статус **NOT_RUN** в этом отчёте. Физические mouse/navigation/save проверки выполняет только владелец в своей копии TEST_FLORA; агент её не читал и не изменял. Инструкция: [manual_qa.md](manual_qa.md).

## GUI-13.1 layout follow-up

Owner обнаружил historical GUI-13.1 FAIL после этого исходного delivery: окно Source Diagnostics выходило за рабочую область. Точечное исправление, новое automated evidence и актуальный package описаны в [layout_fix.md](layout_fix.md). Этот follow-up заменяет ZIP выше для ручной установки; interactive GUI QA вновь остаётся **NOT_RUN** до подтверждения владельца.
