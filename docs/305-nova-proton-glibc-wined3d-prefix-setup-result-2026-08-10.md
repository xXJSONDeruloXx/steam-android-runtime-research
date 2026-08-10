# Nova glibc Proton WineD3D prefix-setup control — result — 2026-08-10

## Result

The corrected glibc control successfully reproduced Proton's normal prefix
setup path and reached the real Geometry Wars executable through FEX, Wine,
Wined3D, OpenGL, and a software `softpipe` renderer. It did not produce a
game frame. The first fatal game-side sequence was an audio-device
initialization failure followed immediately by a null-read access violation;
Wine launched `winedbg`, so the wrapper's 60-second bound ended with exit 124.

This closes the unfair-prefix concern. WineD3D is no longer an untested
fallback, and the result is not a Vulkan WSI or Gamescope/AHardwareBuffer
failure.

The audio error is the nearest preceding failure, not yet a proven causal
explanation for the game's null dereference. The next control should disable
or isolate Wine audio while keeping the same Proton/WineD3D/softpipe path.

## Run identity and provenance

- Run ID:
  `nova-glibc-proton-wined3d-prefix-setup-corrected-20260810T142127Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`, Android 13, `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Game executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- Game executable SHA-256:
  `457340226810ea529310f17875d87201cc93635e5a375ea4b5fdb75361887129`
- Android APK SHA-256:
  `7f94e8bc85717147c2c62b4438fae26a826d1132cbbec4e103c9ddad79b84229`
- Wrapper:
  `android/nova-lab/device/nova-proton-glibc-geometry-wars.sh`
- Wrapper SHA-256:
  `b14ce1e9d761440abebee283c9900dd09ef69dda526df36e66a4c531b1ac5846`
- Repository HEAD: `87cf71cb766391cdea7b234948b38be13cad988f`
- Compatibility tool:
  `/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64/proton`
- Installed Proton prefix version: `11.0-100`
- Parent profile: hardware acceleration enabled, CEF GPU disabled, Steam
  `gamepadui`, Steam client software GL forced, CEF environment split enabled
- Parent display: fresh Termux:X11 `:0`, Android `1280x960`, stretched X11
  `1280x800`
- Game WSI layer: unset
- Game Vulkan ICD: unset

Host evidence is retained under:

`android/nova-lab/build/runs/nova-glibc-proton-wined3d-prefix-setup-corrected-20260810T142127Z/`

Key evidence hashes:

- `game-output.txt`: `c5dbdd10466cb24203b1c4f2ce783576d88be6a783e9daf7d40cbc1793cec2df`
- `game-status.txt`: `12d4495cadf2f8c7c680c4189b9f6a0af45780548e072676be05178892fb36e3`
- `proton-log.txt`: `be022201ac8cadca2b3dc3d72b91ce731699681903a6dde133c1ce52f267b368`
- `screen-before-game.png`: `964390d43bbe559396c2b1cd10235559208dac567e0d4a16fce7899a4723f154`
- `screen-after-game.png`: `d55ca8243a55d34563a28c9bca0477be90279ab1453fecd205be66c52adde98b`
- `parent-stop.txt`: `b774f18b2f350afebbc33b92db606573e46b73b9bc62a1e46baa394edafa32a7`

## Prefix setup correction verified

Before launch, the persistent AppID 8400 compatdata contained only `pfx`,
`pfx.lock`, and `proton-fex-config.json`; it had no `tracked_files`, `version`,
or `config_info`. The run copied that directory to a new run-scoped path and
seeded only an empty uid-501/gid-20 `tracked_files` file.

Proton's normal `run` action then generated the expected bookkeeping:

- `tracked_files`: 135,774 bytes
- `version`: `11.0-100`
- `config_info`: generated and beginning with `11.0-100`
- fresh Proton log: 798,275 bytes

The game output recorded:

```text
mount_private=pass path=/
x11_namespace_input=pass allowed_events=9 hidden_events=
nova_glibc_proton=pass mode=wined3d run_id=nova-glibc-proton-wined3d-prefix-setup-corrected-20260810T142127Z
nova_glibc_proton_setup=proton_run
nova_glibc_proton_wined3d=1
nova_glibc_proton_software_gl=swrast/softpipe
nova_glibc_proton_vk_icd=unset
Proton: Upgrading prefix from None to 11.0-100 (.../compatdata/8400/)
```

The persistent prefix registry hashes were unchanged before and after the
run:

```text
system.reg   5a7fba0513db2c05776d5b3de08140d2a897ca711842b74dbb475e6ad47ffa22
user.reg     1943c8d9f5b2da5e4bd9ef016c1c49f62d110a3882c67b94af60adcaa209217a
userdef.reg  a2e53741b4af39b5371308fb9ab998988cbdd0ed69b377dc29c89d1a6cfa791e
```

## Rendering and startup evidence

The fresh Proton log reports `Options: {'forcelgadd', 'wined3d',
'gamedrive'}` and shows the following sequence:

1. FEX loaded `libwow64fex.dll`.
2. The real `GeometryWars.exe` loaded as the native game module.
3. Wine loaded builtin `d3d9.dll`, `wined3d.dll`, and `opengl32.dll`.
4. Wined3D reported `GL_RENDERER "softpipe"`.
5. Wined3D created its swapchain; the only related warning was that the game
   requested more than one back buffer, which this Wined3D path does not
   properly support.
6. Wine loaded the game input and Steam client modules, including
   `XINPUT1_3.dll` and `steamclient.dll`.

The first fatal sequence was:

```text
err:dsound:DSOUND_ReopenDevice Initialize failed: 8889000f
warn:seh:dispatch_exception code=c0000005 (EXCEPTION_ACCESS_VIOLATION)
wine: Unhandled page fault on read access to 00000000 at address 004AB0C4
wine: ... starting debugger...
```

The post-game screenshot was black rather than a Geometry Wars frame; the
pre-game screenshot still showed the signed-in Steam library. Because the
game process and `winedbg` remained alive after the wrapper timeout, the exact
PIDs were terminated during teardown. No game-frame acceptance claim is made.

The log also contains a Vulkan physical-device enumeration warning from Wine,
but this control intentionally left the Vulkan ICD and WSI layer unset and
selected Wined3D/OpenGL. That warning is not the first failing boundary for
this control and does not reopen the Vulkan WSI question.

## Cleanup and preflight hygiene

The exact parent stop returned `nova_launcher_stop=pass`, the exact run
staging and wrapper were removed, and the final process audit contained no
matching Nova, Steam, Proton, Wine, FEX, Geometry Wars, Gamescope, or input
relay process.

The preflight snapshot exposed ten older PPID-1 uid-501 Wine processes with
Windows-style argv left by an earlier session. They were verified as stale
Wine service/game processes and terminated by their explicit PIDs before this
run. That contamination would otherwise have violated the fresh-process
baseline even though the named Nova cleanup helper reported pass.

## Next control

Run a new, separately documented WineD3D control with the same prefix setup,
software GL, Proton tool, and game, but isolate the audio boundary. The
minimum useful comparison is to disable Wine audio drivers or route them to a
known null backend, then compare whether Geometry Wars reaches its first frame
or the same `004AB0C4` fault. Keep the WSI layer, Vulkan ICD, Gamescope, and
AHardwareBuffer path unchanged.

Only after that comparison should we decide whether the remaining failure is
an audio-dependent game/Wine/FEX issue or proceed to the explicit DXVK control
and the narrow Win32-surface-to-X11 investigation described in
[`docs/302`](302-nova-bionic-track-closure-glibc-steamrt-plan-2026-08-10.md).
