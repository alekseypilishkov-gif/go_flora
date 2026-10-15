# Проверки обновления 0.1.2-dev

Все команды выполняются из корня репозитория. В локальном Windows запуске `python` — bundled Python, Godot — `.scratch/godot-portable/godot.exe` (аудированная 4.7.2). GUI не автоматизировался.

```powershell
python tools/prepare_stage01.py
python tools/run_stage01_tests.py --godot .scratch/godot-portable/godot.exe
python tests/probe_stage01_layout.py
python .scratch/check_update02_baseline.py
python tools/package_stage01.py
python tests/test_stage01_package.py --godot .scratch/godot-portable/godot.exe --archive <generated-ZIP>
python tools/verify_repository.py
python stages/00_source_audit/evidence/whitespace_probe.py --bash "C:/Program Files/Git/bin/bash.exe"
git diff --check
git diff --cached --check
git diff --check 8cbac98f0705a16f5746baa07f37ec2b2bae75b6...HEAD
```

`commands.json` и package command records содержат точные аргументы процессов и exit codes. В [baseline reproduction script](baseline_probe.py) сохранён точный код одноразового probe; для повторения скопировать его в корневой `.scratch/check_update02_baseline.py`, предварительно выполнить prepare/main suite. Он берёт plugin.gd из закреплённого предыдущего HEAD `51b137434c143b21f02a53430a00687f37c76395` в отдельную временную копию с новым harness. `baseline_expected_fail.log` содержит ожидаемый FAIL: старая позиция, рост ширины, отсутствие поля дальности. Ошибок парсинга/исключений нет.

`layout_cached_position.json` дополнительно показывает, что старый сохранённый dock-slot может пережить смену начальной позиции в plugin.gd. Native suite использует изолированную раскладку и отдельно проверяет общую группу Scene/Import. Обновление не переписывает `.godot/editor/editor_layout.cfg` владельца.

Первые Paint-действия подтверждены владельцем в чате; новая раскладка и полная GUI-приёмка остаются NOT_RUN. Предыдущая evidence не изменялась. Содержимое живого TEST_FLORA не обновлялось, подготовлен только архив.
