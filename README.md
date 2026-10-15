# GO_FLORA

Editor-first, terrain-independent 3D vegetation for **Godot 4.7.2**: reusable Mesh/GLB/PackedScene sources, PNG/WebP alpha plants, weighted palettes, stable placement records and spatial MultiMesh rendering.

**Stage 02.1 / 0.2.1-dev: READY_FOR_MANUAL_QA. INTERACTIVE_GUI_QA: NOT_RUN.** [Issue #7](https://github.com/alekseypilishkov-gif/go_flora/issues/7) authorizes the palette/dock update within [Stage 02 / Issue #5](https://github.com/alekseypilishkov-gif/go_flora/issues/5). [New Russian report and ZIP instructions](stages/02_imported_alpha_vegetation/updates/01_palette_dock_ux/report.md). Stage 01 was owner-accepted and merged in [PR #4](https://github.com/alekseypilishkov-gif/go_flora/pull/4) at `5c076153e1dea6363b885e82f4ef391808586348`. Its historical reports retain their original statuses; unexecuted older manual/GPU/export cases are not retroactively marked PASS.

## Install and use

Copy `addons/go_flora/` into a Godot project and enable **GO_FLORA**. In the dock choose a layer/set, **Add Mesh / GLB / Scene…** or **Create Alpha Plant…**, save the reusable source `.tres`, and Paint / Erase / Single. Alpha-scissor, ground pivot, crossed/radial cards and pixel atlas regions are supported. Reviewed authored scenes have a constrained runtime instance fallback with inert editor preview. Read the [addon guide](addons/go_flora/README.md) and [source contracts](docs/STAGE_02_SOURCE_CONTRACTS.md).

GO_FLORA defaults to the right Inspector group. Its named palette supports **Mix by weights / Selected source only**, enabled checkboxes, weights and scene Undo/Redo; disabling a source keeps all previous placements. Open Set in Inspector activates the correct resource/tab. Russian tooltips and click-open Help explain the controls. Saved custom dock layouts are respected; Ctrl+Alt+G shows GO_FLORA. See the [compatible data/UX addendum](docs/STAGE_02_1_PALETTE_UX.md).

From the repository root, using the pinned local engine:

```text
python tools/prepare_stage02.py --godot .scratch/godot-portable/godot.exe
```

Open `stages/02_imported_alpha_vegetation/demo/project.godot` in Godot. The original [demo](stages/02_imported_alpha_vegetation/demo/README.md) contains a real two-mesh/three-surface GLB, PNG/WebP grass, flowers/atlas, an authored script/collider scene, 137 saved placements and ordinary/tilted collision surfaces. [Russian report](stages/02_imported_alpha_vegetation/report.md), [evidence](stages/02_imported_alpha_vegetation/evidence/README.md), [owner manual QA](stages/02_imported_alpha_vegetation/manual_qa.md).

Build the **plugin-only ZIP** with `python tools/package_stage02.py`. Save/close your editor before updating. The optional [update tool](tools/install_stage02.py) validates the archive, keeps addon backups and leaves scenes/project settings/layout untouched. Development/tests use isolated projects; **TEST_FLORA is not installed or modified automatically**.

## Development and scope

Follow [AGENTS.md](AGENTS.md), [CONTRIBUTING.md](CONTRIBUTING.md) and accepted [ADR A](docs/ARCHITECTURE_ADR_0001.md). Runtime code/data live in `addons/go_flora/`, tests in `tests/`, shared docs in `docs/`, new evidence in `stages/02_imported_alpha_vegetation/`. Earlier stage evidence is immutable. Source analysis, headless native tests, real GPU pixels and interactive owner review are separate gates.

```text
python tools/run_stage02_tests.py --godot .scratch/godot-portable/godot.exe --phase stage02
python tools/run_stage02_gpu.py --godot .scratch/godot-portable/godot.exe
python tests/test_stage02_package.py --godot .scratch/godot-portable/godot.exe
python tools/run_stage02_tests.py --godot .scratch/godot-portable/godot.exe --phase final
python tools/run_stage021_tests.py --godot .scratch/godot-portable/godot.exe --phase ux
python tools/verify_repository.py
```

Stage 02 stops at a scoped PR for owner review. Stage 03, Tree3D, LOD/wind/large forests, merge and public release require separate decisions. Original code, documentation and fixtures use the approved [MIT LICENSE](LICENSE); [third-party conditions](docs/LICENSING_DECISION.md) remain separate. No third-party art, code or native libraries are bundled. Historical reports: [Stage 00](stages/00_source_audit/report.md), [Stage 01](stages/01_painter_mvp/report.md), [accepted dock/distance baseline](stages/01_painter_mvp/updates/02_dock_width_distance/report.md).
