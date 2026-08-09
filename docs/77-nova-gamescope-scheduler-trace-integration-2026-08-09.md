# Nova Gamescope scheduler-trace integration (2026-08-09)

Status: source/build integration committed; clean ARM64 compilation and device
validation are the next gates. This checkpoint resolves the reproducibility
gap around the scheduler diagnostic; it does not claim a Steam login screen or
end-to-end frame identity.

## Problem

The scheduler trace required to distinguish a missing Gamescope repaint from a
block in the Android output path existed as an untracked patch while the
tracked build script did not apply it. The existing scheduler-trace binary
therefore had dirty-source provenance and could not be reproduced from the
repository alone. The original predeclared experiment was also named doc 71,
but the pulled history now uses doc 71 for the continuous-repaint result.

## Implementation

`android/nova-lab/build-gamescope-headless.sh` now applies
`android/nova-lab/patches/gamescope-headless-ahb-scheduler-trace.patch` after
the clock-trace patch and before the libei/touch patch. The patch remains
opt-in through `NOVA_AHB_SCHEDULER_TRACE=1` and records:

- same-commit `paint_all` early returns;
- `paint_all` entry;
- one-per-second idle `paint_decision` heartbeats with repaint and paint
  decisions; and
- `Present()` entry and return with compositor layer count and result.

The instrumentation preserves the original three-buffer stream transport,
no-global-repaint scheduler behavior, libei input path, and SurfaceControl
fence protocol.

## Build and device gate

The integration is not accepted as a device result until a clean source copy
passes sequential patch application, ARM64 Gamescope compile/link, APK build,
and a fresh bounded run with exact source/binary/APK provenance. The old dirty
binary is not used as proof for that gate.

The eventual run must correlate the scheduler trace with the Android AHB trace
using the shared monotonic clock. In particular, the frame-148
`ack_sent`/frame-149 `wait_release` boundary must show whether Gamescope
selected no repaint, entered `Present()`, or blocked before the Android output
wait.

## Remaining observability gap

Scheduler timestamps explain why a producer frame was or was not attempted,
but they do not yet identify the exact visual content latched by Android or
captured from X11. A later frame-identity change still needs to add a stable
producer commit/frame ID and a visual checksum to the ACK/report path, then
correlate those values with same-run Android and X11 captures before a login
screen can be accepted.
