# Stage 02.3 — Erase and retained source contract

Scope: owner-authorized Issue #9, existing Stage 02 branch and Draft PR #6; version 0.2.3-dev. Schema 1, record IDs, serialized source kinds and Paint/Single sampling budgets remain unchanged.

## Continuous Erase

Each gesture owns an ephemeral world-space grid of unlocked records in its active set. Index construction is incremental, including traversal of unrelated records. Grid cells have brush-radius edge length; exact point-to-segment world distance decides deletion after retrieval. Nonuniform layer scale and rotation are applied before indexing. Initial clicks query a sphere; accepted consecutive hits query a swept capsule, independently of Paint spacing and mouse event count. Missing/ineligible hits break the path. The final release hit participates in Erase; stationary inputs enqueue no redundant segment.

Long sparse segments visit occupied cells with a conservative expanded-cell bounding sphere, then exact record tests. Short segments use bounded local grid queries. Erased candidates leave transient buckets. An empty live index discards remaining queries immediately. No persistent spatial fields or record identities are introduced.

Input enqueues; the editor processes one query slice per process tick. Each slice permits at most 512 index/cell/candidate operations and checks a 4 ms deadline between operations. One additional bounded slice on release preserves small synchronous Editor API transactions. This is a query-work bound, not a hard whole-frame deadline: delta assembly, application and final render rebuild remain synchronous. CPU timings must not be described as FPS. The standalone core `finish_delta()` synchronously drains work for non-editor callers; the UI waits until no query remains before using it.

Preview uses record-to-MultiMesh slot references created during ordinary render construction. Each query slice reports only newly erased IDs; the preview zeroes those transforms without rebuilding batches. Empty preview updates keep prior hiding. Cancel discards transient state and reconstructs visible cache from unchanged records. Mouse-up inside the viewport enters draining state until every accepted segment completes, then creates one scene Undo action. Escape, outside-viewport release, focus loss, navigation, scene/set/layer change, transform change or a signalled data mutation cancel all pending work. New input cannot replace a draining stroke. Undo restores original record references, IDs, order and serial in linear time.

## Palette membership and rendering

`GFVegetationSet.render_only_sources: Array[GFVegetationSource]` is an additive `@export_storage` field with an empty default. Old scenes require no migration. It is not an Inspector palette property and never enters `source_by_id()`, placement weighting, Mix or Selected eligibility. `rendering_sources()` resolves active entries first, then retained references, deduplicated by stable source ID. Renderer, layer resource signatures, bindings, material/card observation, invalidation and reimport all include this catalog. Reviewed/unknown/refused scene fallback rules are unchanged.

Remove targets the actual entry instance and revalidates membership. Ordinary removal changes membership and retains its source reference, keeping all existing records visible after serialization/reopen. Even unused references remain retained because a saved set can be shared with unopened scenes; this stage has no automatic archive cleanup. Zero-placement removal is immediate and reversible. Removal with placements explains preservation and shows their count in the owning layer. A separate confirmation is required for removal of all matching `(set_id, source_id)` records, including locked records; it affects only that layer, preserves serial and other records, and is one scene action. Original files are never deleted.

Confirmation captures scene, data, entry, source identity and exact matching record references; a changed context/count refuses the operation. Set/scene/layer switches or opening another GO_FLORA source tool close the popup. Nonexclusive editor-owned dialogs avoid competing with native resource chooser exclusivity. Dock and named Inspector invoke the same controller once.

Selected keeps its transient stable ID when its row disappears and blocks painting with an explicit diagnostic. Undo makes that selection usable again. Readding the saved source restores paint eligibility and removes its retained duplicate in the same action; Undo restores archive membership. Attempted duplicate active IDs in append/reference assignment create no data or Undo change.

## Test contract clarification

The unchanged Stage 02.1 native suite was executed and preserved under the Stage 02.3 evidence: two scenarios expected an active duplicate ID to be assigned/appended. The owner explicitly approved replacing exactly these two scenarios with stronger duplicate-refusal, unchanged-record and unchanged-history assertions. The assertion count remains 99. Other Stage 01/02/02.1 tests and the Stage 02.2 suite remain unchanged. New tests separately cover successful archive readdition and its real native Undo/Redo.
