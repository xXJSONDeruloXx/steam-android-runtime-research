# Nova physical controller live confirmation — 2026-08-10

## Status

The physical controller path is considered solved for the current Nova
Termux:X11/Steam session. The operator reports that the real physical
controller on the device now works correctly, including normal controller
operation in the live session.

This is a manual confirmation from the active signed-in session, not a new
bounded instrumentation run. It is therefore a current product-status
decision, not a replacement for the earlier evdev, uinput, SDL, and Steam
consumer evidence.

## Roadmap impact

- Remove controller transport, Android dispatch, and Steam UI navigation from
  the immediate blocker list for the Termux:X11 path.
- Keep the working physical controller path frozen as a regression baseline
  while rendering, audio, networking, aspect ratio, and lifecycle work
  continues.
- Recheck controller behavior later when a game produces a frame, including
  game-specific ABXY/axis mapping, rumble, hotplug, and suspend/resume. Those
  are compatibility checks, not reasons to reopen the current controller
  bridge now.
- Treat controller behavior on a future Gamescope/AHardwareBuffer renderer as
  a separate integration/regression check rather than evidence against this
  accepted Termux:X11 result.

## Evidence boundary

The confirmation applies to the current signed-in Nova Android session and
does not by itself establish that a different renderer, a launched game, or a
rootless process boundary preserves the same behavior. The next active gates
remain game rendering, audio, and the relevant session/network details.
