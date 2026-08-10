# Nova glibc Proton DXVK native-setup control — 2026-08-10

## Question

The two correctly initialized WineD3D controls reached Wined3D/softpipe but
did not produce a frame and both faulted in Geometry Wars after startup. This
control returns to the standard Proton Vulkan path using Proton's normal
`run` setup, explicit native DXVK DLL dispatch, and the Holo Turnip ICD. It
does not load the Android WSI layer.

The no-layer boundary is intentional: it first establishes whether the
current glibc Proton/FEX/WineVulkan path can create a Vulkan instance under
the exact private X11 namespace and uid without attributing any result to the
X11/DMA-BUF layer. The prior native-dispatch result reached DXVK and
WineVulkan but failed instance creation; the prior DMA-BUF result reached
Turnip and device creation. Those records are
[`docs/250`](250-nova-geometry-wars-proton11-dxvk-nativeoverride-result-2026-08-10.md)
and
[`docs/293`](293-nova-android-wsi-layer-dmabuf-result-2026-08-10.md).

## Controlled inputs

- Device: Retroid Pocket Nova, adb serial `675a2365`, Android 13, `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Game executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- Compatibility tool:
  `/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64/proton`
- Parent profile: hardware acceleration enabled, CEF GPU disabled, Steam
  `gamepadui`, Steam client software GL forced, CEF environment split enabled
- Parent display: fresh Termux:X11 `:0`, Android `1280x960`, stretched X11
  `1280x800`
- Proton setup: normal `proton run`, fresh run-copy AppID 8400 compatdata,
  empty seeded `tracked_files`, generated `version`/`config_info` required
- Renderer mode: `dxvk`
- `PROTON_USE_WINED3D=0`
- Explicit `WINEDLLOVERRIDES`:
  `d3d11=n;d3d10core=n;d3d9=n;dxgi=n`
- Vulkan ICD:
  `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`
- WSI layer: unset
- Software GL overrides: unset for the game process
- Fresh `PROTON_LOG_DIR` and `DXVK_LOG_PATH`

## Acceptance and evidence

Capture:

1. the exact APK, wrapper, game, Proton, ICD, and parent identities;
2. fresh readiness and D-Bus evidence;
3. the wrapper markers and Proton's `System`/`Effective WINEDLLOVERRIDES`;
4. fresh Proton and DXVK logs, including DXVK version and
   `winevulkan.dll`/instance-extension negotiation;
5. the first Vulkan failure or a Geometry Wars frame; and
6. exact teardown, including orphaned Wine/FEX processes and run staging.

The run must not be classified as a WSI-layer result. If the ICD has no
surface extensions, record that as the expected no-layer baseline and push the
result before the separately predeclared `dxvk-wsi` control using the preserved
DMA-BUF artifact:

- Layer SHA-256:
  `895a6dc9dc63e5778c0171fc56cdcb7e565a0f99c137c137073cb5ce8693b24a`
- Manifest SHA-256:
  `31758fb210e73e1ecd7460c9ec413e8eab6a7281b0ba847cd351af79f17f742a`

This predeclaration is committed and pushed before the device run.
