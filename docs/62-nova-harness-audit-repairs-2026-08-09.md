# Nova harness audit repairs — 2026-08-09

Status: implemented after the sixth Luna parent-session audit; no device run
was performed by this change.

The audit in
[`docs/61-parent-session-process-audit-followup-2026-08-09.md`](61-parent-session-process-audit-followup-2026-08-09.md)
found four recurring evidence risks. This checkpoint repairs those risks
before the next AHardwareBuffer experiment.

## Repairs

- `capture-nova-x11-window.sh` discovers the mapped Steam Big Picture X11
  window, writes the run-scoped ID manifest during the baseline phase, and
  rejects a changed or manually substituted ID for later captures.
- `capture-nova-manual-evidence.sh` collects CDP, focus, Android screenshot,
  and X11 artifacts sequentially and writes a required per-phase aggregate
  `capture_status=pass` record only after every artifact has a successful
  command and nonempty output.
- `poll-nova-ahb-boundary.sh` filters logcat by the launched Android PID,
  requires the current process's launch marker before accepting a boundary,
  writes `marker-source.txt` with the run/PID freshness fields, and records a
  bounded marker or an explicit failure.
- `finish-nova-manual-run.sh` serializes stop, report transfer/hash, ADB
  forward removal, and the existing fail-closed post-stop verifier under one
  `set -euo pipefail` wrapper.

These changes are harness-only. They do not modify socket type, ring count,
AHB ownership, SurfaceControl pacing, fence generation, or Steam input.

## Validation

The next device run must use the new helpers for all three capture phases, the
PID-filtered boundary poll, and teardown. Before deployment, run `bash -n` on
all four helpers and verify that each is executable. A run is not publishable
unless the capture status, marker freshness, and post-stop verifier all pass.

## Next experiment boundary

After these guards are in place, the next one-variable AHB diagnostic may
replace only the blocking ACK boundary with a property-gated timed
`poll()`/`recvmsg()` observation. Its purpose is to obtain queue state at a
known deadline now that `SO_RCVTIMEO` setup has been proven valid. Keep the
stream transport, three-buffer ring, SurfaceControl path, fences, and input
sequence unchanged.
