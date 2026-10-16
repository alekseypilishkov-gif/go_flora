# GUI-13.1 — исторический owner FAIL

Источник: [комментарий PR #14 от 16.10.2026](https://github.com/alekseypilishkov-gif/go_flora/pull/14#issuecomment-6213217799). Это owner-наблюдение в `TEST_FLORA` для build `0.2.4-dev` и PR head `e733a0d39de1082bd8a32beb8bc2342768c94a24`; агент не открывал и не изменял `TEST_FLORA`.

Статус: **FAIL GUI-13.1**. При статическом `Green cone bush` с раскрытыми Technical Details диалог Source Diagnostics вырос по высоте за рабочую область, поэтому нижние action buttons и OK были недоступны. Семантическая диагностика static READY прошла отдельно; это был layout/reachability failure.

Это historical FAIL сохранён намеренно. Последующий automated evidence в `runs/layoutfix2/` подтверждает только isolated native Editor API layout regression; он не заменяет повторную owner GUI-приёмку.
