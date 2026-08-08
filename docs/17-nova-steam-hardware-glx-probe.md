# Nova native Steam hardware GLX probe

Test date: 2026-08-07 (device report timestamps are UTC)
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`

This is a bounded negative probe for the graphics boundary left open by the
software SteamUI smoke. It selects the Holo Mesa `msm` driver, leaves
`GALLIUM_DRIVER` unset so Mesa can select its native path, disables
`LIBGL_ALWAYS_SOFTWARE`, and runs the same Xwayland/Gamescope/AHardwareBuffer
session used by the accepted UI test.

The result is intentionally not described as a hardware CEF failure: Steam
does not reach `steamwebhelper` or CEF. Gamescope itself still initializes the
Turnip Adreno 740 compositor and imports the two Android AHardwareBuffers; the
native Steam client dies during its initial GLX/update-UI path.

## Reproduction

The named wrapper keeps the accepted software profile separate from the
hardware experiment:

```sh
android/nova-lab/deploy-native-steam-hardware-probe.sh || true
```

For the explicit Gallium name experiment, use:

```sh
NOVA_STEAM_GALLIUM_DRIVER=freedreno \
  android/nova-lab/deploy-native-steam-hardware-probe.sh || true
```

The wrapper saves the disposable client logs under the ignored
`android/nova-lab/build/` directory. The underlying report and screenshot use
the normal `deploy-gamescope-headless-ahb-test.sh` paths.

## Observed boundaries

With `NOVA_STEAM_MESA_DRIVER=msm` and no Gallium override, the client log
reported:

```text
client_mesa_driver=msm
client_status=132
```

The client stderr ended with:

```text
UpdateUI: showing logo
/opt/nova-kgsl-driver/gamescope-headless-ahb-control.sh: line 29: ... Illegal instruction ...
```

The resulting status is `128 + SIGILL`, matching the earlier Nova Mesa/SVE
finding: the Holo Mesa native path reaches an instruction unsupported by the
Nova CPU. No `android_ahb_composite_frame=` marker is produced because Steam
never creates a hosted X11 window.

With `NOVA_STEAM_GALLIUM_DRIVER=freedreno`, Steam fails even earlier in the
GLX update UI:

```text
client_mesa_driver=msm
client_gallium_driver=freedreno
glx: failed to create drisw screen
UpdateUI GL not available
client_status=152
```

That profile also produces no hosted Steam frame. The exact cause of the
explicit-name `drisw` failure still needs a focused GLX/DRI probe, but it does
not currently provide a viable hardware Steam path.

The accepted control remains `swrast` + `softpipe`: it reaches SteamUI,
`steamwebhelper`, the pre-login Gamepad UI screen, and the Android
AHardwareBuffer/fence presentation path. The next graphics experiment should
therefore isolate Mesa's CPU/SVE-dependent GLX code or provide a compatible
hardware GL/CEF route; changing Gamescope's Vulkan output is not the current
blocker.

## Remaining graphics gate

- Build a minimal Holo-rootfs GLX/DRI probe that reports the selected DRI
  module, renderer, and failing instruction without launching Steam.
- Determine whether a Nova-compatible Mesa build/configuration can expose
  hardware GLX/CEF without the SVE code path.
- Keep the software profile as the presentation/input regression control until
  the hardware path reaches `steamwebhelper` and reports a non-software CEF
  renderer.
