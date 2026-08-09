# Termux:X11 native ARM64 Steam experiment — 2026-08-09

Status: predeclared experiment; no device launch has occurred for this
profile.

## Hypothesis

The physical Android screen gate is now proven for a rootfs-native X11 client.
The next question is whether the existing native ARM64 Steam tree can use the
same Termux:X11 socket directly, without Gamescope, the Nova AHardwareBuffer
bridge, or SurfaceControl.

This experiment changes only the X11 client payload: the synthetic animation
is replaced by a small run-scoped launcher that starts the installed ARM64
Steam client with the existing disposable-rootfs compatibility contract.

## Launch profile

The host deploy harness remains
`android/nova-lab/deploy-termux-x11-forwarding-smoke-test.sh`, with:

```text
client=android/nova-lab/device/nova-termux-x11-steam-client.sh
display=:0
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
steam_flags=-gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox
steam_renderer=swrast + softpipe + LIBGL_ALWAYS_SOFTWARE=1
steam_uid=501:20
steam_timeout=60s
x11_window_name=any viewable depth-1 child
x11_window_wait_seconds=25
allow_x11_capture_failure=1
```

The launcher runs the existing native ARM64 Steam executable, applies the
existing network API compatibility helper, grants only local X11 access with
`xhost +local:`, and uses the already-built System V semaphore shim. It writes
the Steam startup log and stdout/stderr under the disposable rootfs `/tmp`.

## Acceptance gates

The run is useful only if it records all of the following with one fresh run
identity:

1. explicit preflight cleanup pass;
2. a fresh Termux:X11 socket and Android Activity;
3. a viewable depth-1 X11 child window from the Steam client;
4. an Android `screencap -p` artifact, visually inspected for Steam content;
5. fresh Steam client/webhelper/SteamUI markers, if reached; and
6. exact Termux:X11 plus Nova-rootfs cleanup and post-stop verification.

The X11-side `XGetImage` helper remains observational in this first Steam
profile. A `BadMatch` result cannot turn an Android screenshot into a pixel
pass by itself.

## Interpretation

Possible first boundaries are deliberately separated:

- no X11 child: Steam startup, loader, bootstrap, or X11 authorization;
- Steam child but no webhelper: Steam bootstrap/update/CEF lifecycle;
- webhelper/browser markers but no visible Android Steam content: CEF/X11
  rendering or window selection;
- visible Steam content but no login/OOBE: input/network/Steam state; or
- visible login/OOBE: proceed to the next separately documented input and QR
  login experiment.

This is the direct-X11 alternative to the low-level Gamescope/AHB line; a
failure must not trigger another Gamescope patch in this branch.
