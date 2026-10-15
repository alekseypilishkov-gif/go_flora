# GO_FLORA Studio — план рабочего пространства

Дата: 15 октября 2026. **Статус: направление одобрено владельцем; архитектурный план, НЕ РЕАЛИЗОВАНО.** Этот документ не является новым принятым ADR и не разрешает разработку модулей. [ADR 0001](ARCHITECTURE_ADR_0001.md) сохраняет статус ACCEPTED.

## Разделение рабочих задач

GO_FLORA Studio планируется как отдельное большое рабочее пространство внутри Godot для создания ассетов растительности. Компактный Foliage Painter остаётся рядом с Inspector и выполняет размещение в 3D viewport. Создание текстур, материалов и моделей не должно превращать Painter в многостраничный редактор, вытесняющий Inspector/FileSystem/Output.

| Будущий компонент | Предлагаемая задача | Граница |
| --- | --- | --- |
| Tree Generator | Контроль формы дерева/куста, топологии, Seed и полигонального бюджета; подготовка конечных вариантов | Stage 03 остаётся отдельной будущей задачей. Tree3D — возможный необязательный provider после provenance/license review, не обязательная зависимость Painter |
| Retro Texture Processor / Texture Lab | Подготовка resolution/palette/dither/alpha-cutout профилей для PS1/PS2-подобного художественного стиля | [Отдельный draft](RETRO_TEXTURE_PROCESSOR.md); переиспользование алгоритмов требует одобрения, никакой код upstream в эту задачу не переносится |
| Material Library | Создание и переиспользование наборов текстур/материалов для растительности и будущих Surface Layers | Общие material assets не должны содержать индивидуальные painted masks сцен |
| Atlas Builder | Компоновка атласов, UV region, gutters и проверка mip/filter поведения | Предложение; не объявлять поддержку автоматического atlas packing на основании уже реализованных AlphaCard atlas regions |
| Bake & Export | Получение обычных Mesh/Source/material/texture assets из результатов модулей и их проверяемый экспорт | Форматы, ownership, dependency closure и round-trip gates ещё требуют решения |

Tree Generator должен показывать Seed, фактическую геометрию и проверяемый polygon budget; нельзя обещать конкретное качество/производительность до прототипа. Художник явно сохраняет или обновляет ассет. Изменение рецепта не должно молча регенерировать сохранённые placement IDs/варианты в сцене; точный контракт Bake/Reapply требует отдельного решения.

## Painter и будущий Surface mode

Существующий Foliage Painter сохраняет VegetationLayer3D, именованную палитру, Mix/Selected, Paint/Erase/Single и scene Undo/Redo. Будущий Surface mode получает отдельную материальную палитру и данные; подробности — [Surface Material Painting DRAFT v0.1](SURFACE_MATERIAL_PAINTING_DRAFT.md).

Предлагаются взаимоисключающие Foliage/Surface инструменты: один жест ЛКМ не должен обрабатываться двумя кистями. Навигация Godot, modal dialogs и переключение сцены требуют общих правил владения input, но сохранённые данные и transactions подсистем остаются независимыми. Точное расположение Studio main-screen, переключателей и общих assets — будущий UX review, не реализованный интерфейс.

## Что ещё решить

- UI lifecycle и способ открытия Studio без регрессии компактного Painter.
- Provider/recipe API, topology controls, кэш вариантов и представление polygon budget.
- Ownership исходных и generated assets, безопасная запись, provenance и лицензии каждого источника.
- Контракт Material Library/Atlas/Bake, поддерживаемые форматы и shader backends.
- Порядок реализации модулей: [Roadmap](ROADMAP.md) не меняет Stage 03/04/05; Surface Painting пока отдельный backlog без финального номера этапа.

Источники направления: прямая задача владельца Git Integration & Merge от 15.10.2026; [проектный Surface draft v0.1](https://docs.google.com/document/d/1fkWorFG1pNALeVlCUWD2sTk9DmHgrMl7ZeCuVeohDaA/edit), разделы 2/10/11; [Issue #10](https://github.com/alekseypilishkov-gif/go_flora/issues/10). Наличие этих документов не является разрешением на Stage 03 или код новых систем.
