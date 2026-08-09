# Nova AHardwareBuffer app receive-wait experiment card — 2026-08-08

Date: 2026-08-08

Status: executed; result recorded in [doc 52](52-nova-ahb-app-receive-wait-result-2026-08-09.md).

## Motivation

The stream socket-trace run
`manual-20260808T234314Z-ahbsockettrace` showed complete Gamescope ACK sends
through frame 431, then a release wait timeout at frame 432/index 0. Android's
last completed `ack_recv` was frame 429 and its next visible state was
`wait_ack` for frame 430. The current Android trace logs the `recvmsg` result
only after that call returns, so it cannot yet distinguish an app-side blocked
receive from a loop that stopped before entering the receive path.

## One-variable change

Keep the original `SOCK_STREAM` transport, three-buffer ring,
AHardwareBuffer ownership, SurfaceControl transaction, release-fence handling,
pacing, fullscreen 1280x960 presentation, Gamescope artifact, and input mode.
Add only opt-in Android-side receive-wait diagnostics around the existing
blocking ACK `recvmsg`:

- `ack_wait_begin` immediately before the call, with frame, buffer, FD, inode,
  and socket type;
- a zero-timeout `poll(POLLIN|POLLERR|POLLHUP|POLLNVAL)` recorded as
  `ack_wait_probe`, without consuming data or changing the existing blocking
  call; and
- `ack_wait_end`/the existing `ack_recv` result after the call returns,
  including errno, flags, ancillary-rights count, and fence FD.

The probe must remain disabled by default and must not add a receive timeout,
nonblocking mode, retry, close, or fallback behavior. The purpose is to record
the state at the exact boundary, not to make the loop progress.

## Interpretation

1. `ack_wait_begin` plus a zero-result probe and no `ack_wait_end` while
   Gamescope logs a full ACK send means Android entered the blocking receive
   path but did not observe readable data at the probe; investigate peer wake or
   socket delivery/identity next.
2. `ack_wait_probe` reports `POLLIN` but no completed receive means the
   ancillary/stream receive path or descriptor handling needs closer inspection.
3. The final Android record is not `ack_wait_begin` for the expected frame,
   while SurfaceControl/presentation records are also absent, so the app loop
   stopped before consuming the ACK socket; investigate buffer state or the
   presentation callback boundary.
4. A complete `ack_wait_end` with valid payload and fence through the route
   transition leaves the receive path and moves the next experiment to the
   downstream release/latch boundary.

## Run gate

Before launch, read `docs/34-nova-runtime-harness-lifecycle.md`, use a new
run-scoped profile and preflight manifest, and record the exact Gamescope/APK
and source digests. Rediscover the Android focus before every input and the
mapped X11 window before every capture. Correlate CDP, X11, Android, and both
socket traces under the same run ID. Stop at the first classified receive-wait
boundary or a same-run network-route correlation, then require exact runtime,
app-file, and trace reset pass markers before documenting the result.

Do not combine this card with an ownership, ring-size, fence-policy, timing,
font, or input workaround.
