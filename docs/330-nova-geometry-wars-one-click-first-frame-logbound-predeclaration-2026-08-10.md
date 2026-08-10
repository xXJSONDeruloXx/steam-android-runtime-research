# Nova one-click Geometry Wars bounded-log first-frame predeclaration — 2026-08-10

Status: predeclared; no device launch has started under this identity.

## Question

Did the previous Geometry Wars no-frame result stop before the known
DXVK/WineVulkan boundary because `WINEDEBUG=+loaddll,+seh` amplified an
exception loop, or does the game still fail before Vulkan presentation when
the same one-click rendering path is observed with bounded logging?

The preceding run reached the native game executable and Turnip ICD selection,
but its 31 GB Proton trace was dominated by repeated FEX/Wine `c0000005`
faults and contained no selected WineVulkan/surface evidence. This control
keeps the full parent and rendering setup unchanged and removes only `+seh`
from the game-side diagnostic variable. It does not modify Gamescope,
AHardwareBuffer, the APK, embedded X11, or the persistent prefix.

## Run identity and fixed artifacts

- Run ID:
  `nova-game-geometry-wars-one-click-first-frame-logbound-20260810T164455Z`
- Branch: `main`
- Baseline source commit:
  `2744f2583ac5c648d45189038e43dde52006d351`
- Device: Retroid Pocket Nova, Android 13, `kalama`, adb serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Game executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- Expected GeometryWars.exe SHA-256:
  `457340226810ea529310f17875d87201cc93635e5a375ea4b5fdb75361887129`
- Proton tool:
  `/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64/proton`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `0d3020eb0ba8d0fa09b168f85ba088ad3cc08932a7ad36c76bad0ab4b69f5d97`
- Host wrapper:
  `android/nova-lab/device/nova-proton-glibc-geometry-wars.sh`
- Host wrapper SHA-256:
  `f4ebb21105a8af5876a2ed11cf06a3b8db2d11ee4d0bd537d63ce5510cf80848`
- Parent display: fresh Termux:X11 `:0`, Android `1280x960`, X11 `1280x800`

The actual device game, Proton, ICD, launcher, and runtime hashes must be
captured again during this run. The expected values above are pins, not
substitutes for same-run provenance.

## Fixed one-click parent profile

Start the APK through the visible `Start Steam` button with no diagnostic
intent extras. The parent profile is fixed at:

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

The fresh authenticated Steam session must reach launcher readiness before
the game child is started. Display, networking, audio bridge, controller
relay, CEF, and Steam client variables are observations or fixed controls,
not variables in this experiment.

## Sole controlled delta

The direct AppID-8400 child must use the same run-scoped prefix copy, Proton
normal `run` action, wrapper mode, DXVK selection, explicit ICD, and disabled
WSI layer as [328](328-nova-geometry-wars-one-click-first-frame-predeclaration-2026-08-10.md).
The only changed game-launch variable is:

```text
# previous run
WINEDEBUG=+loaddll,+seh

# this run
WINEDEBUG=+loaddll
```

All other game variables remain:

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

The game wrapper must receive the quoted path:

```text
nova-proton-glibc-geometry-wars.sh dxvk <run-id> "/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe"
```

No DMA-BUF WSI layer, Gamescope flag, AHardwareBuffer output socket, Bionic
sidecar, or persistent-prefix write is allowed.

## Procedure and storage bound

1. Immediately before device launch, read the Nova lifecycle contract in
   [34](34-nova-runtime-harness-lifecycle.md) in full. Run exact cleanup,
   verify the attached-device baseline, and reject any stale readiness marker
   from a prior launcher session.
2. Record the actual APK, game, Proton, ICD, runtime, wrapper, and parent
   artifact hashes. Snapshot the persistent AppID-8400 prefix read-only.
3. Copy compatdata into the exact run-scoped rootfs `/tmp/<run-id>/` path and
   seed only the run copy for Proton's normal prefix setup.
4. Start the visible one-click Steam session and record fresh readiness,
   D-Bus, focus, X11 tree, and authenticated pre-game screenshot evidence.
5. Launch only Geometry Wars through the private X11/chroot-dev namespace as
   uid 501/gid 20. Capture the exact command, output, status, process polls,
   loader excerpts, Proton log excerpts, DXVK log directory, and screenshots.
6. Poll for the first game frame for at most 60 seconds. Do not read or pull
   the full Proton log. Use bounded excerpts and record its final byte size;
   if it exceeds 256 MB, stop further growth and preserve only selected
   evidence before teardown.
7. Terminate only the observed AppID-8400 process remnants. Stop the parent
   through the exact one-click path, verify cleanup markers and final targeted
   process/socket/mount/D-Bus/app-file state, and remove only this run's exact
   device staging tree and temporary helpers.

## Acceptance and classification

Accept only a same-run visible Geometry Wars frame with a matching AppID-8400
process/log boundary. A changed Steam screenshot, a 1x1 Wine window, or a
successful Proton wrapper start is not a first frame.

Classify the furthest fresh boundary as one of:

- prefix/Proton setup;
- pre-Vulkan game/FEX/Wine startup;
- Vulkan loader/ICD selection or instance creation;
- DXVK/WineVulkan initialization;
- Win32-surface WSI;
- swapchain/present;
- game/runtime after rendering setup; or
- first-frame pass.

In particular, do not call this a WSI failure unless the bounded evidence
proves that WineVulkan/DXVK reached the surface contract. Compare against the
deeper explicit native-override evidence in [250](250-nova-geometry-wars-proton11-dxvk-nativeoverride-result-2026-08-10.md).

Commit and push this predeclaration before reading the lifecycle contract for
the device run. The result must be documented and pushed before any next
experiment begins.
