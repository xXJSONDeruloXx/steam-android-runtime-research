# Nova one-click touch interaction predeclaration — 2026-08-10

Status: predeclared; device acceptance is pending.

## Question

Does the user-facing APK launch path preserve Android touch interaction all the
way to the signed-in Steam Big Picture UI when Termux:X11 is the active
surface? The earlier libei/AHardwareBuffer touch records prove a separate
Gamescope transport seam, while the direct one-click profile has only been
visually and audibly accepted so far.

## Fixed run

Use a fresh run of the current pushed APK. Start the Steam session only by
tapping the visible `Start Steam` button; do not pass Steam launch extras.
After the signed-in Steam home is visible, capture a baseline, tap the
`Friends` navigation item at approximately `(620,545)` on the 1280x960 Nova
surface, wait for the UI to settle, and capture the same surface again.

The run keeps the known-good profile unchanged:

```text
audio_bridge=1
hardware_accel=1
cef_disable_gpu=1
steam_ui_mode=gamepadui
steam_force_software_gl=1
steam_cef_env_split=1
x11_display=1280x960
```

The coordinate is a touch-input probe only; it is not a controller or keyboard
event. No low-level source or Gamescope code changes are included.

## Acceptance

Require:

1. fresh APK-button launcher markers and a visible signed-in Steam baseline;
2. a current Termux:X11 foreground surface at 1280x960;
3. an Android touch injection that changes the Steam UI region, with before and
   after screenshots and hashes; and
4. exact launcher/X11/runtime cleanup with no matching Nova process left.

If the screen does not change, classify the failure by checking Android input
focus and the Termux:X11 window rather than treating a changed screenshot hash
alone as touch success. This result applies only to the direct X11 product
profile; the native Gamescope/AHardwareBuffer touch path remains a separate
requirement.
