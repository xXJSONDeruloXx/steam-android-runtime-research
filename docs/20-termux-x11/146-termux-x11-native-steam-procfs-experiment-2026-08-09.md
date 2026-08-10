# Termux:X11 native ARM64 Steam procfs experiment — 2026-08-09

Status: completed; see the [device result](147-termux-x11-native-steam-procfs-result-2026-08-09.md).

## Why this is next

The previous [bind + shared-memory result](145-termux-x11-native-steam-dev-shm-result-2026-08-09.md)
cleared the `/dev` and semaphore boundaries. Steam then exited with:

```text
src/steamexe/main.cpp (1330) : Plat_GetExecutablePath returned false
```

The rootfs `/proc` is an empty directory, while Android's `/proc` is a live
procfs. The existing Holo runtime setup binds `/proc` into the rootfs.

## One-variable change

The private `chroot-dev` namespace will now mount, in order:

```text
Android /dev       -> rootfs /dev
tmpfs mode=1777    -> rootfs /dev/shm
Android /proc      -> rootfs /proc
```

All three mounts remain private to the client namespace and are unmounted in
reverse order after the launcher exits. Steam remains uid 501:20 with the
same flags, renderer, Termux:X11 APK, timeout, and X11 window gate. The host
harness still clears and pulls fresh Steam log paths.

## Acceptance and interpretation

The target is fresh Steam stderr past `Plat_GetExecutablePath`, followed by a
viewable X11 child and an Android screenshot. If procfs bind fails, record the
mount capability boundary. If procfs passes but Steam reaches another clean
loader/runtime boundary, document and push that result before changing
anything else.

No Gamescope, AHardwareBuffer, SurfaceControl, input, OOBE, login, or QR
variable is included.
