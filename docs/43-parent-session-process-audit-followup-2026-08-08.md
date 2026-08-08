# Parent session process audit — follow-up 2 — 2026-08-08

## Scope

- Source: `/Users/kurt/.codex/sessions/2026/08/07/rollout-2026-08-07T10-58-54-019fdcbb-f967-7153-bc2e-2a2eb9a26093.jsonl`
- Audit window: `2026-08-08T21:02:18Z` through the newest observed record, `2026-08-08T23:02:45Z`.
- Compared with `docs/35-parent-session-process-audit-2026-08-08.md` and `docs/40-parent-session-process-audit-followup-2026-08-08.md`.
- Evidence references are JSONL line numbers, not repository source lines.
- This report is documentation-only and was not committed or pushed by this audit.

## Executive finding

The `legacy-20260808T225322Z-ahbtrace` milestone materially improved the workflow: it used a unique run directory, dynamic CDP route polling, dynamic X11 tree discovery, repeated focus checks, immutable run-time Gamescope identity, and a passing exact cleanup plus trace-reset contract. The frame-247 stall is consequently much stronger evidence than the earlier screenshot-only observations.

The remaining process risks are narrower but important. A publish happened before the full reset/provenance gate was exercised; the first post-publish reset test exposed a shell/`su -c` quoting defect. The linked Gamescope source worktree was still dirty while its commit was treated as sufficient identity. The documented run still lacks an APK hash, and the session proceeded to protocol source inspection while a fresh Luna handoff was still being retried.

## Repeated findings since audits 35 and 40

### 1. Publish-before-complete-gate recurred — high

The tracer checkpoint was staged, committed, and pushed at lines `40381–40382` before the subsequent root-side trace reset probe completed. The probe at `40436–40455` showed that `su -c` quoting caused the trace-file write to run as the shell user despite `id` reporting root. The fix was then patched, committed, and pushed as a second checkpoint at `40470–40501`.

This repeats audit 35's late verification/publication problem and audit 40's warning to make the artifact tuple atomic. The follow-up fix was correct, but the first pushed checkpoint did not yet prove the cleanup/reset path it advertised.

Repair: add a pre-publish gate that exercises the actual deployed shell command through `adb shell`, verifies the trace file contents and permissions, runs stop/reset twice, checks the linked worktree diff/hash, and only then stages the complete checkpoint.

### 2. Source commit identity still did not prove source-tree identity — high

The local verification at line `40356` showed `gamescope-headless-source-seven` containing modified source files and untracked subprojects. Later checks verified only its Git directory and `HEAD` (`40478–40479`), while the launch message described the source as confirmed/clean (`40548`) and the run report recorded only commit `fb9f84ee…` (docs/42 lines 9–18).

This repeats audit 40's immutable-artifact concern. A commit hash alone is insufficient when the build worktree is dirty or patch-applied. The binary may be valid, but the exact source delta that produced it is not reconstructible from the run metadata.

Repair: record `git status --porcelain`, a deterministic source diff/patch SHA, dependency/subproject state, and binary SHA in the same immutable artifact manifest. Refuse deployment when the worktree is dirty unless an explicit patch digest is present.

### 3. APK provenance remains an open gap despite improved Gamescope provenance — high

The tracer build verification printed an APK hash at line `40333`, and the run used a unique artifact directory. However, docs/42 explicitly says the run metadata omitted the APK hash and that the installed APK cannot be proven (lines 20–25); its next gate repeats this requirement (line 90). This is a direct remaining item from the latest milestone, not a resolved provenance field.

Repair: hash the exact APK immediately before `adb install`, store it in the run metadata, record the installed package version/signing or package-path identity, and fail the run report if the metadata field is absent or differs.

## Newly introduced or newly visible risks

### 4. Sidecar handoff was retried with a schema error and an already-finished target — medium

After the run, the parent attempted to send the new audit request to the prior Luna target. The first call failed with `Provide either message or items, but not both` at lines `40844–40845`; it then retried at `40848–40849`. The target was the earlier completed sidecar rather than a newly spawned audit identity.

Repair: use one known-valid sidecar invocation shape, spawn a fresh audit agent for each periodic audit, and record the returned agent ID before waiting. Treat handoff failure as a bounded tool error, not a reason to continue protocol work without the requested audit.

### 5. Post-reproduction protocol inspection began in the same parent turn without a new transport gate — medium

The parent correctly stopped and cleaned the run at `40773–40778`, documented and pushed docs/42 at `40812–40830`, then immediately began broad ACK/release source inspection at `40852–40853`. This is reasonable preparation, but the next experiment contract in docs/42 requires one transport-only change and a fresh run. The session does not yet show a small, predeclared transport hypothesis or a bounded test plan before broad source exploration.

Repair: before source edits, write the one-variable transport hypothesis, exact expected trace delta, bounded acceptance criteria, and rollback/stop condition. Keep source inspection read-only until that experiment card exists; do not widen from framing to ownership/ring changes without a failed transport-only result.

## What demonstrably improved

- Unique run artifacts and explicit run identity were used at launch (`40549`, docs/42 lines 5–18).
- CDP route polling was dynamic and bounded rather than a fixed-delay readiness check (`40645`, `40692`).
- Android focus and X11 target were rediscovered before each relevant transition (`40568`, `40628–40633`, `40652–40657`).
- The second transition was correlated to app and Gamescope frame traces, not inferred from screenshots alone (`40706–40711`, docs/42 lines 53–75).
- Exact runtime cleanup, app-file cleanup, and trace reset all passed with no residual processes (`40773–40778`, docs/42 lines 77–86).
- The milestone correctly avoided changing protocol/ownership code before the evidence checkpoint (docs/42 line 96).

## Prioritized repair list

1. **P0:** Make pre-publish verification atomic: deployed `su` quoting/reset test, double cleanup, source dirty-state/patch digest, Gamescope hash, APK hash, and feature markers must all pass before staging.
2. **P0:** Add APK SHA-256 to run metadata before install; reject reports that omit it (docs/42:20–25, 90).
3. **P1:** Treat a dirty linked source worktree as a distinct artifact and record its exact diff/dependency digest; do not call commit-only identity “immutable” (`40356`, `40478–40548`).
4. **P1:** For the next protocol iteration, write one transport-only experiment card before editing or broadening source investigation (docs/42:88–96; `40852–40853`).
5. **P2:** Standardize periodic Luna spawning/handoff to avoid schema retries and stale target reuse (`40844–40849`).

