# Command history and failure accounting

Audit date 2026-10-14. Reusable paths are relative to repository root. Workstation executable paths are recorded in environment.json. A status here describes the actual command/check, not source plausibility.

| Command/check | Result | Resolution/evidence |
| --- | --- | --- |
| `git status` before clone | FAIL: directory not a Git repository | Empty local workspace confirmed |
| `git clone https://github.com/alekseypilishkov-gif/go_flora.git .` in sandbox | FAIL: DNS resolution | Same clone with network authorization PASS; empty repository warning |
| GitHub issue read + repo/branches query | PASS: Issue #1, no comments, public repo/default main, branches `[]` | Scope applied before initialization |
| Initial main publication approval | Automatic approval review rejected it as outside branch scope | Re-read Issue A explicit minimal base-commit authorization and empty branches; evidence-backed retry approved; no bypass |
| `git add README.md .gitignore CONTRIBUTING.md AGENTS.md` / commit in sandbox | FAIL: .git/index.lock permission | Authorized Git mutation retry PASS |
| Base commit and `git push -u origin main` | PASS | Only minimal bootstrap; `6c79285` initial commit; Stage 00 results in separate branch |
| `git switch -c codex/stage-00-foundation` | PASS | Required branch |
| `git clone --filter=blob:none --no-checkout https://github.com/JekSun97/gdTree3D.git .scratch/tree3d-source` then checkout `e9ec657...` | PASS | Unmodified source, clean checkout; not committed |
| Source lookup `src/tree3d.h` | FAIL: 404 / wrong filename case | Corrected to actual `src/Tree3D.h`, PASS |
| GitHub tags fetch endpoint via connector | FAIL: endpoint validation | `git tag --list` and `git rev-list -n 1 v1.1.0` PASS |
| Source reads while checkout pending | FAIL: files not yet present | Reads retried after checkout completion, PASS |
| Second concurrent ZIP download | FAIL: file in use by original download | Original download completed; SHA-256 PASS; no ZIP alteration |
| Tag/main `git diff --stat` in sandbox with partial clone | FAIL: promisor blob network lookup | Tree-only `diff --name-status --no-renames` PASS; pinned Proctree source read through connector PASS |
| SCons availability `python -m scons --version` | FAIL: No module named scons | Native compilation NOT_RUN, no installation |
| Initial probe harness | FAIL: Windows default output encoding could not decode log | Explicit UTF-8 replacement decoding added; English editor language selected |
| First Godot commands | FAIL: editor/user log directory permissions; runtime probe also leaked UndoRedo object | Original logs retained under `logs/sandbox-attempt`; local portable copy, child-only APPDATA profile, and explicit history free used |
| Portable engine alone | FAIL: user data still outside allowed path | Child-only profile redirection added; final headless commands PASS |
| Final headless editor/runtime/reopen/alpha/Tree3D commands | PASS | Exact runner commands and raw final logs; manual subchecks remain NOT_RUN |
| GPU Compatibility alpha command | FAIL, exit 1 | Scissor PASS; hash FAIL retained with pixel log and screenshot |
| GPU Vulkan Mobile/Forward+ alpha commands | PASS, exit 0 | Both scissor/hash samples pass on desktop GPU |
| Codeberg canonical ProtonScatter fetch | FAIL: fetch/cache error | GitHub mirror inspected; head parity UNVERIFIED |
| First staged `git diff --cached --check` | FAIL: one trailing space in original error log | Space removed; preserved error text; repeated gate PASS |
| Canonical fetched source byte verification | PASS | All 8 reconstructed Git blob SHA-1 values match upstream IDs; SHA-256 manifest uses those exact bytes |
| `python tools/verify_repository.py` and staged whitespace gate | PASS | No large/dependency artifacts or broken local links; required documents present |
| Audit commit/push/PR | PASS | `b5555ad04f0772a36406776c3fa8e5aaaba37c95`; feature branch; PR #2 open; no merge/release |
| GitHub Actions source checks | PASS | Run 38543078304 on b5555ad; static source checks only |

Native build, interactive viewport delivery, per-set propagation, export/lifecycle and non-Windows platforms were not executed: **NOT_RUN**. Upstream source/binary identity and asset provenance are **UNVERIFIED**, not test statuses. Preliminary tooling/permission errors are preserved here even where subsequent corrected runs pass.
