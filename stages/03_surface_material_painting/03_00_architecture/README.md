# Stage 03.00 — Surface Material Painting: architecture research

Дата: 23.10.2026. **RESEARCH ONLY. Implementation: NOT AUTHORIZED / NOT STARTED.**

Пакет для review владельца по [Issue #10](https://github.com/alekseypilishkov-gif/go_flora/issues/10). Технические решения ниже — предложения, не принятый ADR.

| Deliverable | Документ |
| --- | --- |
| A. Аудит и рекомендация | [SURFACE_03_00_ARCHITECTURE_REPORT.md](SURFACE_03_00_ARCHITECTURE_REPORT.md) |
| B. Матрица вариантов | [DECISION_MATRIX.md](DECISION_MATRIX.md) |
| C. Предлагаемый технический контракт | [TECHNICAL_CONTRACT_PROPOSAL.md](TECHNICAL_CONTRACT_PROPOSAL.md) |
| D. Ограниченный Stage 04 | [STAGE_04_MVP_PROPOSAL.md](STAGE_04_MVP_PROPOSAL.md) |
| E. CONFIRMED / INFERRED / UNKNOWN, источники, команды, FAIL | [EVIDENCE_INVENTORY.md](EVIDENCE_INVENTORY.md) |
| Git, quality gates, stop point | [DELIVERY.md](DELIVERY.md) |

Рекомендация: отдельный Surface subsystem, локальная XZ mask mapping для проверенного ground mesh, четыре устойчиво назначенных канала RGBA8; CPU Resource внутри сцены — единственный источник весов. Собственный ShaderMaterial и сериализуемая Texture2D-обёртка с пересоздаваемым GPU-кэшем. Внешние PNG/.res маски и общий brush framework отложить.

Все исполнявшиеся эксперименты находятся в игнорируемой `.scratch/surface0300/`. В Git включены только отчёты, логи, контрольные суммы и текстовые листинги проб/сериализации; постоянной ручной QA-сцены нет.

**INTERACTIVE_GUI_QA: NOT_RUN. READY_FOR_MANUAL_QA** относится только к будущей интерактивной приёмке, а не к утверждению существования Surface продукта. Итог исследования: **READY_FOR_OWNER_ARCHITECTURE_REVIEW**, с открытыми implementation gates из proposal. Stage 04 требует отдельной задачи владельца.
