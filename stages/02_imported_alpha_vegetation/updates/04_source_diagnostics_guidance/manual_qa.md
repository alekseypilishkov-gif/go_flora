# Ручная приёмка 0.2.4-dev — Source Diagnostics (GUI-13.3 adaptive layout)

**INTERACTIVE_GUI_QA: NOT_RUN. READY_FOR_MANUAL_QA.** Это чек-лист владельца в существующем TEST_FLORA; automated Editor API не заменяет мышь, навигацию или сохранение реальной сцены.

## Установка через Проводник Windows

1. Закройте Godot с TEST_FLORA и сделайте backup его `addons\go_flora` вне проекта.
2. В Проводнике откройте `C:\Dev\GO_FLORA\stages\02_imported_alpha_vegetation\updates\04_source_diagnostics_guidance\.scratch\packages`.
3. Убедитесь, что выбран `GO_FLORA_stage02_0.2.4-dev_a0f7ea1c.zip`; его SHA-256: `22a3a2957f0bfcb6ade623c3aa4c369d1b4b23f715c561ce2e5e8ed8d9a551b4`. Извлеките ZIP во временную папку.
4. Скопируйте извлечённую `addons\go_flora` в `C:\Dev\TEST_FLORA\addons\go_flora`, подтвердив замену. Не создавайте вложенность `addons\addons`.
5. Откройте исходную сцену, дождитесь import и проверьте в Project Settings → Plugins версию **0.2.4-dev**.

## Source Diagnostics

- [ ] На экранах 1280×720 и 1920×1080 откройте палитру и `Source diagnostics / review revision`; убедитесь, что окно не выходит за рабочую область, а selector, Copy/Inspector (когда применимы) и OK остаются достижимыми.
- [ ] Для короткого Static READY и Reviewed READY убедитесь, что `Технические сведения` находится непосредственно после guidance, без высокой пустой области перед toggle. При раскрытии details должны занять оставшуюся высоту до action-row.
- [ ] Для длинных Review Required и Revision Mismatch guidance прокрутите текст; откройте и закройте `Технические сведения`, убедитесь, что long guidance имеет собственную прокрутку, details используют оставшуюся высоту и окно не растягивается.
- [ ] Выберите статический Mesh/GLB: показана короткая готовность, нет инструкции по Scene Fallback; технические сведения сворачиваются и прокручиваются.
- [ ] Выберите reviewable PackedScene с scripts/collider/groups/signals: показаны шесть шагов. Copy revision кладёт revision именно этого Source; Inspector открывает тот же Source.
- [ ] До approval измените сцену/зависимость или используйте ранее одобренную revision: отображаются текущая и прежняя строки, fallback остаётся блокированным до нового review.
- [ ] После ручного review вставьте current revision в `Reviewed Scene Revision`, включите `Allow Scene Fallback` и вернитесь в diagnostics: `Status: READY`, `scene_instances: true`, есть пояснение Editor inert preview / Runtime instance.
- [ ] Для AnimationPlayer, nested/inherited scene, `@tool` script, Skeleton/skin или запрещённого render property убедитесь, что guidance объясняет blocker и не предлагает Copy как решение. Fallback сам не включается.
- [ ] Переключайте Sources в selector несколько раз: guidance, revision, технические поля и видимость Copy должны следовать выбранному Source. Проверяйте навигацию Godot, Escape и закрытие окна.

При FAIL запишите сцену, Source, точные шаги и скриншот/Output. Не объявляйте manual QA успешным без результата владельца.
