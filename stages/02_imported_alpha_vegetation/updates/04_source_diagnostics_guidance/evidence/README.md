# Evidence — Issue #13

Все пробы запускаются в disposable-копиях Stage 01/02 demo из `C:\Dev\GO_FLORA\.scratch\qa013`; `TEST_FLORA` не читается и не изменяется. Godot: `4.7.2.stable.official.ed1daf0bf`, SHA-256 `ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424`.

- `runs/initial` — **FAIL**: первая test-fixture не сериализовала nested instance; фактическая проверка получила пустую сцену. Никакая product-логика не менялась этим исправлением.
- `runs/retry1` — **FAIL**: nested fixture исправлена, но headless display server не поддерживает системный clipboard, а harness не создал `res://.scratch` перед записью результата. Product UI теперь хранит выбранную revision на runtime-кнопке для native API проверки без обращения к clipboard; файл результата создаётся в harness.
- `runs/retry2` — **PASS**: контракт, Stage 01/02/02.1/02.3, диагностика Editor API и прежний modal lifecycle.
- `runs/final1` — **PASS**: повтор `retry2` после финального изменения plugin version и документации. Это итоговый runtime evidence.

`summary.json` каждой попытки содержит точную команду, exit code и статус каждого запуска. `.log` сохраняют полный Godot output. `initial` и `retry1` сохранены намеренно: evidence не переписывается после исправления тестовой инфраструктуры.
