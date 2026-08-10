# Nova glibc Proton WineD3D audio-isolation control — result — 2026-08-10

## Result

Disabling Wine's PulseAudio and ALSA driver DLLs did not unblock Geometry
Wars. Proton accepted the explicit overrides, neither backend DLL loaded, and
Wined3D again reached OpenGL `softpipe` and its swapchain. The game then
reported that no audio driver could initialize and faulted at the same
`0x004AB0C4` address as the normal WineD3D control.

This rules out a simple `winepulse` versus `winealsa` backend selection fix.
It does not prove that audio is irrelevant: the game still encounters the
missing-audio condition and faults immediately afterward. The result is a
game/Wine/FEX startup failure after Wined3D initialization, not a Vulkan WSI,
Gamescope, or AHardwareBuffer failure.

## Run identity and provenance

- Run ID: `nova-glibc-proton-wined3d-noaudio-20260810T143429Z`
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
  `4db6bdea3b58634ebc96366b1e82448b9b65546dd57421523755532cfcd2f448`
- Repository HEAD: `8f2e1c0`
- Compatibility tool:
  `/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64/proton`
- Parent profile: hardware acceleration enabled, CEF GPU disabled, Steam
  `gamepadui`, Steam client software GL forced, CEF environment split enabled
- Parent display: fresh Termux:X11 `:0`, Android `1280x960`, stretched X11
  `1280x800`
- Game WSI layer: unset
- Game Vulkan ICD: unset
- Changed variable:
  `WINEDLLOVERRIDES=winepulse.drv=d;winealsa.drv=d`

Host evidence is retained under:

`android/nova-lab/build/runs/nova-glibc-proton-wined3d-noaudio-20260810T143429Z/`

Key evidence hashes:

- `game-output.txt`: `a421663df549dd41d306db7100ad49c14eaf48052d5d35542e58583a7304386a`
- `game-status.txt`: `12d4495cadf2f8c7c680c4189b9f6a0af45780548e072676bc05178892fb36e3`
- `proton-log.txt`: `5d69c0b8150d69fc394613e6602bf490df3f125d93d5143a824e740d7632face`
- `screen-before-game.png`: `4121fdeafcd44f84ffc7708ac53f5dea308ebc540ddd6b2041669dc01d2b7b9f`
- `screen-after-game.png`: `d55ca8243a55d34563a28c9bca0477be90279ab1453fecd205be66c52adde98b`
- `parent-stop.txt`: `bcffcee88bbca5d1322adb35e2a91aaeff16803dc5313b2d85527a3103b1415f`

## Prefix and override evidence

The run copied the persistent AppID 8400 compatdata to a fresh path, seeded
only an empty uid-501/gid-20 `tracked_files`, and let Proton's normal `run`
action initialize it. Proton generated:

- `tracked_files`: 135,774 bytes
- `version`: `11.0-100`
- `config_info`: generated, beginning with `11.0-100`
- fresh Proton log: 780,524 bytes

The wrapper and Proton log both recorded the explicit override:

```text
nova_glibc_proton_audio=disabled
nova_glibc_proton_winedlloverrides=winepulse.drv=d;winealsa.drv=d
System WINEDLLOVERRIDES: winepulse.drv=d;winealsa.drv=d
Effective WINEDLLOVERRIDES: winepulse.drv=d;winealsa.drv=d
```

No `winepulse.drv` or `winealsa.drv` load occurred in the fresh log. Instead,
Wine reported:

```text
err:mmdevapi:init_driver No driver from L"pulse,alsa,oss,coreaudio" could be initialized.
```

## Rendering and failure boundary

The fresh Proton log shows the same successful early path as the normal
WineD3D control:

1. `libwow64fex.dll` loaded.
2. The real `GeometryWars.exe` loaded.
3. Builtin `d3d9.dll`, `wined3d.dll`, and `opengl32.dll` loaded.
4. Wined3D reported `GL_RENDERER "softpipe"`.
5. Wined3D initialized its swapchain; the multi-back-buffer warning remains.

The first fatal game-side sequence was then:

```text
err:mmdevapi:init_driver No driver from L"pulse,alsa,oss,coreaudio" could be initialized.
warn:seh:dispatch_exception code=c0000005 (EXCEPTION_ACCESS_VIOLATION) ... addr=004AB0C4
wine: Unhandled page fault on read access to 00000000 at address 004AB0C4
wine: ... starting debugger...
```

The wrapper reached its 60-second bound and returned `game_exit=124` while
the game and `winedbg` remained alive. The post-game capture did not show a
Geometry Wars frame, so this is not a rendering acceptance pass.

Compared with [`docs/305`](305-nova-proton-glibc-wined3d-prefix-setup-result-2026-08-10.md),
the normal-audio run logged `DSOUND_ReopenDevice Initialize failed: 8889000f`
before the same page fault. The no-audio run replaces that backend error with
the expected no-driver message but preserves the exact game fault address.
That makes a one-line PulseAudio/ALSA backend correction unlikely to be the
remaining blocker; a real audio device/null backend or a deeper 32-bit/FEX/game
startup issue remains to be distinguished.

The Wine log also contains Vulkan physical-device enumeration warnings, but
the run intentionally had no Vulkan ICD or WSI layer and selected Wined3D.
They are not the first failing boundary for this control.

## Cleanup

The initial parent start was delivered to an already-top LauncherActivity, so
the test APK was explicitly force-stopped and restarted cold before readiness
was accepted. The cold parent then reported fresh readiness and session D-Bus
address `unix:path=/tmp/nova-steam-runtime/dbus-session-13887/bus`.

After the bounded game attempt, the exact parent stop returned
`nova_launcher_stop=pass`. The nine orphaned Wine/game/debugger PIDs from this
run were terminated by their explicit fresh-run PIDs, the one remaining
`winedevice.exe` was terminated explicitly, the exact run directory and
temporary wrapper were removed, and the final process audit had no matching
Nova, Steam, Proton, Wine, FEX, Geometry Wars, Gamescope, or input-relay
process.

The persistent prefix registry hashes remained unchanged:

```text
system.reg   5a7fba0513db2c05776d5b3de08140d2a897ca711842b74dbb475e6ad47ffa22
user.reg     1943c8d9f5b2da5e4bd9ef016c1c49f62d110a3882c67b94af60adcaa209217a
userdef.reg  a2e53741b4af39b5371308fb9ab998988cbdd0ed69b377dc29c89d1a6cfa791e
```

## Next step

The WineD3D fallback is now fairly closed for this exact prefix and game:
both normal and audio-isolated controls reach Wined3D/softpipe but fault at
the same game address without producing a frame. Move to the separately
scoped explicit DXVK control: use the same correctly initialized run-copy
prefix, record Proton's effective native DLL overrides, capture fresh DXVK
logs, and then classify the Vulkan/WSI result independently.
