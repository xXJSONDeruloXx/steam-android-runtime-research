# Nova 8-Bit Bayonetta authentic Steam-client retry — 2026-08-13

## Question

Can a small, DRM-free Windows game installed by the real Steam client start on
the rooted Nova direct-X11 path, and does its result distinguish the game
runtime from the earlier Geometry Wars and Peggle failures?

The target is 8-Bit Bayonetta, App ID `567090`. This is an authentic Steam
client experiment; GameNative was not used.

## Provenance and controls

- Nova checkout: branch `feat/rooted-cef-gpu-games`, HEAD
  `27d26036898acccca69f5f0642943989f849b983` with pre-existing working-tree
  changes.
- Sibling comparison checkout: `/Users/kurt/Developer/steamclienttermux`,
  clean `main` at `8d14c10195b34fe2714ba59df1680df27a852532`.
- Device: Retroid Pocket Nova / AYN Thor serial `d234a848`, rooted Android 13.
- Rootfs: `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs`.
- Launcher profile: Runtime 4 shadow, `gamepadui`, 1280×800 X11 stretch,
  hardware acceleration disabled, CEF GPU disabled, and the existing FEX
  compatibility preset.
- Installed executable SHA-256:
  `221e1c1c83bb32b97e0033c820fbffe41c2148dd8c20efe9db0439022891c465`.
- Current appmanifest SHA-256 after Steam's LastPlayed update:
  `c18bd1d3c9c690ade5f57e5b5da047d23be2c3e9b0691937ef2bfeb7b95c129b`.
- Steam's real `config.vdf` contained the explicit priority-250 mapping:

  ```text
  567090 -> proton11_arm64_fex2608-adea3e410
  ```

The game was installed through Steam's own `steam://install/567090` route. The
Steam Big Picture Compatibility page was used to enable and persist the
per-game tool mapping. No game files, authentication data, or runtime payloads
were copied from the sibling checkout.

## Launches

After the previous FEX attempt, the exact AppID/Wine/Proton process scan was
empty and its run-scoped Proton log directory was removed. A fresh launcher
session reached `nova_launcher_ready=pass` with Steam main PID `11033`.

First, the real Steam client was asked to forward:

```text
/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -applaunch 567090
```

Steam returned its normal:

```text
Steam is already running, exiting (command line was forwarded).
```

The new log was `steam-567090.log`, 7,253 bytes. After capturing it, the
log directory was removed and the exact game/Wine process scan was empty.

To test the requested UI path separately, the run-scoped log directory was
cleared again while the Steam client stayed live, and the focused Big Picture
Play button was activated through the virtual Xbox controller. This produced
another fresh 7,253-byte `steam-567090.log` and the same result.

## Result

Both authentic Steam launch routes reached Proton but failed before a durable
game process or game surface:

```text
Proton: 1779182345 proton-11.0-1-beta5-unstripped
SteamGameId: 567090
Command: ['/opt/nova-steam/home/.local/share/Steam/steamapps/common/8BitB/8BB.exe']
...
A 24 Couldn't detect CPU features
0024:err:seh:NtRaiseException Unhandled exception code c000001d flags 0 addr 0x6ffc115f50
```

The process scan remained empty for `8BB.exe`, `wineserver`, Wine preloader,
Proton wait, Pressure Vessel, and `srt-bwrap`. The captured screen returned to
the authentic 8-Bit Bayonetta Steam library page, not the game. The UI-Play
capture SHA-256 is
`6b8aff0f04c45f34b7190863df98f3a7a65905d5ed338361a27e1b9f8cff74e5`.

The log also repeats missing `gameoverlayrenderer.so` preload warnings for
Steam's bin64, bin32, and ARM64 paths. Those warnings are recorded, but they
are downstream of the current FEX CPU-feature/illegal-instruction boundary;
they are not evidence of a game-frame failure caused by the overlay.

The finished log was removed after capture. No matching Wine or Proton process
remained; the rooted Steam UI launcher was intentionally left running.

## Comparison with `steamclienttermux`

The sibling's confirmed Superflight and Kingsway runs select the official
`proton_11_arm64_official` tool and show the actual Runtime 4 prefix:

```text
SteamLinuxRuntime_4-arm64/_v2-entry-point --verb=waitforexitandrun --
Proton 11.0 (ARM64)/proton waitforexitandrun
```

Those runs reached FEX/Wine and, for Superflight and Kingsway, a real DXVK/
Turnip frame. The current Nova 8-Bit mapping selects a local diagnostic wrapper
around Proton 11 ARM64, and its observed failure is at FEX CPU detection before
`8BB.exe` remains alive. The current Nova process evidence did not show the
sibling's Runtime 4 entry-point command around this custom-tool launch.

8-Bit Bayonetta is another PE32 x86 title, like the earlier Peggle Deluxe and
Geometry Wars controls. Its matching early FEX failure makes it useful as a
cross-check, but it does not justify trying a long list of additional small
32-bit games. The higher-value next experiment is to reproduce the sibling's
official Proton 11 ARM64 plus real Runtime 4 command boundary on Nova, or to
isolate the 32-bit FEX CPU-feature/exception path, with a new run ID and a
freshly deleted Proton-log directory.

## Acceptance

This is an authentic Steam installation and Steam-mediated Proton invocation,
but not a game success. It proves the current failure boundary is reproducible
from both the Steam IPC launch and the actual Big Picture Play control, while
the rooted Steam UI and input path remain functional.
