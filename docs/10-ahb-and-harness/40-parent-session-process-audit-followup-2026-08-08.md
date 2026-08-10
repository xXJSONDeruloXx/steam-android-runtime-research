# Parent session process-audit follow-up — 2026-08-08

## Scope

- Source: `/Users/kurt/.codex/sessions/2026/08/07/rollout-2026-08-07T10-58-54-019fdcbb-f967-7153-bc2e-2a2eb9a26093.jsonl`
- Audit window: `2026-08-08T20:44:51Z` through the newest record observed at `2026-08-08T22:44:51Z`.
- Comparison: `docs/10-ahb-and-harness/35-parent-session-process-audit-2026-08-08.md`.
- Evidence references below are JSONL line numbers, not repository source lines.
- This follow-up is deliberately separate from the prior audit and was not committed or pushed.

## Executive finding

The previous audit's main risks recurred during the next two hours. The parent did establish useful source-vs-Android presentation evidence, but the experiment boundary was still porous: live manual sessions remained active while source patches, detached worktrees, and builds changed; captures were keyed to wall-clock sleeps and hard-coded X11 IDs; and several logs/screenshots were not proven to belong to the current run before interpretation. The new highest-risk issue is concurrent mutation of the test artifact or harness during an active device session, which can make an apparent frame-protocol result non-reproducible.

## Repeated findings

### 1. Ad hoc manual sessions and long waits remain the default — high

The parent repeatedly launched or continued manual sessions with long timeouts and then used many independent waits and probes: launch at lines `37212`, `37312`, and `39231`; repeated `write_stdin` waits at `37920–37972` and `40242–40292`; and stops at `37301`, `38412`, and `39131`. The active session was still being investigated while tracing work continued near the end of the window.

This repeats prior audit finding 1. It makes results from different profiles easy to conflate and leaves device state alive across source/harness changes.

Repair: make the manual session a named, finite profile with a recorded run directory; prohibit source/build changes while it is active; require a stop-and-clean result before changing hypotheses. A bounded capture command should own all timing and teardown rather than accumulating sleeps and terminal polls.

### 2. Fixed-delay evidence collection is still being used as readiness or state proof — high

The parent used `sleep 2`, `sleep 3`, `sleep 4`, `sleep 5`, `sleep 6`, `sleep 8`, `sleep 9`, `sleep 12`, and `sleep 15` around CDP queries and screenshots at lines `37101–37118`, `37236–37274`, `38226–38304`, and `39300–39410`. The source/Android comparison was explicitly sampled at 3 seconds, 12 seconds, and 27 seconds after input (`39300–39319`, `39378–39410`).

This repeats prior audit finding 2's stale/ambiguous readiness problem in a more subtle form: the observations may be fresh, but the fixed delay does not establish which frame, presentation ACK, or UI transition they represent.

Repair: emit a monotonic run/frame marker at input dispatch, source-window capture, Android present, and release/ACK completion. Capture on those markers, with a bounded timeout, and report timeout rather than silently treating a delayed sample as the state transition.

### 3. Logs and artifacts are still not consistently bound to the current run — high

During a live manual session, the parent inspected persistent Steam logs and prior-looking build artifacts at lines `37224`, `37324`, `37341–37377`, and `39364–39372`, including `webhelper_js.txt`, the Steam UI bundle, `native-steam-controller-ui-input-smoke.log`, and `device-gamescope-headless-ahb-metadata.txt`. The capture workflow then wrote generic names such as `current-oobe-*` and `nova-x11-*` at lines `38180–38274` and `39251–39410`, while the X11 capture used hard-coded IDs `0x240003b` and `0x1000005` at line `39258`.

This repeats prior audit findings 1, 2, and 5. The session did inspect useful hashes and metadata, but there is no demonstrated invariant that every screenshot, Steam log excerpt, X11 window ID, and device marker carries the same run ID and artifact hash.

Repair: create a per-run directory before launch and put the run ID in every filename and report header. Record X11 tree output and the selected window's geometry/visual immediately before each capture; reject hard-coded XIDs and generic artifact paths in acceptance evidence.

## Newly introduced process risks

### 4. Live-device work was interleaved with mutable source patches, worktrees, and builds — P0

While manual device sessions and repeated capture attempts were active, the parent edited the AHB output patch and tracing code at lines `39560–40141`, created a detached `gamescope-headless-source-seven` worktree at `40158`, encountered patch-shape/check iteration at `40172–40223`, and started a trace build at `40238`. The parent then started `./android/nova-lab/build.sh` at `40296` while the trace build's polling continued through `40292`; the audit window ends before a clean, serialized completion and provenance handoff is shown.

This is distinct from the prior audit's “verification was broad but not gated” finding: the risk is now concurrent mutation, not merely late verification. A later device observation can silently use the old artifact, a partially rebuilt artifact, or a different worktree than the one being reasoned about.

Repair: enforce a three-phase gate: stop/clean device session; build in an immutable, uniquely named source/build directory; verify source commit, patch digest, binary SHA-256, and feature markers; only then deploy a new run. Do not allow a device capture command to run while the corresponding build directory is being modified.

### 5. Patch integrity was repaired by repeated hunk surgery without a single clean apply/build gate — high

The AHB patch was edited multiple times at `40028–40054` and `40172–40223`, with explicit hunk recount/check and path correction steps. The trace source/worktree path was also mistyped once as `/Users/kurt/Developer/steam-android-research` at line `40167` before being corrected.

The parent did perform checks, but the process leaves an artifact-provenance gap: there is no single recorded line showing “clean source checkout + exact patch applies + build completes + resulting binary hash and feature marker” before the next live deployment/capture.

Repair: use a disposable clean worktree and a script that applies the patch with `--check`, builds, records the source commit and patch SHA, verifies the binary marker/hash, and exits nonzero on any mismatch. Treat a failed patch check as the end of that experiment, not as an invitation to keep the device session running.

### 6. Device focus and capture target selection remain manually inferred — medium

Some focus checks were added at line `37232`, but later interactions still used raw taps and key events at `38287` and `39300`, while the X11 capture selected fixed window IDs at `39258`. The session did not show a single pre-input/pre-capture record containing Android focused window, Steam CDP target identity, X11 tree, selected XID, geometry, and run ID together.

Repair: make focus/target discovery a required precondition for each input/capture pair. Fail closed when the Android overlay, CDP page, or X11 window identity differs from the recorded target; do not rely on a previous tree listing or a remembered XID.

## What improved

- The parent used source-vs-Android captures rather than relying only on the Android screenshot (`39300–39319`, `39378–39410`).
- It added diagnostic tracing intended to be observational rather than immediately changing ownership behavior (`39560–39568`, `40028–40054`).
- It continued to perform syntax, diff, and patch checks (`38454`, `39204`, `40172–40223`), and explicitly searched for relevant process/report state (`39527–39556`).

These are good ingredients, but they need to be serialized behind the run/artifact gates above.

## Prioritized repair list to send to the parent

1. **P0 — Stop and clean before any more build or device work.** Add an assertion that no Nova/Gamescope/Steam process or active manual launcher exists before a source/build mutation. The current window ends with a live-build/live-session overlap (`39231`, `40238–40296`).
2. **P0 — Make artifact identity atomic.** Build from one clean worktree, record source commit + patch SHA + binary SHA + feature flags, and deploy only that immutable bundle. Do not interpret captures until those values are printed in the same run record (`40158–40223`, `40238–40296`).
3. **P1 — Replace sleep-based sampling.** Correlate input dispatch, X11 source capture, Android present, and release/ACK markers by run/frame ID; fixed 3/12/27-second samples are insufficient (`39300–39410`).
4. **P1 — Eliminate stale/generic evidence paths.** Put all screenshots/logs/metadata under a per-run directory and reject persistent Steam logs or generic `current-*` files unless their freshness cursor and run ID are verified (`37324–37377`, `39364–39372`).
5. **P1 — Discover focus and X11 target every run.** Replace hard-coded XIDs and raw input with a required target-discovery record (`39258`, `37232`, `39300`).
6. **P2 — Keep patch/build diagnosis bounded.** One patch hypothesis, one clean apply check, one build, one hash/feature verification; abandon the experiment on patch drift instead of repeatedly editing a live-run artifact (`40028–40223`).
