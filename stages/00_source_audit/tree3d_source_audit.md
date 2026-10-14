# Tree3D source and package audit

Audited 2026-10-14. Upstream: [JekSun97/gdTree3D](https://github.com/JekSun97/gdTree3D). This document separates **source inspection**, **author claims**, **runtime observations**, and **UNVERIFIED** provenance. Files/hashes: [source_refs.json](evidence/source_refs.json), [tree3d_source_checksums.json](evidence/tree3d_source_checksums.json), [archive_comparison.json](evidence/archive_comparison.json).

## Revisions and history

| Reference | Pin / evidence |
| --- | --- |
| Release v1.1.0, published 2026-09-14 | Tag resolves to [`dfe70274f5fe2a4845f1937fab524f7ee8f2c532`](https://github.com/JekSun97/gdTree3D/commit/dfe70274f5fe2a4845f1937fab524f7ee8f2c532), commit dated 2026-09-13 |
| Main inspected | [`e9ec657b0ee3667ac11dddad6133d52274c656f7`](https://github.com/JekSun97/gdTree3D/commit/e9ec657b0ee3667ac11dddad6133d52274c656f7), 2026-09-13; merge adding demo shaders |
| Official addon ZIP | [Tree3D-addon-godot4.5.zip](https://github.com/JekSun97/gdTree3D/releases/download/v1.1.0/Tree3D-addon-godot4.5.zip), SHA-256 `fb12f381ec19d1e9eb6339f8df85da474e9255ba0f86e5251df5d4599cc1b42d`; downloaded hash matches GitHub release digest |
| Local Tree3D_1.1.zip | SHA-256 `0d27c9673bd664a2b4a3d17d426f27142e8a1b78c49b72b9f66a806477c4cd72`; found locally and verified, not committed |
| godot-cpp candidate | 4.5 branch inspected at `27d9dd23c83871e0619fca5dc2cddfbfd69e926a`; future reproducible build candidate, **not** proven release dependency |

[Release history](https://github.com/JekSun97/gdTree3D/releases): v0.6 (2024) described Godot 4.2/4.3, v0.71 fixed twig disable and expanded build matrix; v0.8 (2026-06) moved to 4.5+ and claimed fixes for scene switching/duplication; v0.9 added collision; v1.0.0 introduced vertex-color wind; v1.1.0 advertised three wind tiers and trunk-base wind fix. These historical descriptions are upstream claims, not regression tests run here.

**Important mismatch:** `v1.1.0` tag source differs from main in `src/proctree.cpp` and does not contain the added Low/Medium/Nigh shader files that exist in the official release ZIP. `Tree3D.cpp`, header, SConstruct, descriptor and workflow blobs are identical between the inspected tag and main. Tag name alone cannot establish which source generated the release binaries. Preserve both pins; independent source/binary correspondence remains **UNVERIFIED**. The `Nigh` filename is upstream spelling; do not assume `High` is the actual resource path.

## Source findings

| Area | Verified source inspection / implication |
| --- | --- |
| Exposed API | [`Tree3D.h`](https://github.com/JekSun97/gdTree3D/blob/dfe70274f5fe2a4845f1937fab524f7ee8f2c532/src/Tree3D.h) and [`_bind_methods`](https://github.com/JekSun97/gdTree3D/blob/dfe70274f5fe2a4845f1937fab524f7ee8f2c532/src/Tree3D.cpp#L7): seed, trunk segments/branch depth/shape/growth/UV controls, twig enable/scale, separate materials, collision enable/type, wind parameters. Node3D subclass; no public mesh getter/bake function |
| Mesh production | Constructor creates two **internal** MeshInstance3D children. UpdateMeshTrunk/Twig builds triangle surfaces with SurfaceTool, indices, UVs, normals and RGBA vertex colors, optimizes indices, commits ordinary ArrayMesh resources |
| Leaves/twigs | Proctree has separate twig vertices/faces/UVs/normals/colors. This is card geometry, not an arbitrary custom model source. Twig disable queues its node for deletion; re-enable creates a new one |
| Materials | StandardMaterial3D/ORMMaterial3D/ShaderMaterial accepted. Material setters place overrides on child surface 0. Exporting Mesh alone loses overrides; capture effective per-surface material explicitly. README recommends Front cull for trunk |
| Collision | Fast mode makes a cylinder from trunk AABB/maximum radius. Accurate mode creates a concave shape from trunk/branch triangles. Twig-face contribution is commented out despite broad README wording. Collision regeneration queues old bodies for deletion |
| Wind | Proctree emits colors; shader uses COLOR.r as wind weight. Main/release tier shaders use global tree_wind_* uniforms and world vertex coordinates; original shader has local controls. Ensure global parameters and bounds exist; preserve color data and distinguish from per-instance tint |
| Lifecycle | Constructor creates/generates internal meshes; _enter_tree/_process/_exit_tree are empty, destructor has no explicit cleanup. Godot owns child nodes; cached Ref<Mesh> can outlive the generator. Repeated toggle, duplication, reload and scene-switch behavior needs tests; historical fixes do not establish current stability |
| Cost | Many setters regenerate all meshes; several update only trunk/twig. Avoid a live Tree3D per painted instance. Generate bounded variants, detach/cache once and batch ordinary meshes |

The source exposes a potential stale twig-wind update: `set_twig_wind_influence_start` updates the Proctree property and calls UpdateMeshTwig without `tree.generate()`. Also maximum recursion/segments setters are not proven safe for hostile values. These are **source-level risks**, not runtime bug confirmations; no upstream fixes are made in Stage 00.

## Package comparison and license boundaries

Both archives contain binaries and shaders, with no full C++ source. All **22 shared addon payload files are byte-identical**, including every packaged native library and the `.gdextension` descriptor. Local-only addon files: README.md and LICENSE.md. Official-only: original shader `.uid`. Archive ZIP hashes differ because packaging/content differs. This confirms local↔official binary payload equality, **not source↔binary build identity**.

Both descriptors say `version = "v1.0"` and `compatibility_minimum = "4.5"` despite v1.1.0 archive/release naming. Metadata remains stale; the version string must not drive provider identification. Full per-entry SHA-256 comparison is recorded without publishing ZIP contents.

Core MIT copyright 2024 Artyom Bozhko and contributors is distinct from the Paul Brunt/Jari Komppa BSD-style conditions in Proctree. Official addon ZIP inventory contains no full license notice; local package adds core MIT but no separately identified Proctree binary notice. Demo texture/asset ownership and linked binary dependency notices are **UNVERIFIED**. See [licensing decision](../../docs/LICENSING_DECISION.md). No upstream textures, shaders, source or binaries are committed.

## Build and compatibility

[SConstruct](https://github.com/JekSun97/gdTree3D/blob/dfe70274f5fe2a4845f1937fab524f7ee8f2c532/SConstruct) delegates to godot-cpp/SConstruct, builds `src/*.cpp`, writes libraries into demo/addons/Tree3D and installs addon descriptor/resources. The checked-in godot-cpp directory contains only a placeholder, not a pinned submodule. The [workflow](https://github.com/JekSun97/gdTree3D/blob/dfe70274f5fe2a4845f1937fab524f7ee8f2c532/.github/workflows/build-with-github.yml) fetches moving godot-cpp branch 4.5. It builds Linux/Windows x86_32/x86_64 and macOS x86_64/arm64/universal debug/release libraries; macOS hardware verification is explicitly TODO. Android and Windows ARM are TODO, Web is not established.

Local Godot: `4.7.2.stable.official.ed1daf0bf`, Windows 11 AMD64. Python 3.12.14 and Git 2.55.0.windows.3 work. Visual Studio Community 2022 is installed, but the queried C++ component is absent; no cl.exe was found in its tree or on PATH. SCons module check **FAIL**; CMake/Ninja/GCC/Clang/Docker/gh absent on PATH. **Native source build NOT_RUN** due to missing prerequisites. No global/system installs performed.

Runtime **PASS** for official unmodified v1.1.0 Windows x86_64 debug library: editor import; Tree3D registration/creation with seed 42; two internal meshes (2182/1792 vertices, one surface each); deep duplicate/save; generator freed; detached meshes still accessible and assigned to small MultiMeshes. [Logs](evidence/logs/tree3d.log). This does not prove wind appearance, collision correctness, release-library export, repeated lifecycle stability or other platforms.

**No C++ adaptation is required for the isolated extraction proof.** A production provider needs stable topology checks, material/local-transform capture, lifetime and variant caching tests. Prefer an explicit upstream snapshot API if maintainers support it; keep Tree3D optional until then.

## Native build reproduction — NOT_RUN here

Use an existing compiler environment. Do not install Visual Studio globally as part of this stage. In a new disposable source checkout, preserve all upstream notices. Commands below pin candidate dependencies but do not assert they match the release build:

```powershell
git clone https://github.com/JekSun97/gdTree3D.git .scratch/tree3d-build
git -C .scratch/tree3d-build checkout dfe70274f5fe2a4845f1937fab524f7ee8f2c532
git clone https://github.com/godotengine/godot-cpp.git .scratch/godot-cpp-build
git -C .scratch/godot-cpp-build checkout 27d9dd23c83871e0619fca5dc2cddfbfd69e926a
git -C .scratch/godot-cpp-build submodule update --init --recursive
# Upstream godot-cpp contains only a placeholder: copy dependency into it without deleting upstream files.
Copy-Item -Path .scratch/godot-cpp-build/* -Destination .scratch/tree3d-build/godot-cpp -Recurse -Force
python -m venv .scratch/build-venv
.scratch/build-venv/Scripts/python.exe -m pip install SCons==4.11.1
Push-Location .scratch/tree3d-build
../../.scratch/build-venv/Scripts/python.exe -m SCons platform=windows arch=x86_64 target=template_debug -j2
Pop-Location
```

The venv Python relative path from `.scratch/tree3d-build` resolves to `.scratch/build-venv`. On Linux/macOS use `bin/python`, appropriate platform/arch and existing GCC/Clang/Xcode toolchain. Package only the resulting addon plus complete notices into an ignored ZIP, run `evidence/run_probes.py --tree3d-archive <zip>` with the audited Godot, retain source/tool hashes and logs, and compare output. A successful build still does not prove byte-for-byte equality with upstream without its compiler/config provenance.
