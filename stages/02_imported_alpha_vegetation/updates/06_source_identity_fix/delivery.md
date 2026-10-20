# Поставка 0.2.6-dev — Issue #18

Статус: **READY_FOR_MANUAL_QA**. **INTERACTIVE_GUI_QA: NOT_RUN**.

[PR #19](https://github.com/alekseypilishkov-gif/go_flora/pull/19) → main, ветка codex/issue-18-source-identity. Code commit: **caf41af5f83d51d8a3b32127fb1a242475468376**. Последующий commit содержит evidence/docs и изоляцию копии expected в тестовом отчёте; байты addon не меняются. PR остаётся открытым, без merge/release.

## ZIP и идентичность

- Plugin-only ZIP: `.scratch/packages/GO_FLORA_stage02_0.2.6-dev_59ce80ed.zip` (локальный артефакт; прямую ссылку владелец получает в итоговом сообщении), 59 файлов только addons/go_flora.
- [Полный per-file SHA-256 manifest](evidence/package-green/GO_FLORA_stage02_0.2.6-dev_59ce80ed.json).
- [SHA-256 file](evidence/package-green/GO_FLORA_stage02_0.2.6-dev_59ce80ed.sha256).
- SHA-256: **ffa98da66f21bc8368824f2e9a49de0ee0eff6b3e11da29925d9aa49354ce289**.
- Source digest: 59ce80edcad35dbbe61591bf62cfb952768ac4c4d9f76357dba69b1b27c87271.
- Все 59 ZIP entries совпадают с manifest и Git blobs code commit: [commit-identity.json](evidence/package-green/commit-identity.json). ZIP не коммитится и не публикуется как release.

Упаковка детерминирована: ZIP_STORED, сортированные пути, фиксированные timestamp и Unix permissions. Повторная сборка побайтно идентична. В пакет не входят fixtures, QA-сцены, .godot, tests, evidence или зависимости. Root MIT notice сохранён.

## Выполненные проверки

| Gate | Результат | Evidence |
|---|---|---|
| CRC/SHA всех файлов и воспроизводимость | PASS | [package test](evidence/package-green/installation-summary.json) |
| Три установки, backup предыдущего addon | PASS | [package test](evidence/package-green/installation-summary.json) |
| SHA demo, существующей Stage 01 сцены, project.godot и editor_layout.cfg после каждой установки | PASS | [package test](evidence/package-green/installation-summary.json) |
| Refusal ZIP traversal | PASS | [package test](evidence/package-green/installation-summary.json) |
| Standalone import + Stage 01/02 runtime установленного ZIP | PASS | [commands/logs](evidence/package-green/commands.json) |
| Полная локальная регрессия | PASS, 31 probes | [all-green](evidence/runs/all-green/summary.json) |
| Последний новый suite + fresh-process после изоляции test snapshots | PASS, 80 + 2 assertions | [identity-evidence-green](evidence/runs/identity-evidence-green/summary.json) |
| Графический native Save/Save As/thumbnail/reopen | PASS, 5 assertions | [graphics-green](evidence/runs/graphics-green/summary.json) |
| Repository + working/staged whitespace | PASS | [pre-commit](evidence/runs/pre-commit/summary.json) |
| Bash whitespace gate regression | PASS | [реальный Bash gate](evidence/runs/quality/bash-whitespace-regression.json) |
| Исторические runtime/test/stage файлы | PASS, 1960 неизменны | [scope](evidence/runs/quality-final/protected-files.json) |
| Исходный checkout | PASS, 2478 прежних файлов неизменны | [integrity](evidence/original_checkout_integrity.json) |

Committed diff проверен командой git diff --check d911087157ecaa9e3ab2b92d95049f2999aebab1...HEAD. Итоговые quality gates после добавления материалов поставки записаны в evidence/runs/delivery-gates.

## GitHub Actions

Все три workflow успешно завершены на code commit caf41af:

| Workflow | Результат | Run |
|---|---|---|
| Repository static checks | PASS | [39418879589](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/39418879589) |
| Stage 01 Godot automatic checks | PASS | [39418879904](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/39418879904) |
| Stage 02 imported assets automatic checks | PASS, включая новый Issue #18 step | [39418879786](https://github.com/alekseypilishkov-gif/go_flora/actions/runs/39418879786) |

Снимок статусов и шагов: [ci-code-commit.json](evidence/ci-code-commit.json). После evidence commit три CI повторно проверяются на итоговом HEAD; актуальные результаты привязаны к [Checks PR #19](https://github.com/alekseypilishkov-gif/go_flora/pull/19/checks). Ручная приёмка владельца не запускается CI.

## Промежуточные FAIL и границы

Все FAIL сохранены в [report.md](report.md). Дополнительно [первая установка](evidence/package/commands.json) завершилась FAIL из-за длинного Windows staging path; повтор в коротком disposable .scratch/qa018 прошёл. Это существующее ограничение installer, не изменение Source persistence.

При review JSON обнаружено совместное использование Dictionary ожиданий начального сравнения и последующего rename/reopen. Ранее проверки проходили до rename, но факт expected в итоговом JSON изменялся. Тест теперь копирует snapshot перед подготовкой reopen; новый identity-evidence-green подтверждает совпадающие неизменяемые facts. Прежние evidence не переписаны.

TEST_FLORA не изменялся. Все установки и Godot-процессы выполнялись в disposable worktree .scratch с отдельным portable editor cache. Ранняя оговорка cache и остальные ограничения описаны в [known_limitations.md](known_limitations.md). Единственная рабочая сцена приёмки владельца указана в [manual_qa.md](manual_qa.md).
