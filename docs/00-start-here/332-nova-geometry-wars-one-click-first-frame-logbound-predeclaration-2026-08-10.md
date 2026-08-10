# Nova one-click Geometry Wars bounded-log control — fresh predeclaration — 2026-08-10

Status: predeclared; no device launch has started under this identity.

## Question

Does the current one-click glibc/Holo rendering path reach a first Geometry
Wars frame and the known DXVK/WineVulkan boundary when the game-side trace is
bounded to `WINEDEBUG=+loaddll`, without changing the parent display or Android
presentation path?

The preceding identity was invalidated before Nova launch by device ENOSPC.
Its deleted Proton log was held open by five orphaned Wine processes; those
processes have been terminated and the device now has stable free space. See
[331](331-nova-geometry-wars-one-click-first-frame-logbound-preflight-enospc-result-2026-08-10.md).

## Run identity and provenance pins

- Run ID:
  `nova-game-geometry-wars-one-click-first-frame-logbound-20260810T170605Z`
- Branch: `main`
- Baseline source commit:
  `78722b0`
- Device: Retroid Pocket Nova, Android 13, `kalama`, adb serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Game executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- Expected GeometryWars.exe SHA-256:
  `457340226810ea529310f17875d87201cc93635e5a375ea4b5fdb75361887129`
- Proton tool:
  `/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64/proton`
- Expected APK: `android/nova-lab/build/nova-lab-debug.apk`
- Expected APK SHA-256:
  `0d3020eb0ba8d0fa09b168f85ba088ad3cc08932a7ad36c76bad0ab4b69f5d97`
- Host wrapper:
  `android/nova-lab/device/nova-proton-glibc-geometry-wars.sh`
- Expected host wrapper SHA-256:
  `f4ebb21105a8af5876a2ed11cf06a3b8db2d11ee4d0bd537d63ce5510cf80848`
- Parent display: fresh Termux:X11 `:0`, Android `1280x960`, X11 `1280x800`

Actual device hashes, runtime provenance, fresh launcher session ID, and
storage/inode baseline must be captured again during this run.

## Fixed one-click parent

Start the APK through the visible `Start Steam` button with no diagnostic
intent extras. Keep this parent profile fixed:

```text
audio_bridge=1
hardware_accel=1
cef_disable_gpu=1
steam_ui_mode=gamepadui
steam_disable_preload=0
steam_disable_system_dbus=0
steam_holo_mesa_first=0
steam_force_software_gl=1
steam_cef_env_split=1
controller_relay=enabled
```

The fresh authenticated Steam session must reach launcher readiness before the
game child is started. Display, networking, audio, controller relay, CEF, and
Steam client variables remain fixed observations, not experiment variables.

## Sole game-launch delta

Use the same run-scoped prefix copy, Proton normal `run` action, wrapper mode,
DXVK selection, explicit Turnip ICD, disabled WSI layer, and quoted executable
path as [330](330-nova-geometry-wars-one-click-first-frame-logbound-predeclaration-2026-08-10.md).

The only changed game-side diagnostic variable is:

```text
WINEDEBUG=+loaddll
```

The game variables otherwise remain:

```text
mode=dxvk
SteamAppId=8400
SteamGameId=8400
STEAM_COMPAT_CLIENT_INSTALL_PATH=/opt/nova-steam/home/.local/share/Steam
STEAM_COMPAT_DATA_PATH=/tmp/<run-id>/compatdata/8400
PROTON_USE_WINED3D=0
WINEDLLOVERRIDES=d3d11=n;d3d10core=n;d3d9=n;dxgi=n
VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
VK_IMPLICIT_LAYER_PATH=unset
MESA_LOADER_DRIVER_OVERRIDE=unset
GALLIUM_DRIVER=unset
LIBGL_ALWAYS_SOFTWARE=unset
PROTON_LOG=1
PROTON_LOG_DIR=/tmp/<run-id>/proton-log
DXVK_LOG_LEVEL=info
DXVK_LOG_PATH=/tmp/<run-id>/dxvk-log
VK_LOADER_DEBUG=error,warn,driver
```

Launch the child only through:

```text
nova-proton-glibc-geometry-wars.sh dxvk <run-id> "/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe"
```

No DMA-BUF WSI layer, Gamescope flag, AHardwareBuffer output socket, Bionic
sidecar, embedded X11, or persistent-prefix write is allowed.

## Bounded procedure and storage guard

1. Immediately before device activity, read [34](34-nova-runtime-harness-lifecycle.md)
   in full. Run the exact cleanup helper and capture a fresh process, mount,
   socket, storage-byte, and storage-inode baseline. Require at least 8 GB and
   1,000,000 free inodes before launch.
2. Capture same-run APK, game, Proton, ICD, runtime, wrapper, and parent hashes.
   Snapshot the persistent AppID-8400 prefix read-only.
3. Copy only compatdata into the exact run-scoped rootfs `/tmp/<run-id>/` path
   and initialize the run copy through Proton's normal setup.
4. Start the visible one-click session and record fresh readiness, focus, X11,
   D-Bus, and authenticated pre-game screenshot evidence.
5. Launch only Geometry Wars through the private X11/chroot-dev namespace as
   uid 501/gid 20. Capture command, output, status, process polls, bounded
   Proton excerpts, loader excerpts, DXVK directory contents, and screenshots.
6. Poll for a first game frame for at most 60 seconds. Never pull the full
   Proton log. If the run-scoped log exceeds 256 MB, stop growth, preserve only
   selected excerpts, and tear down immediately.
7. Terminate only observed AppID-8400 remnants, stop the parent through the
   exact one-click path, verify targeted cleanup, and remove only this run's
   exact staging tree and helpers. Recheck both bytes and inodes after `sync`
   and scan for deleted-open descriptors before declaring cleanup complete.

## Acceptance and classification

Accept only a same-run visible Geometry Wars frame with a matching AppID-8400
process/log boundary. A changed Steam screenshot, 1x1 Wine window, successful
Proton wrapper, or Turnip ICD selection is not a first frame.

Classify the furthest fresh boundary as one of prefix/Proton setup,
pre-Vulkan FEX/Wine startup, Vulkan loader/ICD or instance creation,
DXVK/WineVulkan initialization, Win32-surface WSI, swapchain/present,
post-rendering game runtime, or first-frame pass. Do not call it a WSI failure
unless the bounded evidence proves WineVulkan/DXVK reached the surface
contract. Compare only with the deeper explicit native-override result in
[250](../30-runtime-and-games/250-nova-geometry-wars-proton11-dxvk-nativeoverride-result-2026-08-10.md).

This predeclaration is committed and pushed before the device run.
