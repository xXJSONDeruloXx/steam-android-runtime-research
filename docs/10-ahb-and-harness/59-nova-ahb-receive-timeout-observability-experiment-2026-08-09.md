# Nova AHardwareBuffer receive-timeout observability experiment — 2026-08-09

Status: predeclared; no device result yet.

## Motivation

The read-queue result in
[`docs/10-ahb-and-harness/58-nova-ahb-read-queue-result-2026-08-09.md`](58-nova-ahb-read-queue-result-2026-08-09.md)
reproduced Android's frame-133 `wait_ack` while Gamescope completed the
matching ACK send. Android's source sets `SO_RCVTIMEO` to 15 seconds on each
accepted AHardwareBuffer client, but the blocking `recvmsg()` remained active
for the entire observation window and never reached the new `FIONREAD` path.
The setup call's return value and the kernel's effective option were not
recorded, so the queue result cannot yet be interpreted.

## One-variable diagnostic change

Keep the stream transport, three-buffer ring, connection identity and
ancillary tracing, AHardwareBuffer ownership, SurfaceControl transactions,
release-fence policy, fullscreen 1280x960 presentation, pacing, and Android
input sequence unchanged.

Replace the ignored client-side `setsockopt(SO_RCVTIMEO)` calls with a helper
that performs the same call and immediately reads the option back with
`getsockopt()`. When socket tracing is enabled, log the requested timeout,
both syscall results and conditional errno values, the effective timeout, and
the existing socket identity. This is observability only; it does not change
the requested timeout or add a new timeout path.

Instrument both the legacy single-buffer client and the three-buffer client so
the source does not leave an unobserved receive-timeout setup path. The
manual run uses only the latter.

## Run protocol

1. Read `docs/00-start-here/34-nova-runtime-harness-lifecycle.md`; use a fresh run ID,
   stream profile, mandatory preflight manifest, exact artifact provenance,
   and the bounded manual timeout guard.
2. Build and deploy the APK containing this diagnostic, with the same
   Gamescope binary and flags as the read-queue run.
3. Reproduce the language → timezone A-button transition with dynamic focus
   and X11 target discovery.
4. Capture the `ahb_socket_timeout` records at client setup. If a frame
   reaches `wait_ack`, preserve at least 20 seconds after the first blocked
   ACK and collect the existing `ack_wait_end`/`FIONREAD` evidence.
5. Stop through the guarded manual-session path and run
   `verify-nova-post-stop.sh`. Do not use ad-hoc teardown checks as the
   authoritative cleanup result.

## Interpretation

- `setsockopt()` fails or readback fails: repair the timeout setup path before
  interpreting any receive queue behavior.
- Both calls succeed and read back 15 seconds: if `recvmsg()` returns around
  that deadline with `EAGAIN`, the queue probe becomes meaningful; if it still
  does not return, investigate the device's socket wait behavior or the exact
  blocking call before changing protocol framing.
- Readback is a different nonzero timeout: preserve the observed value and
  determine whether Android's socket-option unit/rounding semantics explain
  the wait; do not silently normalize it in this run.
- The ACK returns positively or a protocol error occurs: follow that new
  ancillary result; the earlier `wait_ack` line was only an incomplete
  boundary.

Do not change socket type, ring count, SurfaceControl backpressure, fence
generation, reader ownership, reconnect behavior, or the independent
previous-release-fence `-1` handling in this experiment.
