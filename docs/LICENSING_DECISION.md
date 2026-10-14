# Licensing decision — owner sign-off pending

**Recommendation:** adopt MIT for original GO_FLORA code and documentation, with a separate third-party notices file for any approved dependency distribution. **Decision: PENDING.** No root LICENSE is added, and this recommendation does not grant rights to upstream assets. Owner approval is required before adopting the license, distributing derivatives or publishing a release.

This is a provenance inventory based on inspected sources, not a substitute for review of the eventual distributable. Stage 00 distributes only original probes/docs and small logs/checksums. Downloaded upstream code, binaries, icons and demos stay in ignored `.scratch/`.

| Boundary | Evidence | Obligations / uncertainty | Stage 00 treatment |
| --- | --- | --- | --- |
| Tree3D core | [MIT notice](https://github.com/JekSun97/gdTree3D/blob/dfe70274f5fe2a4845f1937fab524f7ee8f2c532/LICENSE.md), copyright 2024 Artyom Bozhko and contributors | Retain copyright and full permission/disclaimer in copies/substantial portions | Referenced; no derivative code committed |
| Proctree algorithm/C++ port | [src/proctree.cpp header](https://github.com/JekSun97/gdTree3D/blob/dfe70274f5fe2a4845f1937fab524f7ee8f2c532/src/proctree.cpp) | BSD-style three conditions: retain notices in source; reproduce notices/disclaimer for binaries; no contributor endorsement. Paul Brunt 2012; Jari Komppa 2015 | Separate obligation from core MIT; require notices before binary distribution |
| godot-cpp | [official MIT LICENSE](https://github.com/godotengine/godot-cpp/blob/27d9dd23c83871e0619fca5dc2cddfbfd69e926a/LICENSE.md) | Preserve notices in a native distributable. Pin actual build revision and audit linked components | Not bundled or built here |
| Tree3D shaders | Source under Tree3D repo's core notice; individual shader files lack their own attribution header | Treat as dependency material, preserve root notice if included; later shader adaptations require review | No shader copied to committed probes |
| Tree3D sample textures / demo scenes / icon | Repo and ZIP inventory; no asset-by-asset provenance manifest found | **UNVERIFIED** individual ownership/license. Root MIT alone does not prove external texture provenance | Not redistributed; synthetic green alpha sample only |
| Packaged native libraries | Official v1.1.0 asset digest and per-entry hashes; local binary payload matches | Source ↔ exact compiler/godot-cpp build identity **UNVERIFIED**. Official addon ZIP has no full license/Proctree notice; local archive adds MIT README/LICENSE only | Used locally for import probe, not committed or licensed for redistribution by this audit |
| Competitor plugin code | Primary repos linked in matrix; MIT code notices inspected or referenced | Each code license is separate from demo textures/brands. ProtonScatter explicitly restricts standalone redistribution of bundled Textures.com textures | Research only; no implementation/assets copied |
| Unreal Engine reference | [official Foliage Mode docs](https://dev.epicgames.com/documentation/unreal-engine/foliage-mode-in-unreal-engine) | Behavior reference only; no permission inferred to reuse Epic assets/code | No copies |

Owner decisions: approve or reject MIT for original work; approve the optional external-provider strategy; authorize any later Tree3D derivative integration only after notice completeness, build provenance and asset exclusions are resolved. Keep unknown-license assets out of future release packages by an explicit allowlist.
