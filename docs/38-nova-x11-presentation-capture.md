# Nova X11 presentation capture diagnostic

Status: diagnostic helper added 2026-08-08; first confirmed downstream
release-message stall recorded in
[`docs/39-nova-release-message-stall-2026-08-08.md`](39-nova-release-message-stall-2026-08-08.md).

## Why this exists

The fresh manual session `legacy-20260808T215534Z-51786` established that the
initial language page matched between the visible Steam CDP target and the
Android screenshot. After one real Android A-button event, the CDP target
advanced to `/routes/oobe/1/timezone`, while the Android capture continued to
show the language page for more than twelve seconds. Its rotating welcome text
continued changing, so the output was live but not synchronized with the
current Steam route. AHardwareBuffer present/release markers remained passing.

That result is not enough to identify whether the stale image begins at the
CEF/Xwayland window, in Gamescope's composition, or in the Android
SurfaceControl presentation. The existing Android screenshot is downstream of
all three. The capture helper in this checkpoint provides an upstream sample
at the X11 boundary without changing focus, input, or compositor state.

## Build

The helper is an ARM64 Holo/glibc binary and uses the same X11 package sysroot
as the animated X11 probe:

```sh
./android/nova-lab/build-x11-capture.sh
sha256sum android/nova-lab/build/nova-x11-capture
```

The build is a compile/provenance check only. It does not imply that the helper
has run on the Nova. The selected Gamescope artifact and the capture's run ID
must still be recorded for every device result.

## Capture during a fresh manual run

First follow the lifecycle gate in
[`docs/34-nova-runtime-harness-lifecycle.md`](34-nova-runtime-harness-lifecycle.md),
start a fresh manual session with one explicit profile, and record its run ID.
While that session is live, push the helper into the active rootfs and invoke
it as root. On this Nova build, the Xwayland root drawable rejects `XGetImage`
with `BadMatch`; use the tree to select the mapped Steam window and capture
that window rather than treating a root capture failure as a presentation
failure:

```sh
ADB=/Users/kurt/.local/bin/adb
ROOTFS=/data/local/tmp/nova-holo-rootfs
$ADB push android/nova-lab/build/nova-x11-capture "$ROOTFS/tmp/nova-x11-capture"
$ADB shell su -c "chmod 755 $ROOTFS/tmp/nova-x11-capture"
$ADB shell su -c "mkdir -p $ROOTFS/tmp/nova-x11-capture-run"
$ADB shell su -c \
  "/system/bin/chroot $ROOTFS /usr/bin/env DISPLAY=:0 /tmp/nova-x11-capture \\
   --tree"
```

The tree prints the mapped Steam window as `0xWINDOW_ID` (currently it is
usually `0x240003b`). Capture that drawable and pull the successful artifact:

Use the window ID reported for the visible Steam window to add a targeted
capture in the same invocation:

```sh
$ADB shell su -c \
  "/system/bin/chroot $ROOTFS /usr/bin/env DISPLAY=:0 /tmp/nova-x11-capture \\
   --window-ppm 0xWINDOW_ID /tmp/nova-x11-capture-run/steam.ppm"
$ADB pull "$ROOTFS/tmp/nova-x11-capture-run/steam.ppm" \
  android/nova-lab/build/nova-x11-steam.ppm
```

The helper prints machine-readable `nova_x11_window`, `nova_x11_tree`, and
`nova_x11_capture=pass` records. Capture the output alongside the CDP route,
Android screenshot SHA-256, Gamescope log, and SurfaceFlinger layer snapshot;
do not compare it with an artifact from another run.

## Interpretation order

1. If the visible Steam X11 window already shows the new route while Android
   remains old, the divergence is after the Xwayland client, narrowing the next
   inspection to Gamescope composition or Android buffer/latch identity.
2. If the X11 window remains on the old route while CDP reports the new route,
   the divergence is at the CEF/Xwayland window or its damage/repaint path.
3. If both X11 and Android captures agree, the prior discrepancy was an
   unsynchronized capture timing issue; repeat with a frame identity marker
   before declaring the presentation path repaired.

This checkpoint deliberately does not modify `HeadlessBackend.cpp` or the
AHardwareBuffer ownership algorithm in `ahbbridge.c`; the app-side markers are
diagnostic only. Ownership changes should wait until a fresh, same-run
X11-versus-Android comparison identifies the failing boundary. The 2026-08-08
runs then identified a concrete downstream stall. Run
`legacy-20260808T220739Z-52938` reached the network route in CDP and X11 while
Android remained on the timezone page; Gamescope logged repeated
`Android release message wait failed buffer 1` errors after its frame 180
marker. The fresh instrumented run `legacy-20260808T222115Z-53956` reproduced
the same boundary with buffer 0 after the timezone-to-network transition. A
one-shot `debug_force_repaint` command did not advance the Android layer. The
Android-side wait/ack/release markers now prove that the app stops producing
new frame markers after the release wait fails; the detailed run evidence and
next tracing gate are in
[`docs/39-nova-release-message-stall-2026-08-08.md`](39-nova-release-message-stall-2026-08-08.md).
