# Nova Peggle Deluxe Steam-applaunch Proton 11 run — 2026-08-10

## Scope

Geometry Wars has now been proven to reach Steam's Proton 11 ARM64 wrapper but
exits before a frame. Peggle Deluxe (AppID `3480`) is the next small-game
control. Its earlier direct Proton 11 and unforced Steam Experimental runs
also produced no frame, but Steam has not yet been tested with an explicit
AppID-3480 mapping to the local `proton11_arm64` wrapper.

This run keeps the known-good hardware-backed Termux:X11/software-GL Steam
session and changes only the temporary Steam compatibility mapping:

```text
3480 -> proton11_arm64
```

The existing AppID-1086010 (198X) Proton 11 mapping remains unchanged. The
temporary AppID-3480 mapping and all other Steam configuration are restored
byte-for-byte after the run.

## Run identity and fixed profile

- Run ID: `steam-game-peggle-proton11-20260810T073154Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `3480`, Peggle Deluxe
- Executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Peggle Deluxe/Peggle.exe`
- Compatibility tool: Proton 11.0 (ARM64), local wrapper
  `compatibilitytools.d/proton-11-arm64`
- APK:
  `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Presentation: hardware-backed Termux:X11, 1280×960
- Steam client: software GL (`swrast`, `softpipe`,
  `LIBGL_ALWAYS_SOFTWARE=1`), explicit Freedreno ICD
- Steam UI mode: minimal

## Procedure and acceptance

Before launch, read the Nova lifecycle contract, force-stop the APK and
Termux:X11, run the exact X11/rootfs cleanup helpers, verify no matching
process, mount, socket, or stale launcher state, and pull/hash the original
`config.vdf`. Insert the single AppID-3480 mapping, start a fresh one-click
session, and capture a same-run Steam baseline.

Issue `steam -applaunch 3480` through the live private X11/chroot namespace.
Retain the exact command, status, fresh compatibility/game-process logs, a
250-ms five-second process poll, and repeated 1280×960 screenshots.

Success requires both a Steam tracked command selecting `proton11_arm64` and a
fresh Peggle frame. A wrapper/process start without a changed game frame is a
startup-boundary result only. After capture, terminate only the verified AppID
3480 tree, restore `config.vdf` byte-for-byte, remove exact stale generated
Steam sockets if needed, and verify clean process/mount/socket state.

This declaration is committed and pushed before changing the device mapping or
launching Peggle.

