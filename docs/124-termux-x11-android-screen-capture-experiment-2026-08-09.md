# Termux:X11 Android screen capture experiment — 2026-08-09

Status: predeclared; no device result yet.

This is the next one-variable experiment after the mapped synthetic-window
result in [doc 123](123-termux-x11-synthetic-window-result-2026-08-09.md). It
does not launch Steam, Gamescope, the Nova APK, or the AHardwareBuffer bridge.

## Question

Does a mapped Linux X11 window reach the physical Android `SurfaceView` even
when the server-side `XGetImage` request cannot read that Xwayland window?

The synthetic client, official Termux:X11 APK, display, dimensions, rootfs,
and private launcher remain unchanged. The only experiment-level presentation
change is to continue after a classified X11 PPM capture failure and collect a
fresh Android `screencap` while the same named window is mapped. The X11 PPM
result remains recorded as pass or observational failure; it is not silently
treated as a pixel pass.

## Harness repair committed before launch

The cleanup helper now uses one bounded Android `ps -A` query with exact
server/client token filters instead of spawning a shell pipeline for every
`/proc` entry. The prior run's stuck helper and exact manual teardown are
recorded in doc 123. The script also accepts
`NOVA_TERMUX_X11_ALLOW_X11_CAPTURE_FAILURE=1` for this explicitly named
physical-screen experiment, so a server-side `BadMatch` cannot prevent the
Android screenshot gate from running.

## Procedure and acceptance

1. Read `docs/34-nova-runtime-harness-lifecycle.md` immediately before the
   run and establish a fresh run identity.
2. Install the same official APK, start the same display, and launch the same
   1280x720 synthetic client through the committed private namespace and
   dedicated client launcher.
3. Require the named synthetic window to be mapped in a fresh X11 tree.
4. Attempt the existing X11 PPM capture and record its exact status. Continue
   under the opt-in failure profile if it returns `XGetImage`/`BadMatch`.
5. Capture Android `screencap`, focused-window state, and fresh Termux:X11
   logcat while the mapped window is still alive. Inspect the screenshot for
   the synthetic animation and record its SHA-256.
6. Run exact teardown and require the bounded process/socket verifier to pass.

Pass for this experiment requires the synthetic window, a non-empty Android
screenshot captured with Termux:X11 focused, and clean teardown. An X11 PPM
failure remains a separately reported server capability limitation. Do not
claim Steam/OOBE progress from this run.

## Provenance

```text
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
termux_x11_source_commit=d8013ac5d174bb16120f915c10a7255948c59c17
x11_animate_sha256=884853cdc47c0d10a644153404fcd25e155b8784e24903f3ced568649b10bc04
x11_capture_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017
display=:0
client_dimensions=1280x720
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

If this passes, the next experiment can predeclare native ARM64 Steam over
direct Termux:X11. If it fails, keep the failure at the Android Activity,
SurfaceView, or cleanup boundary and do not introduce Steam as a confounding
variable.
