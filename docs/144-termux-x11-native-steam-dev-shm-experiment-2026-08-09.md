# Termux:X11 native ARM64 Steam `/dev/shm` experiment — 2026-08-09

Status: completed; the device result is recorded in
`docs/145-termux-x11-native-steam-dev-shm-result-2026-08-09.md`.

## Why this is next

The previous [native bind result](143-termux-x11-native-steam-dev-bind-result-2026-08-09.md)
proved that Steam reaches `client_started=pass` once Android `/dev` is bound,
but it then repeats semaphore and thread-synchronization failures. The
existing Holo glibc harness mounts a writable `tmpfs` at rootfs `/dev/shm`; the
direct Termux:X11 client namespace did not.

## One-variable change

The `chroot-dev` private namespace will now, in order:

1. make `/` private;
2. bind Android `/dev` over rootfs `/dev`;
3. mount `tmpfs` at rootfs `/dev/shm` with mode `1777`;
4. run the unchanged uid-501 Steam launcher; and
5. unmount `/dev/shm` and `/dev` after the client tree exits.

The harness also clears the fixed rootfs Steam log paths before launch and
pulls them into the run directory before teardown, preserving fresh child
stderr even when the bounded window gate stops the session.

Everything else remains fixed:

```text
NOVA_TERMUX_X11_BIND_ANDROID_DEV=1
uid_gid=501:20
display=:0
steam_flags=-gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox
steam_renderer=swrast + softpipe + LIBGL_ALWAYS_SOFTWARE=1
steam_timeout=60s
x11_window_wait_seconds=25
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

## Acceptance and interpretation

The first new acceptance boundary is fresh Steam stderr without the repeated
`semaphore creation failed`/`Thread synchronization object is unuseable`
sequence. A viewable Steam X11 child and visually accepted Android screenshot
remain required for a rendering milestone.

If semaphore initialization passes but Steam stops at another loader, CEF, or
SteamUI boundary, document and push that result before changing another
variable. No input, OOBE, login, QR, Gamescope, AHardwareBuffer, or
SurfaceControl change is included here.
