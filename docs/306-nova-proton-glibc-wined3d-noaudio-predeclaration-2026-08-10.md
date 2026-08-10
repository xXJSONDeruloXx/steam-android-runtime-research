# Nova glibc Proton WineD3D audio-isolation control — 2026-08-10

## Question

The correctly initialized WineD3D control reached Geometry Wars through FEX,
Wined3D, OpenGL, and `softpipe`, then logged a `winepulse`/`winealsa` device
initialization failure immediately before an access violation. This control
keeps the same Proton prefix setup, game, display, software GL, and private
X11 namespace, but disables only the Wine PulseAudio and ALSA driver DLLs:

```text
WINEDLLOVERRIDES=winepulse.drv=d;winealsa.drv=d
```

The purpose is to distinguish an audio-dependent game/Wine/FEX failure from a
game fault that occurs after Wined3D startup. It is not a product change and
does not modify the persistent prefix, Gamescope, WSI layer, Vulkan ICD, or
Android audio bridge.

The upstream Proton repository documents runtime environment overrides and
the supported `PROTON_USE_WINED3D=1` path in its
[runtime configuration](https://github.com/ValveSoftware/Proton). Valve's
[Proton issue tracker](https://github.com/ValveSoftware/Proton/issues/3766)
also shows the `WINEDLLOVERRIDES="...=d"` disable form used for a runtime
DLL. The exact audio-driver result remains an experiment for this device.

## Fixed inputs

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
- Game renderer: Proton `PROTON_USE_WINED3D=1`, Mesa `swrast/softpipe`,
  `LIBGL_ALWAYS_SOFTWARE=1`
- Game WSI layer: unset
- Game Vulkan ICD: unset
- Prefix source: persistent AppID 8400 compatdata copied into a new run path;
  seed an empty run-copy `tracked_files`, then require Proton to generate
  `version`, `config_info`, and the complete tracked-file list
- Wrapper mode: `wined3d-noaudio`
- Changed variable: only `WINEDLLOVERRIDES`

## Acceptance

The control must capture:

1. fresh parent readiness and the exact session D-Bus address;
2. the wrapper's `nova_glibc_proton_audio=disabled` and explicit override
   markers;
3. Proton prefix setup artifacts and a fresh `PROTON_LOG`;
4. whether `winepulse.drv` or `winealsa.drv` still loads;
5. Wined3D/OpenGL/softpipe initialization and any game frame;
6. the first failure, exit status, and same-run screenshot; and
7. exact parent, Wine, FEX, Gamescope, input-relay, socket, mount, and
   run-staging cleanup.

Compare against the pushed result in
[`docs/305`](305-nova-proton-glibc-wined3d-prefix-setup-result-2026-08-10.md).
Do not call a changed exit status a rendering success without a fresh game
frame and the corresponding process/log evidence.

This predeclaration is committed and pushed before the device run.
