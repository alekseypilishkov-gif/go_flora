# Stage 02 — ручная приёмка владельцем

**INTERACTIVE_GUI_QA: NOT_RUN. READY_FOR_MANUAL_QA.** Автоматические native API и реальные GPU-кадры в evidence не подтверждают физические клики/навигацию/сохранение в редакторе. Здесь все строки остаются NOT_RUN до действий владельца.

Подготовьте [отдельный demo-проект](demo/README.md), Godot 4.7.2, addon 0.2.0-dev; сохраните `qa_owner.tscn`. Приёмку не выполняйте автоматически в рабочем TEST_FLORA. Запишите commit/engine/renderer, наблюдения, Output, PASS/FAIL и снимки при проблеме.

| ID | Действие | Ожидаемый результат | Статус |
| --- | --- | --- | --- |
| GUI-01 | Открыть demo, выбрать слой, вращать/перемещать камеру; открыть FileSystem/Output | Dock не растягивает минимальную высоту/ширину, не перекрывает панели и ввод/камеру | NOT_RUN |
| GUI-02 | Create Alpha Plant → собственный PNG; сделать single, затем crossed; сохранить отдельные `.tres` | Превью исходника/UV, понятные размеры/threshold; новые ресурсы в наборе | NOT_RUN |
| GUI-03 | Повторить с прозрачным WebP и atlas region X/Y/W/H; заведомо неправильный region/gutter | Правильный регион, ориентация/прозрачность; неверные параметры блокируются с диагностикой | NOT_RUN |
| GUI-04 | Нарисовать смешанные grass/flower на Ground и наклонной синей поверхности | Материал не выглядит непрозрачным прямоугольником, pivot на земле, ориентация по нормали | NOT_RUN |
| GUI-05 | Add Mesh / GLB / Scene → настоящий GLB и safe static PackedScene | Видны все части/материалы, правильные UV/transform, нет потерянных частей | NOT_RUN |
| GUI-06 | Single по разу каждым источником; Paint, Erase выбранного набора; Undo/Redo | Single +1 запись, Erase удаляет все её части; Undo/Redo возвращают прежние IDs/transforms, другой набор не затронут | NOT_RUN |
| GUI-07 | Начать Paint → Esc; повторить с навигацией, потерей фокуса, сменой сцены | Pending preview исчезает без записей/лишнего Undo; нет orphan растений | NOT_RUN |
| GUI-08 | После рисования A=15, B=80; camera near/far; затем A=0 и enabled off/on | Переключаются существующие A cells, B независим, 0 unlimited, записи не меняются | NOT_RUN |
| GUI-09 | Ctrl+S, полностью закрыть Godot, снова открыть QA-сцену; повторить GUI-08 | Те же растения/IDs/transforms/параметры, нет дубликатов | NOT_RUN |
| GUI-10 | Изменить PNG и GLB в QA-копии, выполнить reimport | Внешний вид обновлён, позиции и IDs сохранены; отсутствие файла не удаляет записи | NOT_RUN |
| GUI-11 | Изучить authored_plant.tscn и safe_behavior.gd; посмотреть C в редакторе и F6 runtime | Editor preview инертен; runtime сохраняет collider/script/signal/group. Distance/disabled скрывают только визуал, поведение и collision остаются | NOT_RUN |
| GUI-12 | Изменить reviewed scene/script; попробовать unreviewed/tool/animated scene | Новый fingerprint требует review; неподдерживаемое не маскируется под работающий fallback, записи сохранены | NOT_RUN |
| GUI-13 | После сохранения/закрытия Godot трижды обновить ZIP в одноразовой копии проекта | Меняется только addon; сцены, project.godot, dock layout прежние, backup доступен | NOT_RUN |

Рендер дальности действует на целую MultiMesh-ячейку, не на каждый экземпляр. Runtime fallback дороже и не выключает gameplay вдали. Для оценки runtimestate C можно временно вывести `ticks`/`signal_count` в отладчике QA-копии. Большой лес/FPS/export/другие GPU не входят в подтверждённые результаты.

После приёмки владелец решает о merge PR. Stage 03 и публичный релиз требуют отдельного разрешения.
