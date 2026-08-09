# Parent session process audit — follow-up 5 — 2026-08-09

## Scope

- Source: `/Users/kurt/.codex/sessions/2026/08/07/rollout-2026-08-07T10-58-54-019fdcbb-f967-7153-bc2e-2a2eb9a26093.jsonl`
- Audit window: `2026-08-08T22:35:00Z` through `2026-08-09T00:35:00Z`.
- Compared with: `docs/34-nova-runtime-harness-lifecycle.md`,
  `docs/35-parent-session-process-audit-2026-08-08.md`,
  `docs/40-parent-session-process-audit-followup-2026-08-08.md`,
  `docs/43-parent-session-process-audit-followup-2026-08-08.md`,
  `docs/46-parent-session-process-audit-followup-2026-08-08.md`, and
  `docs/50-parent-session-process-audit-followup-2026-08-08.md`.
- Evidence references below are JSONL line numbers, not repository source
  lines.
- This audit is documentation-only. It does not touch the Nova device,
  runtime/source code, staging, commits, or pushes.

## Executive finding

The parent made real progress: the latest transport-observability run used a
fresh run directory, finite 900-second timeouts, the mandatory preflight
manifest, dynamic CDP/X11 setup, stable endpoint/ancillary tracing, and a
clean exact-scope stop. The run also produced the strongest evidence so far:
Android remained in `recvmsg` for frame 318 while Gamescope reported complete
ACK sends through frame 319, then reached the expected release wait at frame
320.

The process contract is still not enforced at every boundary. The same window
reintroduced an 86,400-second manual profile, used an incorrect rootfs/tool
path and a hard-coded X11 ID during live evidence collection, accumulated
fixed-delay snapshots instead of polling a readiness marker, and ran a
post-stop collection command without `set -e` or explicit status checks. These
are methodology regressions even though the final transport result is useful.

## Prioritized findings

### 1. P1 — The long-lived timeout regression recurred in the seqpacket run

The seqpacket deployment at JSONL line `41098` explicitly set
`NOVA_STEAM_CLIENT_TIMEOUT=86400` and
`NOVA_STEAM_GAMESCOPE_TIMEOUT=86400`. This repeats the issue called out in
docs/35, docs/40, docs/43, docs/46, and docs/50. The later observability run
used 900-second values at line `43057`, so the parent knows the bounded form;
the problem is that the older ad-hoc manual invocation remains easy to reuse.

Impact: a lost continuation or failed stop can leave the runtime alive for a
day, and the profile is not comparable to the bounded run that followed.

Repair: make the manual launcher reject `86400` and any timeout above the
profile maximum unless an explicitly named `long-lived-manual` profile is
selected. That profile must provide a watchdog/deadline and record
operator-versus-timeout teardown. Put the finite values in one named profile
file so a copied command cannot silently revive the old defaults.

### 2. P1 — Ad-hoc live commands bypassed the run-bound target/tool contract

At JSONL line `41200` the parent used plain `adb` rather than the configured
`/Users/kurt/.local/bin/adb`, targeted `/data/local/tmp/nova-holo-glibc`
instead of the active `/data/local/tmp/nova-holo-rootfs`, and invoked the
capture helper through a different `/bin/sh -c` shape. The next commands at
`41222` and `41223` corrected the rootfs path and captured the intended
run-scoped artifacts. During the same seqpacket run, the capture command at
`41133` used hard-coded X11 window `0x240003b` rather than the window selected
from the current tree.

Impact: a failed probe can look like a protocol failure, and a successful
capture can come from a different rootfs or stale X11 drawable. This directly
repeats docs/34, docs/40, docs/43, and docs/50's stale-evidence and dynamic
target requirements.

Repair: expose `ADB`, `ROOTFS`, `X11_CAPTURE`, `X11_WINDOW`, and the run
directory from one run manifest; require every diagnostic helper to source or
receive that manifest. Reject a hard-coded XID unless it equals the manifest's
current discovered ID, and fail if the selected rootfs/tool path differs from
the launch metadata. Keep failed probes in a `quarantine/` subdirectory with
their exit status instead of allowing them to resemble acceptance artifacts.

### 3. P1 — Fixed-delay evidence collection remains the default around a live stall

The observability run used sequential `sleep 25`, `sleep 20`, `sleep 20`,
`sleep 30`, `sleep 10`, and `sleep 8` collection commands at JSONL lines
`43115`, `43123`, `43141`, `43148`, `43162`, and `43170`. The final result was
good, but the sleeps do not establish that the intended phase transition
occurred; they only sample after elapsed wall time. This is the same recurring
pattern documented in docs/35, docs/40, docs/43, docs/46, and docs/50.

Repair: replace the repeated sleeps with one bounded polling helper that waits
for a named marker such as `ack_wait_begin(frame=318)` followed by
`ack_send(frame=319)` and `release_wait(frame=320)`. It should write the
polling command, marker timestamps, deadline, and final status into the run
manifest. If the marker does not arrive, emit `marker_timeout` and stop
without producing a normal-looking boundary artifact.

### 4. P1 — The post-stop evidence shell was not fail-closed

The post-stop command at JSONL line `43202` began with
`cp android/nova-lab/build/holo-glibc-report.txt` even though the report had
been captured remotely in the run directory; it did not use `set -e`, and it
used `|| true` for the ADB forward removal, app-file check, and residual grep.
The parent then ran additional checks at lines `43224` and `43232`, which
reduced the risk, but the first collection command could have returned success
after a missing report or failed verification.

Repair: make teardown collection a repository helper with `set -euo pipefail`
and explicit, scoped exceptions. Pull or copy the report through one named
function, verify its existence and SHA-256, remove the ADB forward as a
required operation, and make residual-process/app-file/trace-state checks
produce machine-readable pass/fail markers. A second stop may be an emergency
retry, but it must be recorded as a retry rather than hiding the first result.

### 5. P2 — Source/audit/build phases still overlap at the end of a milestone

The parent launched the latest Luna audit after the previous milestone, then
continued source inspection and diagnostic patch construction while audit
handoff/wait activity was still part of the session. The earlier recurrence is
visible at JSONL lines `41891–41902` and is explicitly documented in docs/50;
the current window also includes the large protocol-edit/build sequence before
the final run. The final transport run was correctly deployed from a pushed
checkpoint, so this did not invalidate that run, but it leaves the process
audit observing a moving methodology.

Repair: enforce a phase barrier in the plan and checklist:

1. stop and clean;
2. document and publish the result;
3. run one fresh Luna audit and wait for its completion;
4. incorporate or explicitly defer each repair;
5. write the next experiment card;
6. build and verify immutable artifacts;
7. run the device experiment.

Do not inspect or edit the next protocol hypothesis while step 3 is pending.
Record the audit agent ID, handoff status, completion time, and report path in
the next experiment manifest.

## Controls that improved and should remain mandatory

- The latest run at JSONL line `43057` used a unique run ID/profile, finite
  900-second timeouts, explicit 1280x960 dimensions, artifact provenance, and
  `NOVA_REQUIRE_RUN_MANIFEST=1`.
- The run used dynamic CDP polling and a current X11 tree before capture. The
  Android/Gamescope endpoint trace recorded full payloads, one rights FD, no
  truncation flags, and peer credentials at the boundary described at line
  `43162`.
- The parent preserved the failure window before stopping: Android was waiting
  at frame 318, Gamescope sent through frame 319, and the release wait timed
  out at frame 320 (messages around lines `43162–43170`).
- Exact cleanup was invoked at line `43198`, followed by independent
  post-stop process, app-file, and trace-state checks. Keep those independent
  checks even after the teardown helper passes.

## Repair order for the parent

1. Add a shared, run-scoped diagnostic environment/manifest and reject wrong
   ADB, rootfs, helper, X11, or run paths.
2. Remove 86,400-second values from ordinary profiles; require an explicit
   watchdog-backed exception.
3. Replace boundary sleeps with marker-driven polling and a hard timeout.
4. Make post-stop artifact collection fail-closed and verify report hashes.
5. Finish each Luna audit before source inspection or the next experiment
   card begins.
