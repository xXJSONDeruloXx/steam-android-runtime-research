# Nova AHardwareBuffer poll/recvmsg boundary experiment — 2026-08-09

Status: predeclared; no device result yet.

This experiment follows the attached handshake-deadlock research synthesized
in [`docs/10-ahb-and-harness/63-nova-ahb-handshake-deadlock-research-synthesis-2026-08-09.md`](63-nova-ahb-handshake-deadlock-research-synthesis-2026-08-09.md)
and the valid-but-ineffective `SO_RCVTIMEO` result in
[`docs/10-ahb-and-harness/60-nova-ahb-receive-timeout-observability-result-2026-08-09.md`](60-nova-ahb-receive-timeout-observability-result-2026-08-09.md).

## Question

At the first Android `wait_ack` boundary, does the ACK socket become readable
within a known deadline, and what does `FIONREAD` report at that same boundary?

This is a transport-observation experiment. It does not claim that a timeout
proves a kernel socket fault or that a readable socket proves SurfaceControl is
healthy.

## One-variable change

Add the property-gated Android property
`debug.nova.ahb_ack_poll_timeout_ms`, exposed by the host as
`NOVA_AHB_ACK_POLL_TIMEOUT_MS`.

- Default `0`: preserve the existing blocking `recvmsg()` behavior.
- Diagnostic run: set `15000` milliseconds before the Activity starts.
- After `ack_wait_begin` and the existing zero-duration probe, call
  `poll(POLLIN|POLLERR|POLLHUP|POLLNVAL, 15000)`.
- Log the poll result, revents, and errno only for a negative result.
- On a poll timeout, query `FIONREAD`, log the queued byte count and queue
  errno, and return without calling `recvmsg()`.
- On readability, continue through the existing `recvmsg(MSG_CMSG_CLOEXEC)`
  and ancillary validation path.

The deployer validates the property range, records it in run metadata, resets
it during preflight and cleanup, and the post-stop verifier requires it to be
`0`. The default path remains unchanged for all other runs.

## Invariants

Keep all of the following unchanged:

- original `SOCK_STREAM` transport;
- three-buffer ring and modulo scheduling;
- AHardwareBuffer import and ownership;
- acquire/release fence generation and SurfaceControl transaction pacing;
- Steam/X11/input sequence and 1280x960 presentation profile;
- Gamescope binary, source tree, libei requirement, and provenance gates.

The run must use the guarded lifecycle from
[`docs/00-start-here/34-nova-runtime-harness-lifecycle.md`](../00-start-here/34-nova-runtime-harness-lifecycle.md),
including a fresh run directory, fresh process/log baseline, exact artifact
metadata, dynamic X11 capture, PID-filtered boundary polling, and the checked
teardown helper.

## Required evidence

Record:

- `nova_ahb_ack_poll_timeout_ms=15000` in metadata;
- `ahb_socket_timeout ... ack_poll_timeout_ms=15000` at client setup;
- `ahb_socket_poll op=ack_wait_timed` at the first blocked frame;
- either `ahb_socket_trace op=ack_wait_timeout` with
  `recv_timeout_queue_bytes`, or a readable-poll result followed by the exact
  `recvmsg` outcome and ancillary fields;
- the current Android PID and marker-freshness record;
- same-run CDP, Android, and dynamically discovered X11 captures;
- per-phase ADB-forward manifest proving the CDP forward existed before the
  capture started;
- post-stop property reset, no residual processes/files/forward, and trace
  reset verification.

If the app exits immediately after a timed poll, capture the boundary log and
the three same-run evidence phases before teardown; do not extend the run by
reusing a later process or stale log.

## Interpretation

| Observation | Meaning for the next step |
|---|---|
| Poll times out and `FIONREAD=0` | No readable ACK was present at the measured boundary. Compare the exact endpoint identities and sender syscall; do not call this a kernel defect yet. |
| Poll times out and `FIONREAD>0` | The readable state and wait observation disagree. Preserve the socket identity, PID/TID, and timing evidence; investigate competing readers or descriptor misuse. |
| Poll returns readable | The old indefinite `recvmsg()` boundary was incomplete. Analyze its return, message flags, cmsg layout, received FD, and then SurfaceControl phases. |
| Poll returns an error | Treat the poll error as the new transport boundary and inspect descriptor lifecycle/connection state. |
| Property setup or reset fails | Reject the run as invalid; do not interpret the app trace. |

The result must be documented and pushed before changing socket type, ring
count, SurfaceControl backpressure, fence generation, or release identity.
