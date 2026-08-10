# Nova FROG Geometry Wars socket-mode corrected result — 2026-08-10

## Result

The `0777` Gamescope/libei socket workaround removed the previous FROG
connection blocker. The real Geometry Wars child reached the FROG/DXVK path:

    [Gamescope WSI] Executable name: GeometryWars.exe
    info:  DXVK: v2.7.1-467-g83e503b4ae6de84
    info:  Found device: Turnip Adreno (TM) 740 (turnip Mesa driver 25.2.7)

The next boundary is now explicit. DXVK rejected the Turnip device because it
does not advertise `VK_KHR_swapchain`, then reported:

    Skipping: Device does not support required feature 'khrSwapchain'
    warn: DXVK: No adapters found. Please check your device filter settings

This run did not create a game surface or frame. The later Android capture
still shows the Steam client UI rather than Geometry Wars. The host wrapper
was terminated after the remote Gamescope child stopped making progress, so a
wrapper exit status is intentionally recorded as not observed; the Proton log
and Gamescope stderr are the authoritative result artifacts.

The FROG socket handshake itself is therefore a pass, but the rendering gate
is still a fail. The remaining blocker is the device-facing Vulkan swapchain
capability (including FROG's attempted `VK_EXT_swapchain_maintenance1` path),
not Steam launch discovery or socket visibility.

## Run identity and artifacts

- Run ID: `nova-frog-geometry-wars-socket-mode-corrected-20260810T093048Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: 8400, Geometry Wars: Retro Evolved
- Executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- Compatibility tool: Proton 11.0 ARM64,
  `compatibilitytools.d/proton-11-arm64`
- APK SHA-256:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Gamescope SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`
- Gamescope source commit:
  `fb9f84ee247a1f02b1a132da60e94585db84bf61`
- FROG layer: `VK_LAYER_FROG_gamescope_wsi_aarch64`
- ICD: `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`
- Probe script SHA-256:
  `cac78b0835a7265bae9961432a3bce9f9206e6bd430c9f8be2801903f4f61a29`
- Nested command: headless Gamescope, output/nested size `1280x960`,
  `XDG_RUNTIME_DIR=/tmp`, FROG explicit instance layer, native DXVK DLLs,
  software GL isolation, socket mode adjustment inside the child wrapper.
- `proton-steam-8400.log` SHA-256:
  `c92c36b4b4665cef9e6929fbeb7b763b575fbd36fff90c1df88b01517d6236b0`
- `nested.stderr` SHA-256:
  `2cafbc7434bbdbb3d2623865bbc91a57be2215ae7bbc0f6fcc809a832be29bd0`
- `nested.stdout` SHA-256:
  `1619903f56f05254d534cdef3a73b870320808649bc159c8b5f57bca9e223eec`
- Prelaunch screenshot SHA-256:
  `c21f19c212d46c406e1c389bd3cefc1c6647d09ef4b41a5238458bbead473058`
- Final `screen-20.png` SHA-256:
  `07d0ff7c413355980568c34c9bbfa8fac548a2ecab3c92ce71c3a021e71eb942`

The complete evidence directory is:

    android/nova-lab/build/runs/nova-frog-geometry-wars-socket-mode-corrected-20260810T093048Z/

## Prefix and cleanup integrity

The run backed up the AppID-8400 registry files, Proton FEX configuration,
and ten existing system32/syswow64 D3D/DXGI DLLs. `restore-cmp.txt` reports
`pass` for every item. The registry files changed during launch, while the
native D3D/DXGI DLL hashes and Proton FEX configuration remained unchanged;
the original registry state was restored before teardown completed.

The exact cleanup helpers returned `nova_x11_cleanup=pass` and
`nova_runtime_cleanup=pass`, with no matching Nova process, app-owned runtime
file, disposable probe, or Nova-specific mount remaining. The final rootfs
`/tmp` socket inventory is empty, and only the two baseline `/run/udev`
sockets remain. Cleanup also found stale Steam `SingletonSocket` directories
and `steam_chrome_shmem_uid501_spid*` entries produced during the run; after
process cleanup verified no Steam descendants remained, those exact temporary
entries were removed and the final inventory was rechecked.

The runtime cleanup helper emitted toybox `awk` warnings while formatting the
newline-separated PID snapshot passed through `awk -v`, despite returning a
pass marker. This is a harness observability bug to repair before treating a
warning-free teardown as an acceptance requirement.

## Next experiment

Do not try another game with the same native DXVK/FROG profile yet: 198X,
Peggle Deluxe, and Geometry Wars now share a pre-frame rendering boundary.
First capture a same-environment Vulkan physical-device extension inventory
and isolate whether `VK_KHR_swapchain` is absent from the Freedreno ICD itself
or lost/hidden by FROG's device-layer path. Then test the smallest reversible
repair: a surface-creating probe with the device's actual extension set. If
the driver cannot create a swapchain, return to the working Steam UI path for
input/audio/application work while keeping the FROG experiment as a bounded
rendering branch.
