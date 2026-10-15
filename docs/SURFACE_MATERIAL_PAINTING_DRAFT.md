# Surface Material Painting — DRAFT v0.1

Дата синхронизации: 15 октября 2026. **Направление одобрено владельцем; подробный дизайн DRAFT v0.1. НЕ РЕАЛИЗОВАНО. Не окончательный ADR.** [ADR 0001](ARCHITECTURE_ADR_0001.md) остаётся ACCEPTED; schema 1 текущего Foliage Painter не изменяется. Архитектурный backlog: [Issue #10 — SURFACE.00](https://github.com/alekseypilishkov-gif/go_flora/issues/10), OPEN. Рабочая метка issue не назначает окончательный номер этапа и не меняет Roadmap.

Основной источник: [GO_FLORA — Surface Material Painting, проектный дизайн v0.1](https://docs.google.com/document/d/1fkWorFG1pNALeVlCUWD2sTk9DmHgrMl7ZeCuVeohDaA/edit), прочитан через Google Drive; modified time `2026-10-15T12:03:16.699Z`. Этот Markdown — синхронизированное проектное резюме, не объявление API стабильным. Исторические ссылки draft на незавершённый PR #6 относятся к моменту написания; [текущий статус интеграции](../stages/02_imported_alpha_vegetation/integration/2026-10-15/owner_acceptance.md) ведётся отдельно.

## Цель и независимость

Планируется рисование смешиваемыми материалами грунта, по workflow аналогичное [Unreal Landscape Paint Mode](https://dev.epicgames.com/documentation/en-us/unreal-engine/landscape-paint-mode-in-unreal-engine). Это reference поведения; код/материалы Epic не переиспользуются. Grass Ground, Dirt, Rock, Mud — материальные слои поверхности; Foliage grass — отдельные 3D размещения растений.

Будущие режимы **Foliage** и **Surface** взаимоисключающие. Surface имеет собственную палитру, target, persisted mask data и Undo/Redo. MaterialSet не является GFVegetationSet; SurfacePaintData не хранится в GFInstanceRecord. Только низкоуровневое hit selection/input orchestration может быть общим после отдельной декомпозиции. Текущий GFSurfaceTarget зависит от GFBrush/VegetationLayer3D, его нельзя считать готовым независимым Surface API.

## Предлагаемая первая поддерживаемая поверхность

Система не должна зависеть от конкретного Terrain-плагина. Первая гипотеза поддержки — наземный MeshInstance3D с подходящим коллайдером, одним явно управляемым material slot и однозначной local XZ проекцией. Transform мирового hit переводится в локальные координаты target; mapping origin/масштаб/границы и revision сохраняются явно.

Это не гарантия рисования на любой произвольной 3D геометрии. Стены, пещеры, нависания, перекрывающиеся этажи/XZ, UV islands, несовпадающие collider/render mesh, multi-material, GridMap, CSG и Terrain3D требуют отдельной support matrix/адаптеров или UNSUPPORTED diagnostics. Швы соседних mesh targets, отрицательные координаты, rotation/nonuniform scale и reimport mapping — будущие gates, не PASS.

## Слои, данные и материалы

Предложение первого прохода — до четырёх weight-blended материалов, включая базовый, с одной **RGBA8 weightmap tile** на участок. Веса нормализуются к сумме 1; пустое состояние `(1,0,0,0)` означает базовый слой, erase/нулевая сумма возвращается к нему детерминированно. Stable layer ID и явное назначение channel не должны зависеть от переименования/перестановки строки.

Snow/puddles и другие independent overlays — отдельная будущая семантика, не дополнительные нормализуемые веса той же четвёрки. Их storage/channel space, порядок и shader policy открыты. Поддержка 8+ слоёв не обещается без новых mask/shader решений и измерений.

Рабочие имена, **не существующие классы и не утверждённый API**:

| Предложение | Роль |
| --- | --- |
| SurfacePaintTarget3D | Связь с конкретным MeshInstance3D/collider/material slot и capability/mapping diagnostics |
| SurfacePaintData | Собственные schema/version, stable surface ID, target mapping/revision, references и индивидуальные painted masks сцены |
| SurfaceMaterialSet / SurfaceMaterialLayer | Переиспользуемые ссылки на материалы/текстуры и stable layer IDs, без индивидуальных весов сцен |
| SurfaceMaskTile | Постоянные bytes маски и channel mapping; конкретный формат ещё не выбран |
| SurfacePaintStrokeDelta | Before/after изменённых tile rectangles, scene/target context и один Undo/Redo на жест |

Исходные Mesh, textures и shared Material пользователя не меняются in place. Предлагается явный opt-in на owned material variant только согласованного slot, сохранение original reference и обратимое восстановление. ShaderMaterial, смешивание albedo/normal/roughness, overlays и renderer support — будущие решения, не реализация этой задачи.

## Persistence и Undo/Redo — обязательная техническая развилка

Нужен выбранный источник правды: Godot resource (`.res`) либо lossless PNG + descriptor, либо иной проверенный формат. Временный GPU ImageTexture — disposable preview. Нельзя считать обновление ImageTexture доказательством сохранения external PNG через обычный Ctrl+S.

До реализации требуется согласовать dirty state, deterministic channel mappings, ошибки/атомарность записи, сценовое владение, external-file Undo, save/reopen, отключение плагина, экспорт и восстановление missing/reimported ресурсов. Две поверхности с одним MaterialSet должны иметь независимые masks. Нельзя скрывать ошибку записи сообщением Saved или хранить обязательные данные в `.godot`, addon либо untracked scratch.

Один жест — одно scene Undo/Redo; before/after хранится по dirty rectangles, а не полная карта на каждый MouseMotion. Esc, focus loss, scene/tool/target switch должны отменять весь pending stroke. Неподходящий участок разрывает путь. Большие tiles/очереди требуют отдельных budget и memory probes.

## Координаты текстуры и связь с Foliage

Material UV/tiling определяет размер деталей albedo/normal и ретро-фильтрацию. Paint-mask mapping определяет пространственное покрытие; разрешение/фильтр маски задаются независимо. Низкое разрешение PS1/PS2-подобного albedo не требует столь же низкого mask resolution. Общая подготовка материала относится к [Studio](GO_FLORA_STUDIO.md) / [Texture Lab](RETRO_TEXTURE_PROCESSOR.md).

Будущее взаимодействие с растительностью возможно через **read-only** запрос веса Surface Layers и отдельный явный Scatter/Reconcile с preview и Undo/Redo. Рисование Dirt не должно молча удалять существующие растения или менять record IDs/seed. Locked/hand-placed records, ownership и политика пересчёта требуют независимого контракта.

## Следующие вопросы и acceptance будущего прототипа

1. Утвердить target/mapping support matrix, collider/mesh invariants и material ownership.
2. Выбрать persistent masks/атомарное сохранение; доказать полное закрытие/открытие, Undo/Redo, recovery и перенос зависимостей.
3. Проверить ground shader отдельно на Godot 4.7.2 Compatibility/Mobile/Forward+; прежний foliage alpha-scissor PASS на него не переносится.
4. Проверить нормализацию weights, base fallback, brush continuity/cancel, material reordering, transform и независимость targets.
5. Спроектировать UI/input ownership без регрессии компактного Painter и native dialogs; физическая owner GUI acceptance отдельна от native/headless checks.
6. Согласовать implementation issue, срок и номер этапа с владельцем. [Stage 03 Tree Generator → Stage 04 Optimization → Stage 05 Release](ROADMAP.md) сохраняются без перестановки.

Все перечисленные prototype/GPU/runtime/GUI проверки новой Surface системы — **NOT_RUN**. Issue #10 остаётся архитектурной задачей; этот docs-only PR не начинает разработку.
