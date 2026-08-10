# Termux:X11 native ARM64 Steam `/dev` bind experiment — 2026-08-09

Status: predeclared profile hit a harness preflight failure; the result is
recorded in `docs/20-termux-x11/141-termux-x11-native-steam-dev-bind-preflight-result-2026-08-09.md`.

## Why this is next

The preceding [bind probe result](139-termux-x11-rootfs-dev-bind-probe-result-2026-08-09.md)
validated uid-501 access to Android's real `/dev` inside an unshared mount
namespace. The next question is whether native Steam can use that same mount
while its full process tree runs in the rootfs.

## One-variable change

The direct Termux:X11 harness gains an opt-in `chroot-dev` client namespace:

```text
NOVA_TERMUX_X11_BIND_ANDROID_DEV=1
uid_gid=501:20
client_namespace_mode=chroot-dev
```

The private helper marks `/` private, bind-mounts Android `/dev` over the
rootfs `/dev`, runs the existing client launcher, waits for its entire Steam
tree, and unmounts before leaving. Fake character-device provisioning is
skipped for this profile; the bound Android nodes are the only `/dev` source.

Everything else remains fixed:

```text
display=:0
presentation=Termux:X11 Android SurfaceView
steam_flags=-gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox
steam_renderer=swrast + softpipe + LIBGL_ALWAYS_SOFTWARE=1
steam_timeout=60s
x11_window_wait_seconds=25
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

The run records the private namespace helper hash, mount-private helper hash,
fresh Steam log/stdout/stderr, X11 tree, Android screenshot if a child appears,
and exact cleanup markers.

## Acceptance and interpretation

- A `chroot-dev` bind marker plus a fresh Steam process past the urandom/stdio
  boundary confirms the device namespace repair.
- A viewable Steam X11 child and visually accepted Android screenshot are
  required before claiming a rendering milestone.
- If Steam reaches a new loader, CEF, or SteamUI boundary, stop there and
  document it before changing another variable.
- No Gamescope, AHardwareBuffer, SurfaceControl, input, OOBE, login, or QR
  variable is introduced by this run.
