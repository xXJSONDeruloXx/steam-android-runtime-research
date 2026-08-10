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

This closes the “FROG is installed but inactive” hypothesis. The layer is
active, but it does not provide the missing instance-level WSI surface path in
this native probe. It therefore cannot, by itself, unblock the DXVK log
sequence where WineVulkan requests `VK_KHR_win32_surface` and
`DxvkInstance::createInstance` fails. The existing Gamescope headless vkcube
negative control remains consistent with this result.

The layer binary does contain XCB/Wayland and Gamescope surface/present hooks,
including `vkCreateXcbSurfaceKHR` and `vkCreateWaylandSurfaceKHR`, and its
manifest depends on the `ENABLE_GAMESCOPE_WSI` environment variable. Those
strings establish intended capability, not a successful surface negotiation;
the Vulkan loader's fresh extension inventory is the authoritative result here.

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
Geometry Wars and Peggle already reproduce the shared pre-frame failure, and
the FROG layer is now proven active without supplying a usable WSI surface.
The next rendering implementation must either repair the WineVulkan/WSI
bridge or use a different forwarding path that gives the Windows client a
real surface. A future game run becomes useful after that boundary changes.
