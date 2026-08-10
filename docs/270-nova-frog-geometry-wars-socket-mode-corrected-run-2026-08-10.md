# Nova FROG Geometry Wars socket-mode corrected run — 2026-08-10

## Question

This fresh identity retries the FROG Geometry Wars run after correcting the
preflight backup paths. The AppID-8400 registry files are under
`compatdata/8400/pfx/`; `proton-fex-config.json` remains directly under the
compatdata directory. The Gamescope child will apply the reversible `0777`
socket workaround, then run Geometry Wars through Proton 11 ARM64 with the
explicit native DXVK overrides and the Freedreno ICD.

The acceptance question is whether FROG logs a real surface creation and the
game gets beyond the previous pre-frame `DxvkInstance::createInstance`/
WineD3D boundary. A process launch without FROG surface evidence or a changed
game frame is a startup result only.

## Run identity and fixed artifacts

- Run ID: nova-frog-geometry-wars-socket-mode-corrected-20260810T093048Z
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

Prefix preservation covers:

- `compatdata/8400/pfx/system.reg`;
- `compatdata/8400/pfx/user.reg`;
- `compatdata/8400/pfx/userdef.reg`;
- `compatdata/8400/proton-fex-config.json`; and
- the ten existing system32/syswow64 D3D/DXGI files.

## Lifecycle and acceptance

Read the Nova lifecycle contract immediately before launch. Force-stop the APK
and Termux:X11, run exact preflight cleanup, establish fresh process,
mount/socket, and launcher-state baselines, install the tracked probe script,
copy the corrected prefix backup, and launch only this run. Capture complete
Gamescope, FROG, Proton, and DXVK logs, process polls, prefix hashes, and
same-run screenshots.

After capture, restore the captured files byte-for-byte, remove the staged
probe, backup, and run-scoped Proton log directory, force-stop the APK and
Termux:X11, run both exact cleanup helpers, and verify no matching Gamescope,
gamescopereaper, Xwayland, Steam, Wine/Proton, libei, or uinput process
remains. Retain only the two baseline rootfs udev sockets. This declaration
is committed and pushed before the device run.
