# GO_FLORA

An editor-first, terrain-independent 3D vegetation workflow for Godot: reusable plant sources, weighted palettes, editable placement records, and spatially batched rendering.

**Status: Stage 01 — READY_FOR_MANUAL_QA.** Stage 00 is accepted and merged. The initial installable Foliage Painter supports existing static Mesh sources; automated checks passed on Godot 4.7.2. Real mouse/navigation/visual acceptance is **INTERACTIVE_GUI_QA: NOT_RUN**, reserved for the owner. A vegetation generator and later stages have not been implemented.

## Install and try

Copy `addons/go_flora/` into a Godot 4.7.2 project's `res://addons/go_flora/`, then enable **GO_FLORA** in Project Settings → Plugins. Follow the [addon guide](addons/go_flora/README.md) to configure a layer, weighted sets and Mesh sources. No native extension or Tree3D dependency is required.

For the original two-set sample, run `python tools/prepare_stage01.py` from the repository root, then open `stages/01_painter_mvp/demo/project.godot` in Godot 4.7.2. Read the [demo guide](stages/01_painter_mvp/demo/README.md), [manual acceptance script](stages/01_painter_mvp/manual_qa.md) and [Russian Stage 01 report](stages/01_painter_mvp/report.md). [PR #4](https://github.com/alekseypilishkov-gif/go_flora/pull/4) is open for owner acceptance; no automatic merge.

## Repository layout

- `docs/`: product vision, architecture decisions, licensing, and roadmap.
- `stages/00_source_audit/`: research, evidence, disposable probes, and the Stage 01 proposal.
- `stages/01_painter_mvp/`: painter demo, isolated evidence, manual QA and implementation report.
- `addons/go_flora/`: initial GDScript EditorPlugin, typed data resources and disposable spatial render caches.
- `tests/`: deterministic core, fresh-process scene reopen and native headless Editor API checks; these do not prove interactive GUI behavior.
- `tools/`: small repository validation utilities.

## Development

Read [AGENTS.md](AGENTS.md) and [CONTRIBUTING.md](CONTRIBUTING.md). Work on a stage branch, record exact test commands and limitations, and submit a PR. Owner approval is required for merging, third-party integration, and later release work.

Current scope and acceptance: [Issue #3](https://github.com/alekseypilishkov-gif/go_flora/issues/3); historical research scope: [Issue #1](https://github.com/alekseypilishkov-gif/go_flora/issues/1). Original GO_FLORA code and documentation are licensed under [MIT](LICENSE), approved by the owner on 2026-10-14. The installable addon includes a copy of this license. Third-party components retain their own licenses and notices; see the [licensing inventory](docs/LICENSING_DECISION.md). No third-party assets or native libraries are distributed here.

Stage 00 results: [Russian report](stages/00_source_audit/report.md), [architecture proposal](docs/ARCHITECTURE_ADR_0001.md), [evidence and reproduction](stages/00_source_audit/evidence/README.md), and [PR #2](https://github.com/alekseypilishkov-gif/go_flora/pull/2). Audited engine baseline: Godot 4.7.2; broader compatibility is not yet verified.
