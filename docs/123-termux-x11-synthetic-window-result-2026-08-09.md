# Termux:X11 synthetic window result — 2026-08-09

Status: partial display result. The dedicated root-side launcher successfully
entered the chroot and mapped the synthetic X11 window. The first pixel-capture
gate then failed with `XGetImage`/`BadMatch` error 8, and the automatic cleanup
helper did not finish within the bounded wait. No Steam process was launched.

## Run identity

```text
run_id=termux-x11-20260809T152500Z-dedicated-launcher-display-0
repo_commit=1f272c7252cf532f7fa86320276e0bb81333c1da
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
display=:0
termux_x11_source_commit=d8013ac5d174bb16120f915c10a7255948c59c17
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
x11_animate_sha256=884853cdc47c0d10a644153404fcd25e155b8784e24903f3ced568649b10bc04
x11_capture_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

Artifacts are under
`android/nova-lab/build/manual-runs/termux-x11-20260809T152500Z-dedicated-launcher-display-0/`.

## Accepted boundary

The server gate passed, the dedicated `su` launcher produced no client
`unshare` error, and the fresh X11 tree contained the named mapped window:

```text
nova_x11_display=pass display=:0 screen=0 root=0x511
nova_x11_window id=0x511 parent=0x0 depth=0 map_state=viewable x=0 y=0 width=1280 height=714 border=0 name="<none>" res_name="<none>" res_class="<none>"
nova_x11_window id=0x200001 parent=0x511 depth=1 map_state=viewable x=0 y=0 width=1280 height=720 border=0 name="Nova animated Xwayland Gamescope probe" res_name="<none>" res_class="<none>"
nova_x11_tree=pass root=0x511
```

Termux:X11 logs also recorded the external client connection and shared
buffers, including a 1280x714 buffer sent back to the Android Activity. This
is the first accepted evidence that a Linux client from the Nova chroot can
create and map a real window through the Termux:X11 server.

## Capture boundary failure

The window capture helper failed on the mapped window:

```text
termux_x11_window=pass id=0x200001
nova_x11_capture=failed id=0x200001 reason=xgetimage error_code=8 depth=24 visual=0x21
```

The script therefore did not produce `x11-window.ppm` or
`android-screenshot.png`; this is not yet a pixel-level or physical-screen
acceptance. The likely protocol boundary is the server's handling of the
X11 `GetImage` request for this Xwayland window, but that is a hypothesis, not
yet a source-level conclusion. The next experiment must compare a root
capture, an XCB/X11 `GetImage` path, and any supported shared-memory capture
without launching Steam.

## Teardown finding

After the capture failure, the exact cleanup command remained in
`pipe_read` for more than two minutes while scanning `/proc`; its device
process was the run-scoped cleanup helper. The server/socket were not treated
as clean evidence while that helper was stuck. I terminated only the exact
cleanup helper, removed the exact run socket and lock through the private
namespace helper, removed the exact state directory, and rechecked that no
Termux:X11/`CmdEntryPoint` process or `X0` socket remained.

This is a harness timeout finding, not a claim that the process tree leaked:
the final independent check was clean. The next repair should replace the
unbounded per-`/proc` shell scan with a bounded process probe and should keep
the cleanup failure visible rather than allowing it to block the experiment
handoff.

## Next gate

The X11 display/client boundary is now strong enough to justify a focused
capture experiment, but not Steam yet. First make X11/Android pixel capture
work and make teardown bounded. Only then predeclare native ARM64 Steam over
direct Termux:X11.

The focused physical-screen capture follow-up is predeclared in
[doc 124](124-termux-x11-android-screen-capture-experiment-2026-08-09.md).
