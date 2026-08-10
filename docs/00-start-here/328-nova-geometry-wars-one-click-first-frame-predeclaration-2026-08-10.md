# Nova one-click Geometry Wars Proton 11 first-frame Vulkan/WSI predeclaration — 2026-08-10

Status: predeclared; no Geometry Wars device launch has started under this
identity.

## Question

Can the current visible one-click Steam session launch Geometry Wars: Retro
Evolved through the standard Holo glibc/Steam Runtime/Proton 11 ARM64 path
and produce its first game frame? If it cannot, this run must identify the
first Vulkan/WSI boundary from fresh Proton, DXVK, Wine, and Vulkan-loader
evidence.

This is the next game-rendering milestone after the Termux:X11 Steam-window
XI2 selection result in [327](../40-productization/327-nova-one-click-xinput2-steam-window-trace-result-2026-08-10.md).
It does not change the one-click parent profile and does not add the embedded
X11 or full OOBE packaging work.

## Run identity and fixed artifacts

- Run ID:
  nova-game-geometry-wars-one-click-first-frame-20260810T161132Z
- Branch: main
- Baseline source commit: b949f4d5645e748418b42e46b9d25109500f1c15
- Device: Retroid Pocket Nova, Android 13, kalama, adb serial 675a2365
- Rootfs: /data/local/tmp/nova-holo-rootfs
- AppID: 8400, Geometry Wars: Retro Evolved
- Game executable:
  /opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe
- Expected GeometryWars.exe SHA-256:
  457340226810ea529310f17875d87201cc93635e5a375ea4b5fdb75361887129
- Compatibility tool:
  /opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64/proton
- Proton display: Proton 11.0 (ARM64), prefix version expected 11.0-100
- Holo client runtime: steamrtarm64 with the installed SteamRT3C ARM64
  platform tree
- APK: android/nova-lab/build/nova-lab-debug.apk
- Expected current one-click APK SHA-256:
  0d3020eb0ba8d0fa09b168f85ba088ad3cc08932a7ad36c76bad0ab4b69f5d97
- Direct game wrapper:
  android/nova-lab/device/nova-proton-glibc-geometry-wars.sh
- Wrapper SHA-256:
  f4ebb21105a8af5876a2ed11cf06a3b8db2d11ee4d0bd537d63ce5510cf80848
- Parent display: fresh Termux:X11 :0, Android 1280x960, X11 1280x800

The device run must record the actual APK, executable, Proton wrapper,
runtime, and ICD hashes again. The expected values above are pins for the
current host artifacts, not a substitute for same-run provenance.

## Fixed one-click parent profile

Start the APK through the visible Start Steam button with no diagnostic intent
extras. The parent profile is fixed at:

~~~text
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
~~~

The signed-in Steam UI must reach fresh launcher readiness before the game
launch. Its display, audio bridge, controller relay, networking, and CEF
profile are not variables in this experiment.

## Controlled game-launch delta

Only the direct Geometry Wars child changes. Use the existing wrapper in
dxvk mode, which invokes Proton's normal run action rather than runinprefix:

~~~text
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
WINEDEBUG=+loaddll,+seh
~~~

The wrapper also supplies the fixed Holo glibc library path, SteamRT3C
runtime, X11 display, Steam user identity, and existing SysV semaphore shim.
The game process receives no DMA-BUF WSI layer, Gamescope flags, AHB output
socket, or Bionic sidecar. This keeps the first Vulkan/WSI test on the
standard supported glibc/SteamRT/Proton route.

## Procedure

1. Immediately before device launch, read the Nova lifecycle contract in
   [34](34-nova-runtime-harness-lifecycle.md). Stop any prior Nova session,
   run the exact X11 and rootfs cleanup helpers, and verify a fresh process,
   mount, socket, and launcher-state baseline.
2. Verify the persistent AppID-8400 prefix and game files read-only. Snapshot
   the prefix registry, Proton FEX configuration, and existing
   system32/syswow64 D3D and DXGI files.
3. Copy the persistent compatdata into the exact run-scoped
   /tmp/<run-id>/compatdata/8400 path inside the Holo rootfs. Seed the
   run-copy tracked_files bookkeeping with uid 501/gid 20 so Proton's normal
   run action can complete setup. The persistent signed-in prefix is never
   the write target.
4. Start a fresh APK one-click session through the visible button, capture
   the fresh launcher readiness marker, session D-Bus address, Steam client
   log, focus, X11 tree, and authenticated pre-game screenshot.
5. Launch only the verified AppID-8400 process through the existing private
   X11/chroot-dev namespace as uid 501 using the quoted wrapper invocation:

   ~~~text
   nova-proton-glibc-geometry-wars.sh dxvk <run-id> "/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe"
   ~~~

   Retain the exact remote command, wrapper output, exit status, process
   tree, Proton log, DXVK log directory, loader diagnostics, and prefix setup
   files.
6. Capture the display at the prelaunch baseline, during the first 10 seconds
   at short intervals, and through the bounded 60-second Proton wrapper
   lifetime. Record the X11 window tree before and after launch. A changed
   Steam tab, a live Wine process, or a successful wrapper status is not a
   game-frame result.
7. Terminate only the verified AppID-8400 process tree. Restore the prefix
   snapshots byte-for-byte, remove the exact run-scoped compatdata/logs and
   wrapper, stop the parent through the exact one-click path, and verify
   empty matching-process, mount, socket, D-Bus, and app-file audits.

## First-frame acceptance

Accept only a same-run capture that shows Geometry Wars pixels or a fresh
viewable Geometry Wars window, with a matching AppID-8400 Proton/FEX/Wine
process and a changed frame region that is not the Steam UI. Record the first
frame timestamp and screenshot hash. The first game frame is the primary gate;
controller, audio latency, touch handling, networking, and 4:3 game aspect
ratio are observations only and cannot convert a no-frame run into a pass.

## Vulkan/WSI classification

Classify the earliest failing boundary from fresh artifacts:

- Proton/prefix setup: Proton cannot initialize the run-scoped prefix or does
  not generate tracked_files, version, and config_info.
- Pre-Vulkan game startup: GeometryWars.exe reaches FEX/Wine but loads
  WineD3D/OpenGL or exits before WineVulkan/DXVK initialization.
- Vulkan loader/ICD: WineVulkan or DXVK loads, but the loader cannot expose
  the Freedreno device, instance creation fails, or Turnip never initializes.
- Win32-surface WSI: Vulkan device initialization succeeds, but the Wine-facing
  presentation path fails at VK_KHR_win32_surface, vkCreateWin32SurfaceKHR,
  VK_KHR_surface, or an equivalent X11/Win32 surface contract.
- Swapchain/present: a Vulkan surface exists and DXVK initializes, but
  vkCreateSwapchainKHR, image acquisition, present, or the first present
  fails without a game frame.
- Game/runtime after rendering setup: DXVK/WineVulkan and swapchain setup
  succeed, but the game crashes, hangs, or fails before drawing.
- First-frame pass: the same-run Geometry Wars frame is visible and the
  process/log evidence agrees.

Do not call an error a WSI failure merely because a Vulkan variable was
present. The classification requires fresh loader/DXVK/Wine evidence showing
the furthest reached boundary.

## Out of scope and next decision

This declaration does not modify Gamescope, AHardwareBuffer, SurfaceFlinger,
the APK, embedded X11, Bionic runtime experiments, Steam OOBE packaging,
input relays, audio transport, or network routing. The implicit DMA-BUF WSI
layer is intentionally deferred until this clean baseline either produces a
first frame or reaches a reproducible Win32-surface WSI boundary.

Commit and push this declaration before reading the lifecycle contract for
the device run. Do not start that run under this identity until the
predeclaration commit is present on the branch.
