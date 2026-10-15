# GO_FLORA

Editor-first, terrain-independent 3D vegetation for **Godot 4.7.2**: reusable Mesh/GLB/PackedScene sources, PNG/WebP alpha plants, weighted palettes, stable placement records and spatial MultiMesh rendering.

**Stage 02.3 / 0.2.3-dev: FINALIZED / OWNER GUI PASS.** [Issue #9](https://github.com/alekseypilishkov-gif/go_flora/issues/9) is closed after the owner accepted Continuous Erase, both palette removal choices, their Undo/Redo and retained-source save/reopen. See the [dated acceptance record](stages/02_imported_alpha_vegetation/integration/2026-10-15/owner_acceptance.md). [Implementation report and Explorer ZIP instructions](stages/02_imported_alpha_vegetation/updates/03_erase_palette_remove/report.md), [Stage 02.2 picker evidence](stages/02_imported_alpha_vegetation/updates/02_resource_picker_modal_fix/report.md) and [palette/dock update](stages/02_imported_alpha_vegetation/updates/01_palette_dock_ux/report.md) remain intact. Stage 01 was owner-accepted and merged in [PR #4](https://github.com/alekseypilishkov-gif/go_flora/pull/4) at `5c076153e1dea6363b885e82f4ef391808586348`.

**Stage 02 overall: MANUAL ACCEPTANCE INCOMPLETE.** The owner explicitly authorized integration of PR #6 despite the remaining GLB/PackedScene, UV-atlas and broader integration GUI checks. These cases remain READY_FOR_MANUAL_QA; INTERACTIVE_GUI_QA: NOT_RUN applies only to unexecuted cases, not to the accepted Stage 02.3 scenarios. Historical automatic logs keep their original status and are not rewritten as physical GUI evidence.

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
python tools/run_stage022_tests.py --godot .scratch/godot-portable/godot.exe --phase modal
python tools/verify_repository.py
```

The owner's 2026-10-15 integration task authorizes merge of PR #6 and a separate architecture documentation PR; it does not complete overall Stage 02 acceptance or authorize new systems. Stage 03, Tree3D implementation, LOD/wind/large forests and public release still require separate decisions. Original code, documentation and fixtures use the approved [MIT LICENSE](LICENSE); [third-party conditions](docs/LICENSING_DECISION.md) remain separate. No third-party art, code or native libraries are bundled. Historical reports: [Stage 00](stages/00_source_audit/report.md), [Stage 01](stages/01_painter_mvp/report.md), [accepted dock/distance baseline](stages/01_painter_mvp/updates/02_dock_width_distance/report.md).
