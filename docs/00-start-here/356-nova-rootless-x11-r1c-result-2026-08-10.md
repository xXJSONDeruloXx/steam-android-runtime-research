# Nova rootless X11 R1c result — 2026-08-10

Status: pass for the rootless X11 protocol/window boundary; Android activity
presentation and Steam UI remain untested.

## Run identity

- Device: Retroid Pocket Nova, serial `675a2365`.
- Termux X server: display `:77`, process owned by Termux UID `u0_a129`.
- Nova client: app UID `u0_a128` / numeric UID `10128`.
- Holo rootfs: `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs`.
- PRoot and app-owned state: fresh `r1c-20260810T` staging, removed after the run.
- Rooted signed-in Steam session: left running and untouched.

## Evidence

The Termux-side server accepted a connection on `127.0.0.1:6077`. Through the
rootless supervisor, the Nova UID ran the Holo-linked Xlib animation client and
capture client with `DISPLAY=127.0.0.1:77`:

```text
nova_rootless_preflight=pass uid=10128 ...
nova_rootless_exec=proot display=127.0.0.1:77
nova_x11_display=pass display=127.0.0.1:77 screen=0 root=0x511
nova_x11_window id=0x200001 ... map_state=viewable ... width=960 height=540
nova_x11_tree=pass root=0x511
nova_x11_capture=pass id=0x511 path=/home/nova/rootless-x11-root.ppm width=1280 height=1024
nova_x11_pointer_probe=pass seconds=1 samples=20
nova_x11_frames=300
```

The captured root image is 1280×1024, SHA-256
`db5b5514a41af3ff9838a13cefaf25ad613735826fd984ed715f3442e841fad3` in the
ignored build evidence directory. This is a real X11 protocol/window result,
not merely an open TCP port.

The exact `:77` process, app-private state, temporary PRoot/client staging,
and device PPM copy were removed after capture. The rooted `:0` session remains
separate.

## Boundary and limitation

This proves that a rootless Nova app UID can use the official Holo glibc
userspace and PRoot to reach a Termux:X11 server owned by the separate Termux
app over loopback TCP. It does not yet prove that Nova can start that server
through `RUN_COMMAND`, show the corresponding Android X11 activity, or render
Steam. The server was launched with `-ac` for this first private-data-directory
bridge; an authenticated loopback bridge is required before productizing it.

The transport probe is being extended to report the loopback endpoint as a
separate transport result. The next fresh run should exercise that probe, then
the same contract can carry a clean native Steam OOBE test without copying the
rooted Steam home.
