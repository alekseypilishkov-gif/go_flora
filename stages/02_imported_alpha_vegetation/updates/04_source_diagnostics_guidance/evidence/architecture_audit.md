# Целевой архитектурный аудит — Issue #13

Дата: 16 октября 2026. Scope: typed diagnostic contract для Scene Fallback и Source Diagnostics; проверка выполнена отдельно от runtime-probes `runs/final1`.

## Результат: PASS

P1/P2 замечаний не осталось. Изменение остаётся диагностическим: new fields существуют только в памяти `GFSourceResolution` и не входят в `GFVegetationSource`, `GFInstanceRecord`, schema, source fingerprint или renderer cache.

## Проверенные инварианты

1. `status`, `revision`, `parts`, `scene` и `capabilities` сравниваются с pinned `main` `fecf4fc9dd3e04aa79bf0d7b390dc24b3ab6511b` в двух изолированных проектах. Итог: идентичны (`resolver_legacy_contract_parity: PASS`).
2. Resolver назначает `REVIEW_REQUIRED` только после прохождения существующего allowlist. `REVISION_MISMATCH` требует непустую сохранённую revision, отличающуюся от текущей; `REVIEWED_READY` устанавливается после уже существующих exact-revision и opt-in проверок.
3. Неподдерживаемые nodes/properties/render/mesh features, nested/placeholder структуры и `@tool` scripts получают `HARD_UNSUPPORTED` и typed reason. Неизвестная причина остаётся fail-closed.
4. UI выбирает guidance исключительно через `diagnostic_state` и `blocking_reason`; массив свободного текста `diagnostics` выводится только в технических сведениях. Для hard blocker кнопка копирования скрыта, а текст прямо исключает «скопировать revision» как обход.
5. UI не пишет `allow_scene_fallback` или `reviewed_scene_revision`, не инстанцирует scene и не вызывает пользовательский script. Inspector остаётся единственным путём ручного изменения разрешения.
6. Проверены native Editor API: пять текстовых сценариев, выбор другого Source, привязка Copy/Inspector к выбранному Source, collapsible technical details и прежний modal lifecycle. Это не проверка физической мыши/навигации.

## Остаточный риск

Реальная компоновка и действия мышью в окне Godot требуют owner manual QA. Статус этого вида проверки — `INTERACTIVE_GUI_QA: NOT_RUN`.
