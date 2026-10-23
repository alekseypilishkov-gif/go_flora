# GO_FLORA

Editor-first, terrain-independent **3D environment-authoring plugin for Godot 4.7.2**. Today: reusable Mesh/GLB/PackedScene foliage sources, PNG/WebP alpha plants, weighted palettes, stable placement records and MultiMesh rendering. **Next primary direction (owner decision, 23.10.2026): Surface Material Painting**, followed by Surface→Foliage rules and optional future Mesh Paint. Ready-made materials/assets are inputs; full tree/shrub/material/texture generation is outside the active plugin roadmap. [Product decision and scope](docs/PRODUCT_DIRECTION_20261023.md).

**Stage 02.3 / 0.2.3-dev: FINALIZED / OWNER GUI PASS.** [Issue #9](https://github.com/alekseypilishkov-gif/go_flora/issues/9) is closed after the owner accepted Continuous Erase, both palette removal choices, their Undo/Redo and retained-source save/reopen. See the [dated acceptance record](stages/02_imported_alpha_vegetation/integration/2026-10-15/owner_acceptance.md). [Implementation report and Explorer ZIP instructions](stages/02_imported_alpha_vegetation/updates/03_erase_palette_remove/report.md), [Stage 02.2 picker evidence](stages/02_imported_alpha_vegetation/updates/02_resource_picker_modal_fix/report.md) and [palette/dock update](stages/02_imported_alpha_vegetation/updates/01_palette_dock_ux/report.md) remain intact. Stage 01 was owner-accepted and merged in [PR #4](https://github.com/alekseypilishkov-gif/go_flora/pull/4) at `5c076153e1dea6363b885e82f4ef391808586348`.

**Stage 02 overall: FINALIZED / ACCEPTED_WITH_DEFERRED_QA** (owner 16.10.2026). [PR #6](https://github.com/alekseypilishkov-gif/go_flora/pull/6) was merged at `b9672974bb3403b5c2326f507ddd76e7cf4158fd`; the remaining specific Stage 02 regressions are DEFERRED under [Issue #12](https://github.com/alekseypilishkov-gif/go_flora/issues/12). [PR #14](https://github.com/alekseypilishkov-gif/go_flora/pull/14) Source Diagnostics and [PR #17](https://github.com/alekseypilishkov-gif/go_flora/pull/17) Configuration Warnings are MERGED (main 0.2.5-dev). [Issue #18](https://github.com/alekseypilishkov-gif/go_flora/issues/18) / [PR #19](https://github.com/alekseypilishkov-gif/go_flora/pull/19) Source Identity candidate 0.2.6-dev remains **OPEN / READY_FOR_MANUAL_QA / NOT MERGED**; **INTERACTIVE_GUI_QA NOT_RUN**. Historical logs retain their original evidence.

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

**Current plan:** [Stage 03 / Issue #10](https://github.com/alekseypilishkov-gif/go_flora/issues/10) is **Surface Material Painting Architecture & Feasibility — RESEARCH ONLY**. Later [Stage 04 Surface Painter MVP](docs/ROADMAP.md) (supported ground mesh, four weight-blended layers, non-destructive masks, save/reopen and Undo/Redo) requires explicit owner authorization. [Surface Material Painting DRAFT](docs/SURFACE_MATERIAL_PAINTING_DRAFT.md) remains unimplemented; [Studio](docs/GO_FLORA_STUDIO.md) and [Texture Lab](docs/RETRO_TEXTURE_PROCESSOR.md) are deferred historical concepts. Tree Generator/Tree3D, full PBR/texture generation, terrain sculpting and arbitrary Mesh Paint are not MVP commitments.

Follow [AGENTS.md](AGENTS.md), [CONTRIBUTING.md](CONTRIBUTING.md) and accepted [ADR A](docs/ARCHITECTURE_ADR_0001.md). Runtime code/data live in `addons/go_flora/`, tests in `tests/`, shared docs in `docs/`, new evidence in `stages/02_imported_alpha_vegetation/`. Earlier stage evidence is immutable. Source analysis, headless native tests, real GPU pixels and interactive owner review are separate gates.

```text
python tools/run_stage02_tests.py --godot .scratch/godot-portable/godot.exe --phase stage02
python tools/run_stage02_gpu.py --godot .scratch/godot-portable/godot.exe
python tests/test_stage02_package.py --godot .scratch/godot-portable/godot.exe
python tools/run_stage02_tests.py --godot .scratch/godot-portable/godot.exe --phase final
python tools/run_stage021_tests.py --godot .scratch/godot-portable/godot.exe --phase ux
python tools/run_stage022_tests.py --godot .scratch/godot-portable/godot.exe --phase modal
python tools/verify_repository.py
```

Historical 2026-10-15 integration approvals and earlier stage evidence remain preserved. The owner-approved 2026-10-23 product pivot authorizes **design/research only** for Stage 03, not Surface addon code, merge, ZIP installation, release or user resource migration. No automatic local checkout sync or changes to `C:\Dev\TEST_FLORA` are permitted. Original code, documentation and fixtures use the approved [MIT LICENSE](LICENSE); [third-party conditions](docs/LICENSING_DECISION.md) remain separate. No third-party art, code or native libraries are bundled. Historical reports: [Stage 00](stages/00_source_audit/report.md), [Stage 01](stages/01_painter_mvp/report.md), [accepted dock/distance baseline](stages/01_painter_mvp/updates/02_dock_width_distance/report.md).
