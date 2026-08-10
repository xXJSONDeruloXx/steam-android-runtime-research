# Nova FROG Gamescope WSI explicit-layer result — 2026-08-10

## Result

Both FROG activation variants completed successfully as native Vulkan
enumeration, and the layer library was loaded. Neither variant added a usable
window-system surface extension:

| Variant | Activation | Vulkan status | Instance extensions | FROG layer extensions |
| --- | --- | ---: | ---: | ---: |
| implicit | `ENABLE_GAMESCOPE_WSI=1` | 0 | 10 | 0 |
| explicit | `ENABLE_GAMESCOPE_WSI=1` plus `VK_INSTANCE_LAYERS=VK_LAYER_FROG_gamescope_wsi_aarch64` | 0 | 10 | 0 |

Both inventories contain `VK_EXT_headless_surface`, but neither contains
`VK_KHR_surface`, `VK_KHR_xcb_surface`, `VK_KHR_xlib_surface`,
`VK_KHR_wayland_surface`, `VK_KHR_android_surface`, or
`VK_KHR_win32_surface`. The explicit variant's loader diagnostics confirm
that it loaded and inserted
`/usr/lib/libVkLayer_FROG_gamescope_wsi_aarch64.so`; its own diagnostics only
report forcing `VK_EXT_swapchain_maintenance1`.

The local Gamescope source adds an important qualification. Its
`VkInstanceOverrides::CreateInstance` enters the bypass path only when
`GAMESCOPE_WAYLAND_DISPLAY` is set and the process is running under that
Gamescope socket. The one-click session used here is direct Termux:X11, and
the probe environment deliberately did not contain that variable. Therefore
this run proves that the manifest and library load, but it does not exercise
FROG's Gamescope surface-bypass path. It is not evidence that FROG is
functionally broken.

It does establish that direct Termux:X11 has no native surface extension to
hand to WineVulkan, and that simply loading the FROG layer in that direct
profile does not change the extension inventory. It therefore cannot, in
that profile, unblock the DXVK log sequence where WineVulkan requests
`VK_KHR_win32_surface` and `DxvkInstance::createInstance` fails. The
existing Gamescope headless vkcube negative control remains consistent with
this result.

The layer binary does contain XCB/Wayland and Gamescope surface/present hooks,
including `vkCreateXcbSurfaceKHR` and `vkCreateWaylandSurfaceKHR`, and its
manifest depends on the `ENABLE_GAMESCOPE_WSI` environment variable. Those
strings establish intended capability, not a successful surface negotiation.
The Vulkan loader's fresh extension inventory is authoritative for this
direct-X11 profile.

## Run identity and evidence

- Run ID: `nova-frog-wsi-explicit-layer-20260810T084535Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- APK SHA-256:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Fresh one-click launcher: hardware acceleration enabled, software GL
  isolation enabled, display `:0`, geometry `1280x960`
- Fresh session: `20260810T084717Z-10846`
- Fresh D-Bus bus:
  `/tmp/nova-steam-runtime/dbus-session-11063/bus`
- FROG library SHA-256:
  `6797355511b1d62d7d324b9f49e0119a48d2b5647489a4f55784cde37f03eb5a`
- All four probes returned `exit_status=0`
- Native GPU: Turnip Adreno (TM) 740, Mesa 25.2.7

The exact commands, environment, complete stdout/stderr, status files,
manifest, binary metadata, screenshots, process polls, and cleanup records are
retained under:

`android/nova-lab/build/runs/nova-frog-wsi-explicit-layer-20260810T084535Z`

## Cleanup

The fresh session was stopped after both variants. The exact X11 cleanup
returned `nova_x11_cleanup=pass`, the runtime cleanup returned
`nova_runtime_cleanup=pass`, no matching Nova/Gamescope/Xwayland/Steam,
Wine/Proton, libei, or uinput process remained, and the rootfs retained only
the two baseline udev sockets. The stale `server-parent.pid` state file was
removed by exact path after teardown.

## Decision

Do not spend another small-game run on the current Proton/DXVK path yet.
The fresh Steam manifest inventory contains only three installed game titles:
198X (AppID `1086010`), Peggle Deluxe (AppID `3480`), and Geometry Wars:
Retro Evolved (AppID `8400`); the other manifests are Proton or Steam
runtime packages. 198X was covered by the earlier Proton 11 run, and the
Geometry Wars/Peggle runs reproduce the shared pre-frame failure. The next
FROG test must be a separate Gamescope-nested run with
`GAMESCOPE_WAYLAND_DISPLAY=gamescope-0`; the current direct Termux:X11 path
cannot exercise that layer mode. Independently, the rendering implementation
must either provide Mesa/Turnip WSI extensions, repair the WineVulkan/WSI
bridge, or use a different forwarding path that gives the Windows client a
real surface. A future game run becomes useful after that boundary changes.
