# GO_FLORA 0.2.2-dev

GDScript vegetation painter for Godot **4.7.2**, MIT. Stage 02 is **READY_FOR_MANUAL_QA**, **INTERACTIVE_GUI_QA: NOT_RUN**. Copy this directory to `res://addons/go_flora/`, then enable GO_FLORA in Project Settings → Plugins. No native dependency or Tree3D is required. The plugin-only ZIP contains no scenes, textures or models.

## Add your plants

1. Create/select a `VegetationLayer3D`. In its Layer Data → Sets, create a `GFVegetationSet`, assign a unique Set ID, then Refresh Layers / Sets in the dock.
2. Import your project-local GLB/GLTF with Godot first. Click **Add Mesh / GLB / Scene…**, select the Mesh or PackedScene, and **Save Source…** as a project `.tres`. It is added to the active palette with weight 1. Static hierarchies keep every mesh, surface material and accumulated transform. Mesh Transform adjusts the authored pivot.
3. For PNG/WebP, click **Create Alpha Plant…**. Choose the texture, single/crossed/radial mode, width, vertical height, optional ±30° splay, alpha threshold and atlas rectangle in **pixels from top left**. A zero rectangle uses the full image. Radial mode accepts 3 or 4 cards. Preview shows the chosen UV region; save the reusable `.tres`.
4. The named palette shows each plant, preview, enabled checkbox and editable weight. Click a name/preview to choose **Selected source only** for Paint or Single; **Mix by weights** restores the existing weighted group. Click ↗ to inspect a source. **Open Set in Inspector** shows the active set and its named palette; existing source `.tres` references can be reused there. Stable source IDs are generated once; do not change them after painting.

## Палитра и справка

Флажок источника разрешает **новые** размещения: выключенные растения сохраняют положительный вес и все прежние записи/геометрию. Для MIX используются только включённые источники с весом > 0. Веса 3:1 означают относительную вероятность примерно 75%:25%, а не число объектов. В режиме Selected source only вес MIX не учитывается (включённый источник с весом 0 можно выбрать явно). Выключенный/отсутствующий/неподдерживаемый выбранный источник блокирует Paint/Single с диагностикой; Erase остаётся доступным. **Single** независимо от выбора источника размещает одну запись.

Изменения флажка, веса и ссылок проходят через Undo/Redo сцены. Выбор растения/режима кисти временный: он не изменяет entries, IDs, веса или прежние размещения. Переименование обновляет подпись палитры; source_id остаётся прежним. У каждого растения есть подсказка типа/ID и ↗ для его Inspector. Нативные поля набора Enabled, Density Multiplier и Draw Distance остаются редактируемыми; кнопка справки рядом объясняет их действие.

Основные поля кисти, палитры и Create Alpha Plant имеют русские всплывающие подсказки с единицами, defaults и примерами. **Help / Справка** открывает легенду по клику. **Ctrl+Alt+G** показывает GO_FLORA. Open Set in Inspector переключает на Inspector через публичный API Godot, даже когда палитра занимает ту же группу вкладок.

Cards use ground pivot Y=0, owned mesh/material, double-sided **alpha-scissor**, linear filtering with mipmaps, clamp, default threshold 0.5. Texture originals are referenced and never rewritten. Set texture Import → Mipmaps → Generate when desired; supply extruded atlas gutters. UV Gutter is an inward pixel inset; 0.5 px avoids sampling the boundary, while stronger minification may require larger gutters (tested diagnostic atlas: 8 px at 3/12/24 m). A gutter cannot repair a tightly packed/poorly padded atlas. Width/height control aspect explicitly. Alpha-hash is not exposed: Compatibility has a historical failing pixel probe.

## Выбор файла и окна создания

В 0.2.2-dev исправлен конфликт эксклюзивных окон из 0.2.1-dev. В SourceAssetPicker используйте штатные **Quick Load…** (поиск имени и выбор результата/Enter) или **Load…** для PNG/WebP и Mesh/GLB/PackedScene. Окно создания — неэксклюзивный инструмент редактора; штатные choosers сохраняют модальность. На время операции кисть приостановлена, фоновые клики viewport не создают strokes.

**Save Source…** временно скрывает черновик и открывает отдельный модальный EditorFileDialog. **Cancel** в сохранении возвращает те же настройки и Source ID, без добавления в палитру. Cancel/X/Escape окна создания отменяют черновик. Смена слоя/набора/сцены, Help/diagnostics или отключение плагина освобождают его окна; окно Godot, открытое другим инструментом, не закрывается. Успешное сохранение добавляет источник ровно один раз с одним Undo/Redo; повторное уведомление не создаёт дубликат. Старые размещения и схема данных остаются прежними.

## Scenes with authored behavior

SceneState is inspected without instantiating nodes. Scripts, signals, groups and colliders are never silently flattened. A source can be saved for review even when blocked. **Source diagnostics / revision…** shows full selectable status/reasons/references and a **Copy revision** button. Inspect the scene **and all scripts**, then enable **Allow Scene Fallback** in Source Inspector and paste that exact revision into **Reviewed Scene Revision**. File/dependency changes invalidate the approval.

Supported fallback is deliberately narrow: Node3D / MeshInstance3D / StaticBody3D / CollisionShape3D, ordinary non-tool scripts and internal signals/groups. Runtime creates real scene instances with original processing/collisions, and reuses them across static cache rebuilds. It is more expensive than MultiMesh. Set visibility/distance changes only geometry; invisible plants keep gameplay processing/collisions. Deleting a placement destroys its scene; a source revision change replaces it. Script runtime state is not persisted independently of placement data.

**In the editor fallback is an inert mesh preview**: scripts do not execute and authored colliders are absent. Run the scene to inspect behavior. Animation, skeleton/skin, blend shapes, particles, lights, tool scripts, inherited/nested scenes, >256-node hierarchies, per-instance shader parameters and unreviewed render/node properties remain explicitly unsupported. Transform components are supported; combining `transform` with component aliases is rejected. Godot resource loading itself is trusted; this is not a sandbox for hostile project files.

## Paint and save

Choose layer/set, Paint/Erase/Single. LMB drag paints/erases; Single click adds one record. Release commits one scene undo step, Esc cancels pending preview. Navigate and RMB/MMB/Alt/Ctrl pass editor navigation through. Ordinary and tilted collision-backed surfaces are supported; visible geometry without collision is not itself a target. Mask, slope, height, normal alignment, seed, scale/yaw and weighted palettes use the existing deterministic painter.

**Draw distance (m)** remains directly below the active set. 0 = unlimited. It updates existing geometry of that set without moving/deleting records. Each static MultiMesh cell is culled as a whole; this is not per-instance culling. Fallback uses each authored GeometryInstance's range. Gameplay processing/collisions are independent of rendering distance.

Records/IDs/transforms remain authoritative schema 1. One record may render several parts. Save the scene normally; caches are internal/unowned and rebuilt on reopen. Reimport changes derived assets without regenerating placement positions. Missing resources and future/corrupt schema report diagnostics and retain records. Erase still works when a palette source is unavailable. Source/set IDs must stay unique. Stage 01 enum values 0/1/2 keep their original meanings; old unsupported values are not automatically promoted.

The default dock slot is now **right, alongside Inspector**, with bounded 260×120 px minimum and scrolling. Godot restores saved custom arrangements. If an upgraded project restores the old left placement, drag the GO_FLORA tab to Inspector once; the plugin does not reset/write layout files. Work budget defaults to 2,000 samples/stamps (max 20,000); Erase also limits scanned records. Topology edits still rebuild static cells. Large-forest optimization, LOD and wind are outside Stage 02.

## Update safely

Save scenes and close Godot. Extract a verified plugin-only ZIP at the project root, or use the repository's optional `tools/install_stage02.py` with a selected project/archive. The script verifies CRC/SHA/path allowlist, moves the old addon to a timestamped `.scratch/go_flora_updates/.../previous/go_flora` backup and installs only the addon. It does not write scenes, project.godot or saved dock layout; on a fresh project enable the plugin yourself. Keep the ZIP's adjacent `.json` manifest for the script. No automatic update of the owner's TEST_FLORA is performed.
