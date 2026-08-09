# Termux:X11 native ARM64 Steam cleanup-control experiment — 2026-08-09

Status: predeclared experiment; no device launch has run for this profile.

## Purpose

The previous control validated the cleanup/log-capture repair with the
synthetic animator, but the launch command omitted the explicit native Steam
client path. This run corrects only that profile-selection mistake.

## Fixed profile

```text
NOVA_X11_ANIMATE=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/device/nova-termux-x11-steam-client.sh
NOVA_TERMUX_X11_BIND_ANDROID_DEV=1
NOVA_TERMUX_X11_STEAM_UID=501
NOVA_TERMUX_X11_STEAM_GID=20
display=:0
presentation=Termux:X11 Android SurfaceView
```

The Termux:X11 APK, `/dev` bind, private `1777` `/dev/shm` tmpfs, `/proc`
bind, Steam flags, software renderer, network compatibility patch, and
60-second client timeout remain unchanged from the procfs result. The repaired
cleanup helper and wait-before-log-copy ordering are the only code changes.

## Acceptance and interpretation

Use a fresh run ID and record the explicit script hash. Require final
`client_status`, complete Steam stdout/stderr, viewable Steam/webhelper X11
windows, physical Android capture, and automatic cleanup/post-stop/runtime
passes. Compare pixels with the procfs result. No OOBE, login, or QR claim is
allowed unless the physical capture visibly contains that UI.
