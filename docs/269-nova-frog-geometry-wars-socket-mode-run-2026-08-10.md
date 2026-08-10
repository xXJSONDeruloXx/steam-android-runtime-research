# Nova FROG Geometry Wars socket-mode run — 2026-08-10

## Question

The socket-mode experiment let FROG complete its Gamescope handshake, but it
did not create a surface. This fresh bounded run launches Geometry Wars:
Retro Evolved (AppID 8400) as the Gamescope child under the same reversible
`0777` socket workaround. It retains the prior explicit Proton 11 ARM64
native DXVK dispatch (`WINEDLLOVERRIDES` for d3d9/d3d11/d3d10core/dxgi), the
Freedreno ICD, and run-scoped Proton logging.

The acceptance question is whether FROG logs surface creation and the game
gets beyond the previous pre-frame `DxvkInstance::createInstance`/WineD3D
boundary. A process launch without FROG surface evidence or a changed game
frame remains a startup result only.

## Run identity and fixed artifacts

- Run ID: nova-frog-geometry-wars-socket-mode-20260810T092836Z
- Device: Retroid Pocket Nova, serial 675a2365
- Rootfs: /data/local/tmp/nova-holo-rootfs
- AppID: 8400, Geometry Wars: Retro Evolved
- Executable:
  /opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe
- Compatibility tool: Proton 11.0 (ARM64),
  compatibilitytools.d/proton-11-arm64
- Gamescope: /opt/nova-kgsl-driver/gamescope-headless
- Gamescope SHA-256:
  cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca
- Gamescope source commit: fb9f84ee247a1f02b1a132da60e94585db84bf61
- APK SHA-256:
  3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a
- FROG layer: VK_LAYER_FROG_gamescope_wsi_aarch64
- ICD: /opt/nova-kgsl-driver/freedreno-kgsl.icd.json
- Probe script: android/nova-lab/device/nova-frog-geometry-wars-probe.sh
- Headless output/nested size: 1280x960
- Runtime directory: XDG_RUNTIME_DIR=/tmp
- Socket workaround: chmod Gamescope and libei sockets to 0777 in the
  disposable child wrapper, with before/after modes recorded

The one-click Steam/X11 session is started fresh only to provide the current
rootfs, display, and D-Bus session. Gamescope then owns the child display
(`DISPLAY=:1`), while the game runs as uid 501. The AppID-8400 prefix files
are hashed before launch and restored byte-for-byte if Proton changes them.

## Lifecycle and acceptance

Read the Nova lifecycle contract immediately before launch. Force-stop the APK
and Termux:X11, run exact preflight cleanup, establish fresh process,
mount/socket, and launcher-state baselines, install the tracked probe script,
and launch only this run. Capture the complete Gamescope, FROG, Proton, and
DXVK logs, process polls, prefix hashes, and same-run screenshots.

After capture, restore the captured AppID-8400 registry/config/D3D-DXGI files,
remove the staged probe and run-scoped Proton log directory, force-stop the
APK and Termux:X11, run both exact cleanup helpers, and verify no matching
Gamescope, gamescopereaper, Xwayland, Steam, Wine/Proton, libei, or uinput
process remains. Retain only the two baseline rootfs udev sockets. This
declaration is committed and pushed before the device run.

## Preflight correction before device invocation

The first preflight attempt did not launch the Activity or Gamescope. Its
backup command initially addressed the AppID-8400 registry files at
`compatdata/8400/{system.reg,user.reg,userdef.reg}`; the live prefix stores
them under `compatdata/8400/pfx/`. The copy commands therefore reported
`No such file or directory`, and the attempt was stopped before any device
session started. The temporary backup and staged probe were removed. A fresh
run identity uses the corrected `pfx` paths and will not reuse this attempt.
