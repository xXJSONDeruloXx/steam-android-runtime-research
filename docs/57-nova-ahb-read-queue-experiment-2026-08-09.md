# Nova AHardwareBuffer read-queue experiment — 2026-08-09

Status: executed; result recorded in [doc 58](58-nova-ahb-read-queue-result-2026-08-09.md).

## Motivation

The transport-observability result in
[`docs/54-nova-ahb-transport-observability-result-2026-08-09.md`](54-nova-ahb-transport-observability-result-2026-08-09.md)
proves a stable generation-1 peer pair and full Gamescope ACK sends, while
Android remains inside `recvmsg()` for the matching frame. The Android socket
already has a 15-second receive timeout, but the previous run stopped after
the Gamescope release timeout and before that receive timeout could return.

The next run must preserve the timeout return rather than stopping at the
first downstream release error. A queue snapshot after the receive returns,
plus the blocked thread's wait state, distinguishes an empty socket/wake
problem from a late or misread record without peeking SCM_RIGHTS in the normal
protocol path.

## One-variable diagnostic change

Keep the original `SOCK_STREAM` transport, three-buffer ring, connection
identity/ancillary tracing, AHardwareBuffer ownership, SurfaceControl
transaction, release-fence policy, pacing, fullscreen 1280x960 presentation,
and input mode unchanged.

Add only an Android-side `FIONREAD` snapshot after a negative ACK `recvmsg()`
return. The trace records the queued byte count and the queue-query errno, if
the ioctl itself fails, in the existing `ack_wait_end` diagnostic payload.
Successful ACK messages retain their current payload and processing. Do not
use `MSG_PEEK`, retransmission, reconnect, ring changes, or a different socket
type.

## Run protocol

1. Read `docs/34-nova-runtime-harness-lifecycle.md` and use a fresh run ID,
   stream profile, preflight manifest, exact artifact provenance, and the
   bounded manual timeout guard.
2. Reproduce the language → timezone A-button transition with dynamic focus
   and X11 target discovery.
3. At the first `ack_wait_begin` that remains blocked, preserve at least 20
   seconds after that marker. Collect the Android `ack_wait_end` timeout and
   `FIONREAD` result, Gamescope's matching full ACK and release timeout, and
   `/proc/<app-pid>/task/<tid>/wchan`/thread inventory snapshots.
4. Invoke `verify-nova-post-stop.sh` with the run report, run ID, and any ADB
   forward port. Do not hand-write nested shell checks as the primary teardown
   evidence.

## Interpretation

- `recvmsg() = -1`, `errno=EAGAIN`, and `FIONREAD=0` on the same stable socket
  after Gamescope's full ACK send: transport queue/wake or endpoint lifecycle
  remains the leading boundary; escalate to a device-capable syscall observer
  or kernel trace.
- `recvmsg() = -1` with queued bytes greater than zero: the receive timeout
  and queue state disagree; inspect thread scheduling, syscall identity, and
  any competing reader before changing protocol code.
- A positive receive or protocol error after the timeout: the earlier
  `wait_ack` line was an incomplete boundary; follow the newly returned
  ancillary state and do not infer a missing ACK.
- A second runtime reader or a different thread wait state: repair reader
  ownership/lifecycle before investigating SurfaceControl.

The SurfaceControl previous-release-fence `-1` correction remains a separate
experiment and must not be included here.
