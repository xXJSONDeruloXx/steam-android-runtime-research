# Nova Freedreno Vulkan WSI exact-environment result — 2026-08-10

## Result

Native Vulkan enumeration succeeds under the exact private namespace, uid,
library path, ICD, and software-GL environment used for the Proton game
probe. The device is using the expected hardware driver:

```text
Vulkan Instance Version: 1.3.296
deviceName         = Turnip Adreno (TM) 740
driverID           = DRIVER_ID_MESA_TURNIP
driverName         = turnip Mesa driver
driverInfo         = Mesa 25.2.7
```

This is a useful separation from the Geometry Wars failure: the ICD loads and
creates a native Vulkan instance in the same runtime, so the failure is not a
missing driver or a general Vulkan-instance problem.

The native instance exposes ten extensions, including
`VK_EXT_headless_surface`, but it does not expose any window-system surface
extension. In particular, the fresh extension inventory contains no
`VK_KHR_surface`, `VK_KHR_xlib_surface`, `VK_KHR_xcb_surface`,
`VK_KHR_android_surface`, `VK_KHR_win32_surface`, or Wayland surface
extension. The implicit `VK_LAYER_FROG_gamescope_wsi_aarch64` layer is
discoverable, but `vulkaninfo --show-formats` reports zero layer extensions.

That matches the direct DXVK result: DXVK requests `VK_KHR_win32_surface`,
then `DxvkInstance::createInstance` fails. The current blocker is therefore
the WineVulkan/WSI bridge between the 32-bit Proton process and the
Gamescope/FROG presentation path. The Android surface and Gamescope output
path are not disproven; this probe simply shows that the native loader does
not advertise a usable WSI surface extension by itself.

## Evidence

- Run ID: `nova-vulkan-wsi-exact-env-probe-20260810T083725Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- APK SHA-256:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Fresh launcher: hardware acceleration enabled, display `:0`, geometry
  `1280x960`
- Fresh D-Bus bus: `/tmp/nova-steam-runtime/dbus-session-3492/bus`
- UID/GID: Steam uid 501, gid 20, supplementary group 1005
- ICD: `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`
- Driver: `/opt/nova-kgsl-driver/libvulkan_freedreno.so`
- Probe statuses: `summary exit_status=0`, `formats exit_status=0`
- Loader diagnostics selected the Turnip Adreno 740 driver and found the
  FROG Gamescope WSI implicit-layer manifest
- The final cleanup record reports `nova_x11_cleanup=pass`,
  `nova_runtime_cleanup=pass`, absent server/client state, and no remaining
  launcher state files; only the two baseline udev sockets remain in the
  rootfs socket inventory

The exact commands, complete stdout/stderr, status files, screenshots,
process polls, cleanup records, and APK identity are retained in:

`android/nova-lab/build/runs/nova-vulkan-wsi-exact-env-probe-20260810T083725Z`

## Interpretation

The rendering boundary is now:

`Turnip ICD` → `native Vulkan instance` → `no native X11/Win32/Android WSI`
→ `WineVulkan/DXVK surface creation failure`

The earlier Geometry Wars and Peggle Proton 11 runs remain valuable as
cross-title evidence: both start the real Proton wrapper and exit before a
game frame. Geometry Wars additionally proved that explicit native DXVK DLL
dispatch reaches `winevulkan.dll` before the instance failure. Trying more
small games is unlikely to change this shared pre-frame boundary until the
WSI path changes.

## Next controlled experiment

Inspect the installed FROG layer manifest and library, then run one fresh
probe with `VK_INSTANCE_LAYERS=VK_LAYER_FROG_gamescope_wsi_aarch64` explicitly
selected. Compare its extension inventory and a native surface-creation
probe against this exact baseline. If the layer still exposes no usable
surface entry points, stop changing Gamescope/Android presentation flags and
move the next implementation effort to the WineVulkan/WSI bridge or a
different forwarding architecture. Predeclare and push that experiment
before launching it.
