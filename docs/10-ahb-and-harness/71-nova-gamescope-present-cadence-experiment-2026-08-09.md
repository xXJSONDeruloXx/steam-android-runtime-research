# Nova Gamescope present-cadence experiment — 2026-08-09

Status: predeclared; no device result yet.

This experiment follows the clock-correlated boundary in
[`docs/10-ahb-and-harness/70-nova-ahb-clock-correlated-socket-trace-result-2026-08-09.md`](70-nova-ahb-clock-correlated-socket-trace-result-2026-08-09.md).
That result proves that the frame-149 `wait_release` line is the first event
inside Gamescope's Android-output `Present()` branch. The next question is
therefore whether the 60-second interval is a missing repaint/present trigger
or a block inside the output path.

## One-variable diagnostic

Add a bounded, opt-in scheduler trace to Gamescope. With
`NOVA_AHB_SCHEDULER_TRACE=1`, record:

- `paint_all()` entry and its same-focus/same-override-commit early return;
- the repaint decision's `vblank`, `hasRepaint`,
  `hasRepaintNonBasePlane`, and `bShouldPaint` state, with at most one idle
  heartbeat per second;
- `Present()` entry and return around the existing Android-output phases.

Keep the original `SOCK_STREAM` transport, three-buffer ring, SurfaceControl
pacing, fence generation, 1280x960 fullscreen presentation, libei-enabled
Gamescope artifact, and Android keyevent input path unchanged. Do not add a
one-buffer fallback, single control socket, retransmission, or release-fence
semantic change in this experiment.

## Build gate

The scheduler trace must be a separate post-clock-trace patch. Fresh source
application must pass sequential patch checks, ARM64 Gamescope compile/link,
and the existing Android APK build. The device artifact must record the exact
Gamescope/APK hashes and the new trace flag.

## Decision gate

Correlate the last healthy frame-148 `ack_sent` with the next frame-149
`wait_release`:

```text
No paint_all/Present during the gap
  -> investigate commit arrival, hasRepaint bookkeeping, vblank gating, and
     whether Gamescope is expected to repeat a static frame.

paint_all occurs, but Present does not
  -> investigate paint_all's early-return or pre-Present path.

Present enters and blocks before wait_release
  -> add a narrower trace around that blocking call; this would revise the
     source audit.

Present enters at wait_release promptly, but ACK still does not arrive
  -> return to release/ring/socket ownership and unexpected-reader hypotheses.
```

The result must preserve the same-run Android final capture and guarded
teardown. A stale prior process or pre-existing Gamescope log cannot satisfy
this experiment.
