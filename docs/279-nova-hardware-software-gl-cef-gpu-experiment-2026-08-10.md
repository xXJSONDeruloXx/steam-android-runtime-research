# Nova hardware display / software Steam GL / CEF-GPU split — 2026-08-10

## Question

The Nova Termux:X11 Android surface is hardware-backed, but the direct
Steam ARM64 client crashes in Mesa's hardware GLX path before `steamwebhelper`
creates a stable frame. The known-good control forces Steam GL and CEF GPU
off, which proves presentation but does not satisfy the hardware-rendering
requirement.

This run changes one boundary only: keep Steam's direct GLX client path on
software `swrast`/`softpipe`, while re-enabling CEF GPU and retaining the
explicit Freedreno Vulkan ICD. The purpose is to test whether
`steamwebhelper` can use the hardware Vulkan path independently of the
client's crashing GLX path.

## Predeclared run and provenance

- Run ID: `nova-hardware-software-gl-cef-gpu-20260810T101159Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- Package: `com.xjsonderulo.steamandroid.novalab`
- Source commit at launch: `456cba17a512bdaa8c8c386285764a307cd44850`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256: `773ff7cc263d0fe9873c8a60c10fa7063c88ec6070550c676596df62e8bdd448`
- Presentation: Termux:X11 Android SurfaceView, display `:0`
- X11 stretch: enabled, `1280x800` buffer into the Nova `1280x960` surface
- Audio bridge: disabled
- Physical and synthetic input: none
- Game launch: none

The intended launcher/client split is:

```text
hardware_accel=1
cef_disable_gpu=0
steam_force_software_gl=1
client_gl_mode=software
client_mesa_driver=swrast
client_gallium_driver=softpipe
client_libgl_always_software=1
client_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
```

Launch only after the exact Nova cleanup helper and a fresh-session check:

```text
am start -W -n com.xjsonderulo.steamandroid.novalab/.LauncherActivity \
  --ez run_steam_session true \
  --ez hardware_accel true \
  --ez cef_disable_gpu false \
  --es steam_ui_mode minimal \
  --ez steam_force_software_gl true
```

## Acceptance and interpretation

A successful split requires all of the following from the fresh run:

1. The launcher records `hardware_accel=1`, `cef_disable_gpu=0`, and
   `steam_force_software_gl=1`.
2. The client records software GL markers, the explicit Freedreno ICD, and
   `client_started=pass` without status 139.
3. Fresh Steam/webhelper evidence shows a stable visible frame.
4. CEF reports a hardware/Vulkan renderer or equivalent non-software GPU
   status attributable to this run.
5. Termux:X11 independently records Android Adreno EGL and the expected
   shared-buffer geometry.

If Steam still crashes, this closes the CEF-GPU split and leaves the
hardware-rendering blocker in the client/runtime GLX boundary. If Steam stays
alive but CEF reports software rendering, the result is a display stability
control only. No game, input, audio, or networking conclusion may be drawn
from this run.

After capture, use the direct root launcher stop path, restore all X11
preferences byte-for-byte, remove only run-scoped temporary artifacts, and
verify no matching Steam/Gamescope/X11 process remains. Record the result in
the follow-up document and push it before starting another device experiment.

This run follows [34](34-nova-runtime-harness-lifecycle.md) and the known-good
software-GL display control in [219](219-nova-termux-x11-hardware-display-software-gl-isolation-experiment-2026-08-10.md).
