# Parent session process audit — 2026-08-08

## Scope

- Source: `/Users/kurt/.codex/sessions/2026/08/07/rollout-2026-08-07T10-58-54-019fdcbb-f967-7153-bc2e-2a2eb9a26093.jsonl`
- Audit window: `2026-08-08T18:29:40Z` through the newest observed parent record, `2026-08-08T20:31:42Z` (the substantive handoff work ends around `20:30:51Z`; later records are waits/continuation bookkeeping).
- Method: top-level JSONL timestamps and structured `response_item` payloads; line numbers below are JSONL line numbers, not source-file lines.

## Executive finding

The session repeatedly used long-lived manual sessions and stale build/device artifacts while changing the harness underneath them. The parent did eventually add and verify an exact-scope cleanup helper and provenance fields, but those fixes were developed after several failed cleanup attempts and after a broad commit/push. The durable risk is now smaller, but the workflow still lacks one bounded, machine-checked acceptance command that proves a fresh run, teardown, artifact identity, and no residual processes together.

## Repeated patterns and impact

### 1. Repeated relaunches with changing, incompletely recorded profiles — high

There are at least twelve manual-session starts and matching/near-matching stops in the window: JSONL lines 33488, 33604, 33995, 34153, 34329, 34507, 34580, 35168, 35430, 35498, 36051, and 36143, with stop commands at 33463, 33600, 33971, 34079, 34313, 34414, 34542, 34689, 35411, 35477, and 36139. The runs vary input mode, GPU composition, framebuffer dimensions, timeouts, and Gamescope selection; for example line 33995 uses `NOVA_AHB_WIDTH=960 NOVA_AHB_HEIGHT=540` with fullscreen `1280x960`, while line 36143 selects the diagnostic Gamescope and 86400-second timeouts.

Impact: screenshots and Steam UI state from different experiments are easy to compare as if they were one result. Long timeouts also make the process lifecycle dependent on later manual intervention.

Repair: make each profile a named script/config, emit a run UUID and all dimensions/flags before launch, and reject comparison or report collection unless the current run UUID appears in every artifact. Keep bounded acceptance and manual sessions as separate commands with finite deadlines.

### 2. Stale or ambiguous readiness evidence was reused — high

At line 33425 (`18:30:05Z`), the parent tails the device's existing `webhelper_js.txt`; the returned records are timestamped `18:12:42` through `18:23:45`, before the current audit window and before the subsequent manual launch at line 33488 (`18:32:15Z`). The session then continues to inspect screenshots and CDP state without first establishing a fresh per-run log baseline. Later commands repeatedly read persistent Steam logs and `logcat -d` snapshots (for example lines 33827–33865) and use fixed PID `2783` (line 33797), while multiple runs are active across the window.

Impact: a familiar Steam/OOBE line can be mistaken for readiness of the current Activity/Surface. Fixed PIDs and whole-file tails also make it difficult to attribute evidence to the current process.

Repair: have launch create a run directory and capture device log cursors/start timestamps, PID/start-time tuples, and a fresh baseline marker. Readiness should require new records after that marker plus current-process identity; fail if only pre-run lines match. Replace fixed PID queries with the PID recorded by the launcher and verify its `/proc/<pid>/starttime`.

### 3. Cleanup was initially best-effort and demonstrably failed — high

The first cleanup integration intentionally swallowed errors (`|| true`) at lines 36305 and 36316. The first device execution at line 36322 reports repeated Android `awk` syntax errors and `nova_runtime_cleanup=fail ... remaining=5592,10627`; subsequent executions at lines 36334 and 36356 still report `nova_runtime_cleanup=fail`, including a residual rootfs process. Only line 36378 reports `pass`, after more helper edits; the synthetic target check at line 36383 also reports pass.

Impact: an experiment could proceed, or appear stopped, after cleanup had failed. The failure mode was especially dangerous because the session's own lifecycle document later described the incident as resolved.

Repair: keep cleanup as a required preflight and exit trap, propagate both helper and push failures, and make the helper's pass marker plus an independent exact-scope process query mandatory acceptance criteria. Add a device-side unit-style fixture for the Android `awk` implementation and a test for a reparented descendant.

### 4. Redundant investigation and patch retries increased risk — medium

The same stale-buffer documentation patch was attempted repeatedly at lines 36469, 36477, and 36481 after verification commands at 36473 and 36495. Several `apply_patch` calls failed verification (for example line 36387 and line 36681). The session also spent many commands probing CDP/WebSocket tooling availability (33500–33536) and repeatedly taking screenshots of the same UI state (33615–33649) while the run profile was changing.

Impact: time was spent recovering from patch-context drift and tool exploration rather than preserving a clean experiment boundary. Failed patch attempts are not themselves defects, but in this session they coincided with ongoing device state and made the evidence trail harder to interpret.

Repair: use one narrow patch per hypothesis, immediately run the targeted test, then record the result before the next experiment. Add a small repository helper for the required CDP query instead of probing three client libraries/commands during a live run.

### 5. Verification was broad but not consistently gated — medium

The bounded AHardwareBuffer run at line 36402 produced useful markers: 10 frames, 9 releases, `ahb_double_buffer=pass`, three imported `1280x960` buffers, and target reached. However, the same report says `gamescope_libei_build=unknown` and `gamescope_input_emulation=unset` (line 36411); the log then shows “Gamescope built without libei” (line 36415). The provenance fix was applied only afterward at line 36419. Separately, shell lint at line 36514 was followed by `git commit ... && git push origin main` at line 36532, before the later cleanup error-propagation edits at lines 36599–36605.

Impact: a successful protocol test did not establish that the artifact matched the intended input experiment, and a durable repository state was published before all discovered lifecycle gaps were closed.

Repair: make provenance fields required (not `unknown`/`unset`) for bounded runs, fail on a disabled libei marker when input emulation is requested, and run the complete acceptance suite after the final edit and before any commit/push. Never publish a partially repaired harness from the middle of an experiment.

## Items repaired during the audited session

- An exact-scope process cleanup helper was added and iterated until both live cleanup and a synthetic target returned `nova_runtime_cleanup=pass` (lines 36271–36383).
- The bounded AHardwareBuffer harness gained cleanup integration, app-owned file cleanup, artifact SHA-256/source/build metadata, and libei marker reporting (lines 36305, 36419, and the later diff at 36699).
- Stale two-buffer documentation was corrected to describe the current three-buffer contract (lines 36445–36495).
- Manual/controller cleanup paths were changed to surface push/helper failures rather than suppress them (lines 36599–36610), and the lifecycle document was updated (lines 36680–36694).
- Final shell syntax/diff checks were run at lines 36694 and 36698. The session log also records a successful broad commit/push at line 36533 and a later hardening commit attempt beginning at line 36703; this report does not infer the later commit result beyond the JSONL evidence available.

## Still open

1. There is no single bounded acceptance command in the audited evidence that proves fresh-baseline readiness, run identity, exact cleanup, artifact provenance, and residual-process absence as one atomic contract.
2. The manual-session workflow still permits many ad hoc environment combinations and very long-lived timeouts; the session does not show a profile manifest or automatic artifact/run comparison guard.
3. The first cleanup implementation had no automated regression test for Android `awk` portability or reparented descendants; the evidence shows manual repair, not a repeatable fixture.
4. The session's final hardening was staged/under commit processing near the end of the window; a later clean-tree and pushed-commit verification should be recorded separately from the device experiment.

## Priority order

1. P0: add one finite `nova-acceptance` wrapper that creates a run ID, cleans before launch, records process/artifact metadata, uses fresh log cursors, enforces readiness from current records, cleans on exit, and fails on any residual exact-scope process.
2. P1: add a device-shell test fixture for cleanup matching, including Android `awk` syntax and reparented descendants; run it in CI or the documented Docker/device check.
3. P1: formalize `bounded-ahb-1280x960` and `manual-steam-input` profiles with required metadata and reject `unknown`/`unset` provenance.
4. P2: add the small CDP inspection helper and replace repeated ad hoc WebSocket capability probes.
