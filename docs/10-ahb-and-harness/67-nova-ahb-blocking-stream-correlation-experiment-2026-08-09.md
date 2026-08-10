# Nova blocking-stream ACK correlation experiment — 2026-08-09

Status: executed; result documented in
[`docs/10-ahb-and-harness/68-nova-ahb-blocking-stream-correlation-result-2026-08-09.md`](68-nova-ahb-blocking-stream-correlation-result-2026-08-09.md).

This run follows the valid timed boundary in
[`docs/10-ahb-and-harness/66-nova-ahb-poll-recvmsg-boundary-result-2026-08-09.md`](66-nova-ahb-poll-recvmsg-boundary-result-2026-08-09.md).
The timed poll proved that a finite boundary can see zero queued bytes, but it
also closes Android before Gamescope can complete the matching ACK. The next
run must preserve the original blocking receiver so the sender and receiver
can be compared at the same frame.

## One-variable experiment

Use the exact stream profile and current diagnostic source, but leave
`NOVA_AHB_ACK_POLL_TIMEOUT_MS` unset or set to `0`. This restores the existing
blocking `recvmsg(MSG_CMSG_CLOEXEC)` path. Do not change the ring, SurfaceControl
transactions, fences, Gamescope artifact, presentation size, or input path.

Use the corrected PID-filtered boundary helper. It must clear a provisional
blocked frame when a positive ACK arrives, recognize explicit timed-poll
events if present, and only report `blocked_ack_window` when the same frame
remains without a positive ACK for the configured window.

## Required correlation

At the first persistent Android `wait_ack`, capture both sides through at least
the next Gamescope release wait:

```text
Android:   ack_wait_begin -> wait state / ack_received result
Gamescope: ack_send requested length, return, errno, socket identity
```

The high-value result is whether Gamescope records a complete ACK for the same
frame while Android remains in that frame's receive wait. Preserve the exact
endpoint table, connection generation, peer PIDs, cmsg/rights fields, and
`poll()` return semantics. If the app's blocking receive remains active, keep
the session long enough to capture Gamescope's subsequent release-message
timeout and 15–20 seconds afterward.

Use the fresh-run forward/capture guards and the checked teardown. A run is not
interpretable unless baseline, after-A, and final capture statuses, marker
freshness, artifact provenance, and post-stop verification all pass.

## Interpretation

- Full ACK send for N plus no Android positive receive for N: reproduce the
  report's strongest transport boundary; prioritize reader/queue/lifecycle
  tracing before SurfaceControl changes.
- No full ACK send before Android waits: the sender's release/composition
  pacing is part of the initiating boundary; add timestamps around Gamescope's
  release wait and ACK send before changing Android.
- Positive Android ACK receive followed by SurfaceControl/release failure:
  advance the investigation to buffer identity and SurfaceControl semantics.
