# STAGE 01 — реальная GUI-приёмка владельцем

**INTERACTIVE_GUI_QA: NOT_RUN. READY_FOR_MANUAL_QA.** В этой поставке агент не управлял мышью Godot и не снимал скриншоты. Windows Computer Use вернул `Computer Use app approval timed out`; владелец ответил «Оставить GUI-приёмку мне». Headless/native Editor API результаты не заменяют перечисленные действия.

Результаты каждого шага заполните PASS / FAIL / NOT_RUN, указав версию Godot, commit PR, сцену и фактические наблюдения. При FAIL сохраните сцену, Godot Output/errors, снимки и точные шаги. Не переходите к Stage 02 до отдельного утверждения.

## Подготовка

Следуйте [demo README](demo/README.md): `python tools/prepare_stage01.py`, Godot 4.7.2, `demo.tscn`, GO_FLORA enabled. Сохраните копию `qa_owner.tscn`. Откройте Output. Выберите VegetationLayer и набор A; Edit Set in Inspector → Draw Distance M=0 для первой проверки. Default brush: radius=1, density=6, spacing=0,5, seed=42, yaw=0…360, scale=0,8…1,2, align=1, slope=0…60, mask=1. Убедитесь, что счётчик saved records=0.

Опциональные снимки данных: откройте `tests/manual_inspect.gd` в Script Editor, **File → Run** ([официальное описание EditorScript](https://docs.godotengine.org/en/stable/classes/class_editorscript.html)). Снимок содержит ID, set/source, transform, seed и для batches: node ID, cell, record IDs, distance, fade. Скрипт только читает текущую сцену. Сравнивайте records до/после; node ID имеет смысл лишь в одном процессе, поскольку render cache пересоздаётся после reopen. На каждый шаг нужны реальные наблюдения в 3D, даже если прикладывается JSON.

## Шаги

| ID | Действие в настоящем редакторе | Критерий | Результат |
| --- | --- | --- | --- |
| GUI-01 | Navigate: выбрать authored Ground, вращать/перемещать камеру штатными средствами Godot; набрать число в поле dock | Управление, выбор и текстовый ввод работают, размещения не меняются | NOT_RUN |
| GUI-02 | Paint A: наведитесь на Ground около origin, удерживайте ЛКМ и нарисуйте непрерывный путь длиной около 4 м | Видимый контур кисти; pending растения видны до release; saved records до release не растут; после release один commit в Output | NOT_RUN |
| GUI-03 | Paint A на синей повёрнутой/масштабированной поверхности | Hover подходит; растения следуют реальной поверхности и её нормали; до release есть preview | NOT_RUN |
| GUI-04 | Наведите Paint на жёлтую VisualOnlyNoCollision; затем mask=2; slope max=5° на синей; height min=0,5 на Ground; восстановите default | Нет eligible hit и новых records для каждого запрещённого случая; понятный статус, неподходящие клики проходят редактору | NOT_RUN |
| GUI-05 | Выберите collider Ground в дереве → Only selected collision target; попробуйте синюю. Затем Clear, Exclude selected Ground; попробуйте Ground; Clear | Include/exclude ограничивают настоящий target; другие authored узлы не изменяются | NOT_RUN |
| GUI-06 | Paint B рядом с A и в нескольких X/Z ячейках. Выберите A → Erase, ЛКМ drag по обеим группам | Удаляется только A в footprint выбранного слоя; B остаётся; pending erasure до release не удаляет persistent records; Undo возвращает A | NOT_RUN |
| GUI-07 | Single A: один полный клик, до/после запишите счётчик; затем удерживая кнопку слегка подвигайте мышь | Ровно +1 record за click/stroke. Undo убирает ровно эту запись, Redo возвращает тот же ID/transform | NOT_RUN |
| GUI-08 | Сделайте несколько завершённых Paint/Erase/Single; по очереди Undo/Redo | Каждый stroke = один шаг; прежний порядок ID/transform точно восстановлен; нет дубликатов | NOT_RUN |
| GUI-09 | Начните Paint, держите ЛКМ, нажмите Esc и отпустите. Повторите с Alt/ПКМ навигацией, с release за пределами 3D и потерей фокуса приложения | Preview отменён, saved records прежние, лишнего Undo нет; навигация не блокируется | NOT_RUN |
| GUI-10 | Сначала создайте и откройте вторую QA-сцену с layer/set. Вернитесь в A; во время pending stroke переключите сцену, например удерживая ЛКМ и shortcut перехода к соседней вкладке, назначенным в Editor Settings | Pending A отменён без commit; новый stroke B использует историю B; Undo в B не меняет A. Если сам pending-switch не выполнен — оставить этот пункт NOT_RUN | NOT_RUN |
| GUI-11 | При существующих A/B: снимок; Edit Set A → distance=10. Снимок снова, камеру 3D приблизить и отдалить от центра нарисованных ячеек (например ~5 и ~35 м) | Все **старые** A cells переключают visibility_range_end на 10, B остаётся 80. Те же records/ID/transform/count, те же batch node ID до/после этой смены; на дальнем ракурсе A скрыта, B видна | NOT_RUN |
| GUI-12 | A distance=0, затем A enabled=false/true; снова проверить прежние placements | 0 означает unlimited; enabled влияет на render, не удаляет records; B независим; fade OFF | NOT_RUN |
| GUI-13 | Снимок; Save; закройте сам Godot Editor; запустите заново и откройте QA-сцену | Те же count/ID/seed/set/transform (с допуском сериализации 1e-5), rebuilt cells без дубликатов; видимая сцена и настройки наборов сохранены | NOT_RUN |
| GUI-14 | Disable/Enable GO_FLORA в Plugins, включая disable во время pending; при необходимости снова выбрать layer/Refresh | Dock/brush исчезают при disable, pending отменён. Persistent vegetation сохраняется и отображается; enable создаёт один dock без parse/errors/orphans | NOT_RUN |
| GUI-15 | В QA-копии поверните и неравномерно масштабируйте VegetationLayer, затем переместите его; рисуйте ещё и Undo | Старые local placements следуют layer; новые попадают на collider в world space; нормали/масштаб корректны; данные не теряются | NOT_RUN |

При наличии сохранённой сцены дополнительно запустите F6, камеры 1/2 из demo README. Это полезная визуальная проверка runtime distance, но GUI-11 в 3D-редакторе всё равно нужен. Снимки/видео помещайте в этот stage evidence с описанием фактически выполненных действий; чужие или сгенерированные кадры доказательством не являются.

## Ограничения при оценке

Источник — static Mesh. Сцены/генераторы/GLB extraction, LOD, ветер, отдельные vegetation colliders, Select/Lasso/Reapply отсутствуют. Дальность действует на целый spatial batch и зависит от центра его AABB; местами можно видеть переключение целой ячейки. Радиус кисти — world metres; cell size — единицы координат слоя. При достижении bounded budget stroke останавливает работу с понятным статусом; Erase учитывает и число просмотренных records (default 2 000, maximum 20 000). Для крупной QA-сцены увеличьте бюджет. Масштабная производительность и чистая установка/export на других машинах — NOT_RUN.
