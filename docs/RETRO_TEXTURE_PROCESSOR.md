# Retro Texture Processor / Texture Lab — DEFERRED HISTORICAL DRAFT

> **Product pivot, 23.10.2026:** research below is retained for provenance/history only. Creating/retro-converting texture assets inside GO_FLORA is **not an active direction or Surface Painter MVP prerequisite**. The plugin consumes ready-made materials/textures. See [owner product decision](PRODUCT_DIRECTION_20261023.md) and [Roadmap](ROADMAP.md).

Дата: 15 октября 2026. **Только архитектурное предложение. Не реализовано; код, библиотеки и assets не копировались и не интегрировались.** Модуль относится к будущему [GO_FLORA Studio](GO_FLORA_STUDIO.md). Точный implementation scope, язык/способ переноса и acceptance gates требуют отдельной задачи владельца.

## Первоисточник и проверка лицензии

Кандидат для изучения алгоритмов: [Captain4LK / SoftLK-tools](https://github.com/Captain4LK/SoftLK-tools), SLK_img2pixel. Проверенный upstream `master` на 15.10.2026: **`783b808a14fa50228bac0d9f2c7f948ce325e378`**. SHA получен read-only `git ls-remote`; сборка и runtime upstream — **NOT_RUN**.

Проверены фиксированные [README](https://github.com/Captain4LK/SoftLK-tools/blob/783b808a14fa50228bac0d9f2c7f948ce325e378/README.md), [MANUAL](https://github.com/Captain4LK/SoftLK-tools/blob/783b808a14fa50228bac0d9f2c7f948ce325e378/SLK_img2pixel/MANUAL.md) и [COPYING](https://github.com/Captain4LK/SoftLK-tools/blob/783b808a14fa50228bac0d9f2c7f948ce325e378/COPYING). Git blob SHA: README `733bbc7ba8d307afab9a6e0461e0896085706df6`, MANUAL `15432781995a6e11f9f3360fb6f75d149ada551f`, COPYING `a343ccd4335f66ace3f9a83dfff02212a84ef4f2`.

**Авторское заявление:** README относит авторский код к CC0 с исключением каталога `external`; COPYING содержит CC0 1.0 Universal. Это подтверждает заявленную лицензию авторского кода, не означает завершённый per-file аудит всех зависимостей. В README отдельно указаны сторонние библиотеки с собственными условиями, включая stb_image, tinyfiledialogs и Native File Dialog Extended. Их код и notices нельзя считать автоматически CC0. Перед возможным портированием нужен allowlist конкретных файлов/алгоритмов, отдельная проверка сторонних условий и разрешение владельца. Root MIT GO_FLORA не перелицензирует upstream. См. [общую лицензионную границу](LICENSING_DECISION.md).

## Предлагаемый GO_FLORA workflow

Ниже — проектные предложения GO_FLORA, а не уже доступные функции. Входные изображения остаются неизменными; операция создаёт новый owned результат и сохраняемый recipe. PS1/PS2 — художественные профили, не обещание точной эмуляции аппаратных ограничений консолей.

| Шаг | Предложение GO_FLORA | Что подтверждено документацией SLK_img2pixel |
| --- | --- | --- |
| Разрешение | Явный output size либо относительный масштаб, сохранение пропорций по выбору; проверяемая sampling grid | MANUAL описывает absolute/relative размер и sampling filters |
| Цветовая палитра | Ограниченная общая палитра либо palette asset пользователя; сохранять её identity и параметры recipe | MANUAL описывает редактирование/import/export палитры и генерацию цветов через clustering |
| Dithering | Выбор без dithering, ordered Bayer/cluster либо error diffusion; сравнение результата и контроля интенсивности | MANUAL перечисляет семейства ordered и error diffusion |
| Alpha-cutout | Отдельная политика порога alpha, сохранение силуэта; фон не должен загрязнять видимые края | MANUAL документирует alpha threshold; качество краёв/mips для GO_FLORA ещё требует тестов |
| Материал и атлас | Подготовить результат для явного material/atlas binding с gutters, filter/mipmap настройками и provenance | Это интеграционный план GO_FLORA, не доказанная возможность SLK_img2pixel или текущего Atlas Builder |

Стилизующую обработку albedo нельзя автоматически переносить на normal/roughness/mask data. Эти типы карт требуют отдельных правил. Предлагаются preview сравнения, profiles и детерминированный recipe; реальные repeatability/performance tests пока NOT_RUN. Альфа, atlas padding и mips проверяются на итоговом материале, а не только по картинке редактора.

## Открытые вопросы и будущая проверка

- Какие именно алгоритмы переносить, а какие реализовать независимо; стоимость GDScript/native/provider подходов без предварительного выбора зависимости.
- Цветовое пространство, alpha representation, палитра и стабильность dithering при batch обработке.
- Budget/отмена больших операций, сохранение recipe/result, переимпорт и отсутствие изменений оригиналов.
- Отдельные пиксельные/GUI проверки и license manifest до распространения производных файлов.

Исследование документации — PASS; port/build/runtime/PS1/PS2 fidelity — **NOT_RUN**. Никаких новых инструментов или интеграции исходников в этой docs-only задаче нет.
