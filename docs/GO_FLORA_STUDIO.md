# GO_FLORA Studio — исторический план рабочего пространства (DEFERRED)

> **SUPERSEDED AS ACTIVE SCOPE — 23.10.2026.** The original Studio design below is retained as historical research only. GO_FLORA now prioritizes existing Foliage/Object Painter plus upcoming Surface Material Painting and later Mesh Paint. Full tree/shrub/texture/material generation is **out of active scope**. See [owner product direction](PRODUCT_DIRECTION_20261023.md), [Roadmap](ROADMAP.md) and [Surface DRAFT](SURFACE_MATERIAL_PAINTING_DRAFT.md). Studio, if ever developed, is an optional workspace for selecting/managing PREPARED assets, not a dependency for the Surface MVP.

Дата: 15 октября 2026. **Статус: направление одобрено владельцем; архитектурный план, НЕ РЕАЛИЗОВАНО.** Этот документ не является новым принятым ADR и не разрешает разработку модулей. [ADR 0001](ARCHITECTURE_ADR_0001.md) сохраняет статус ACCEPTED.

## Разделение рабочих задач

Исходная идея 15.10.2026 предполагала отдельное большое рабочее пространство для создания ассетов растительности; эта часть теперь архивная, не план работ. Компактный Foliage Painter остаётся рядом с Inspector и выполняет размещение в 3D viewport. Создание текстур, материалов и моделей не должно превращать Painter в многостраничный редактор, вытесняющий Inspector/FileSystem/Output.

| Будущий компонент | Предлагаемая задача | Граница |
| --- | --- | --- |
| Tree Generator — OUT OF ACTIVE SCOPE | Архивные требования к деревьям/кустам и Seed | Stage 03 теперь Surface Architecture; Tree3D не включать в плагин как цель этого roadmap |
| Retro Texture Processor / Texture Lab — DEFERRED | Сохранить прежнее исследование style profiles | [Исторический draft](RETRO_TEXTURE_PROCESSOR.md); не часть Surface MVP |
| Material Library — OPTION LATER | Выбор и группировка уже готовых материаловых слоёв для Surface/Foliage | Общие material assets не содержат scene-specific masks; генерация материалов с нуля не входит в roadmap |
| Atlas Builder — OUT OF ACTIVE SCOPE | Архивная идея auto-packing | Существующие AlphaCard atlas regions остаются; новый automatic atlas generation не планируется |
| Bake & Export — OUT OF ACTIVE SCOPE | Архивный workflow генераторов | GO_FLORA импортирует готовые файлы; не создаёт production mesh/material/texture pipelines |

Историческое требование (до 23.10): Tree Generator должен был показывать Seed, геометрию и проверяемый polygon budget. Реализация отменена как текущий продуктовый приоритет. Художник явно сохраняет или обновляет ассет. Изменение рецепта не должно молча регенерировать сохранённые placement IDs/варианты в сцене; точный контракт Bake/Reapply требует отдельного решения.

## Painter и будущий Surface mode

Существующий Foliage Painter сохраняет VegetationLayer3D, именованную палитру, Mix/Selected, Paint/Erase/Single и scene Undo/Redo. Будущий Surface mode получает отдельную материальную палитру и данные; подробности — [Surface Material Painting DRAFT v0.1](SURFACE_MATERIAL_PAINTING_DRAFT.md).

Предлагаются взаимоисключающие Foliage/Surface инструменты: один жест ЛКМ не должен обрабатываться двумя кистями. Навигация Godot, modal dialogs и переключение сцены требуют общих правил владения input, но сохранённые данные и transactions подсистем остаются независимыми. Точное расположение Studio main-screen, переключателей и общих assets — будущий UX review, не реализованный интерфейс.

## Что ещё решить

- UI lifecycle и способ открытия Studio без регрессии компактного Painter.
- Provider/recipe API, topology controls, кэш вариантов и представление polygon budget.
- Ownership исходных и generated assets, безопасная запись, provenance и лицензии каждого источника.
- Контракт Material Library/Atlas/Bake, поддерживаемые форматы и shader backends.
- Обновлённый [Roadmap](ROADMAP.md): Stage 03 Surface Architecture RESEARCH ONLY, Stage 04 Surface MVP при отдельном owner approval; все генераторы выведены из активной очереди.

Источники направления: прямая задача владельца Git Integration & Merge от 15.10.2026; [проектный Surface draft v0.1](https://docs.google.com/document/d/1fkWorFG1pNALeVlCUWD2sTk9DmHgrMl7ZeCuVeohDaA/edit), разделы 2/10/11; [Issue #10](https://github.com/alekseypilishkov-gif/go_flora/issues/10). Наличие этих документов не является разрешением на Stage 03 или код новых систем.
