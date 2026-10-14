# Observed development failures

These are actual failures during implementation, not final acceptance results. Final logs/status are reported separately.

- Initial Godot editor import: **FAIL**, GDScript could not infer `action_name` from an indexed array. Corrected to explicit String type and rerun; no assertion removed or weakened.
- First restricted hardware query: **FAIL**, Windows CIM access denied. Repeated the same read-only hardware query with authorized escalation; **PASS**, actual results in `hardware.json`. This was an environment access failure, not a Godot runtime error.
- Windows Computer Use control attempt: **FAIL**, `Computer Use app approval timed out`. No mouse actions or screenshots were performed. Owner explicitly reserved GUI acceptance for themselves; **INTERACTIVE_GUI_QA: NOT_RUN**, not a runtime FAIL or PASS.
- Local whitespace regression: first invocation **FAIL**, `bash` absent from PATH; explicit installed Git Bash path then **FAIL** inside the sandbox because MSYS named objects were denied (`0xC0000022`). Retried the unchanged Stage 00 probe with the explicit Git Bash path and authorized escalation: **PASS**, committed whitespace rejected and clean committed diffs accepted for both PR and push. Evidence: `whitespace_regression.json`. These failures did not alter the CI gate or bypass its assertions.
- Staged whitespace check caught **FAIL** in captured core stdout: the test logger printed trailing spaces after empty details. Committed log presentation now trims trailing whitespace and ANSI colors; original subprocess outputs remain in `.scratch/runs/`. Test results/code were not weakened. The gate was rerun on the staged diff.
