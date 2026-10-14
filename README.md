# GO_FLORA

An editor-first, terrain-independent 3D vegetation workflow for Godot: reusable plant sources, weighted palettes, editable placement records, and spatially batched rendering.

**Status: pre-development. Installation: not yet available.** Stage 00 covers research, source/license audit, architecture, and isolated technical probes only. There is no production foliage painter or vegetation generator.

## Repository layout

- `docs/`: product vision, architecture decisions, licensing, and roadmap.
- `stages/00_source_audit/`: research, evidence, disposable probes, and the Stage 01 proposal.
- `addons/go_flora/`: reserved for a future approved plugin; no production implementation yet.
- `tests/`: reserved for future plugin validation; Stage 00 probes stay in their stage directory.
- `tools/`: small repository validation utilities.

## Development

Read [AGENTS.md](AGENTS.md) and [CONTRIBUTING.md](CONTRIBUTING.md). Work on a stage branch, record exact test commands and limitations, and submit a PR. Owner approval is required for merging, third-party integration, and later release work.

Scope and acceptance: [Issue #1](https://github.com/alekseypilishkov-gif/go_flora/issues/1). Original GO_FLORA code and documentation are licensed under [MIT](LICENSE), approved by the owner on 2026-10-14. Third-party components retain their own licenses and notices; see the [licensing inventory](docs/LICENSING_DECISION.md). No third-party assets or native libraries are distributed here.

Stage 00 results: [Russian report](stages/00_source_audit/report.md), [architecture proposal](docs/ARCHITECTURE_ADR_0001.md), [evidence and reproduction](stages/00_source_audit/evidence/README.md), and [PR #2](https://github.com/alekseypilishkov-gif/go_flora/pull/2). Audited engine baseline: Godot 4.7.2; broader compatibility is not yet verified.
