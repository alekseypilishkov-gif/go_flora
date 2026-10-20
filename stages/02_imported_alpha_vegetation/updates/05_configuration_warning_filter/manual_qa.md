# Issue #16 — ручная приёмка владельцем

**INTERACTIVE_GUI_QA: NOT_RUN. READY_FOR_MANUAL_QA.** Все шаги ниже пока NOT_RUN. Автоматические Editor API проверки не заменяют эту приёмку.

Использовать резервную/отдельную копию проекта и ZIP 0.2.5-dev из delivery.md. Установку выполняет владелец; автоматического изменения TEST_FLORA нет. До/после сверить Saved records и контрольные IDs/transforms. Не удалять render_only_sources для очистки значка.

| Шаг | Действие | Ожидание | Статус |
|---|---|---|---|
| A | Открыть корректный пустой слой с архивами READY, review-required, unsupported | Saved records 0; нет жёлтого Node warning только из-за архивов | NOT_RUN |
| B | Выбрать вручную одобренный REVIEWED_READY; открыть Source Diagnostics, разместить растения | Runtime Scene Instances работают; INFO о скриптах/коллайдерах видны в Diagnostics; нет ложной ошибки Node | NOT_RUN |
| C | Архивный неподдерживаемый Source без records, корректный Selected Source | Архив остаётся; Selected Paint доступен; нет Node warning от архива | NOT_RUN |
| D | На копии сделать asset связанного с records Source недоступным; проверить второй Set | Node warning содержит нужный Set, Source, typed category и число records; сами records сохранены. Восстановить asset — warning исчезает | NOT_RUN |
| E | Включить неодобренный Source с weight > 0 в MIX; перейти в Selected на исправный Source | MIX показывает локальную причину, Selected работает. Weight 0 / disabled / исправление Source убирают старую причину без перезапуска | NOT_RUN |
| F | На отдельном fixture много records с одной ошибкой и более 8 групп | По Source/Set одна строка, максимум 8 строк + сводка; dock/подсказка остаются читаемыми | NOT_RUN |
| Persistence | Сохранить/переоткрыть; удалить Source из палитры с подтверждением, Undo/Redo | ID/transforms/число records неизменны; архив и восстановление работают; действительная ошибка не скрывается | NOT_RUN |
| Reimport | На копии изменить ревизию одобренной сцены и переимпортировать asset, затем восстановить | REVISION_MISMATCH/UNAVAILABLE отражаются и исчезают после валидного восстановления; records сохранены | NOT_RUN |
| GUI-13.5 | Два Sources с одинаковым display_name и разными source_id; каждый выбрать в Diagnostics и нажать Edit selected Source in Inspector; повторно открыть/закрыть окно | Окно закрывается, Inspector активен с выбранным объектом; повторное открытие/закрытие без orphan window и ошибки lifecycle | NOT_RUN |

Зафиксировать PASS/FAIL для каждого шага, версию ZIP, исходный commit, скриншоты предупреждения и Source Diagnostics, число records до/после. Не принимать визуальное отсутствие значка за доказательство сохранности records без проверки данных.
