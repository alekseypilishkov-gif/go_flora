# Issue #16 — известные ограничения

- **INTERACTIVE_GUI_QA NOT_RUN**: значок Node, читабельность tooltip/dock и фактическое переключение вкладки Inspector мышью принимает владелец. Автоматизация использует headless Godot и native Editor API.
- Полные legacy render_diagnostics сохранены, включая подробные повторы на records. Ограничение применяется к новому Node каналу и контексту Painter; очистка debug данных не входит в эту задачу.
- Новый канал не сериализуется. Существующий editing_diagnostic() имеет приоритет для повреждённых records/schema/configuration. Его формат и политика не менялись.
- Node output ограничен 8 группами + сводкой; поля свыше 64 символов и сообщение свыше 512 сокращаются. Полные Source/Set IDs проверять в ресурсах; Painter context до 800 символов.
- Snapshot parity проверяет конкретные автоматические fixtures, не все возможные сторонние assets. GPU/FPS, физическая GUI-приёмка и миграция реального TEST_FLORA: **NOT_RUN**.
- Защитная ветка FALLBACK_ROOT_INVALID сохранена как actionable категория; текущий resolver обычно отклоняет не-Node3D раньше. Правила fallback не расширялись.
- Независимая идентичность физического .tres и embedded Source, Issue #15, очистка архивов и Stage 03 не входят в scope.
- PR зависит от ce3391049e4427625c70b6ffe145b2aaa7ab91dc в открытом PR #14. Merge/release и изменение базы PR #14 не выполняются.
