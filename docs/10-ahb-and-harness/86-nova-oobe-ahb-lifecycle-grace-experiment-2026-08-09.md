# Nova OOBE AHB lifecycle-grace experiment — 2026-08-09

Status: predeclared; device result pending.

## Causal hypothesis

The overlay-guard rerun in [doc 85](85-nova-bounded-overlay-guard-experiment-2026-08-09.md)
did dismiss a mid-run `com.rp.settings` chooser, but the Android AHB peer still
closed at frame 82. The current `MainActivity.onStop()` cancels the native
presentation bridge immediately. A transient settings Activity can therefore
trigger cancellation before the focus guard restores the Nova Activity.

## One-variable implementation

Keep the overlay guard, input mapping, no-trigger Gamescope, marker, frame
identity, presentation flags, and 240-frame target unchanged. Change only the
Android lifecycle behavior:

- `onStop()` schedules native bridge cancellation after a 5-second grace;
- `onStart()` cancels that pending teardown when the Activity returns; and
- `onDestroy()` still cancels immediately and removes the pending callback.

This preserves explicit teardown for a real Activity destruction while allowing
a short-lived system overlay to be dismissed without killing the live AHB
session.

## Acceptance gates

Accept only if the same A-button transition remains strict-pass, the AHB app
report reaches 240 frames and 239 releases, the final marker correlates to its
producer frame/checksum, no settings overlay remains in the final capture, and
the independent post-stop process/file/property verifier passes. A longer
session without those gates remains partial.
