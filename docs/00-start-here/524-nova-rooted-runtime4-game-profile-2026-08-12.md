# Nova rooted Runtime 4/game profile implementation

Date: 2026-08-12
Status: implementation complete on a new branch; no Android device run performed

## Scope and branch state

The rootless work was fast-forwarded into local `main` at `55910b1`, then the
implementation branch was created:

```text
feat/rooted-games-hw-accel
```

The working tree was clean before the merge. This record covers the rooted
profile changes on that branch; it is not a device result and does not claim
that a game currently renders on Nova.

## Borrowed contracts

The clean sibling checkout was verified before use:

```text
/Users/kurt/Developer/steamclienttermux
branch: main
HEAD: 8d14c10195b34fe2714ba59df1680df27a852532
status: clean, tracking origin/main
```

The implementation borrows only narrow contracts from that revision:

- official ARM64 compatibility-tool registration: Proton 11 AppID `4628740`,
  depot `4628741`, Runtime 4 AppID `4185400`, depot `4185401`, and
  `require_tool_appid=4185400`;
- Runtime 4 execution through `_v2-entry-point --verb=run --`;
- a separate real-file Pressure Vessel shadow when the installed ARM64 tree
  contains `.l2s` pseudo-hardlinks;
- `VK_DRIVER_FILES` as an explicit Vulkan-selector A/B alongside the legacy
  `VK_ICD_FILENAMES` control; and
- loopback PulseAudio via `PULSE_SERVER=tcp:127.0.0.1:4713`, plus bounded
  session logging.

Nova still uses the rooted Holo/glibc rootfs and direct Termux:X11. No PRoot,
Valve payload, game payload, or authentication data was copied into the
repository.

## Rooted implementation

The one-click rooted launcher now:

1. registers the official ARM64 Proton/Runtime 4 manifest under the exact
   nested Nova Steam client root;
2. stages the Runtime 4 shadow under
   `/opt/nova-steam/runtime/SteamLinuxRuntime_4-arm64` only when the opt-in
   `runtime4` profile is selected;
3. bind-mounts that shadow over Steam’s conventional
   `steamapps/common/SteamLinuxRuntime_4-arm64` path inside the private mount
   namespace, leaving the installed depot untouched;
4. stages the session guard and Geometry Wars runner into
   `/opt/nova-kgsl-driver`; and
5. passes explicit hardware/Vulkan-selector, runtime, audio, and Pulse
   settings into the direct Steam client.

The defaults preserve the current product boundary: SteamRT3C, CEF/software
client behavior selected by the existing hardware flag, and the AudioTrack
bridge. `driver-files` is the new explicit hardware Vulkan selector default,
but it is a hypothesis for the next A/B, not a result.

The direct client accepts these profile controls:

```text
NOVA_TERMUX_X11_STEAM_VK_SELECTOR=driver-files|icd-filenames|none
NOVA_TERMUX_X11_STEAM_RUNTIME_PROFILE=steamrt3c|runtime4
NOVA_TERMUX_X11_STEAM_AUDIO_MODE=bridge|pulse|none
NOVA_TERMUX_X11_STEAM_PULSE_SERVER=tcp:127.0.0.1:4713
```

Its per-run log is capped at 64 MiB by default. The guard remains optional when
a direct entry point has not staged the helper or the selected Holo closure
lacks `/usr/bin/python3`; the one-click rooted path stages it and runs it
whenever that interpreter is present.

## Game/runtime runner

`nova-proton-glibc-geometry-wars.sh` retains the existing WineD3D, DXVK, and
WSI diagnostic modes and adds:

```text
runtime4-smoke <run-id>
```

That mode fails closed unless the staged Runtime 4 has an entry point, `run`,
real Pressure Vessel wrapper, marker, and no `.l2s` links, then runs the
sibling-derived trivial command:

```text
_v2-entry-point --verb=run -- /bin/true
```

For a game, `NOVA_GLIBC_PROTON_RUNTIME=runtime4` invokes the official Proton
path through the same Runtime 4 entry point. The runner defaults its game
audio profile to the loopback PulseAudio contract; `bridge` and `none` remain
explicit alternatives.

## Validation and next gate

Host-side validation passed:

```text
android/nova-lab/test-rooted-games-profile.sh  -> rooted_games_profile_static=pass
android/nova-lab/test-rootless-profile.sh      -> rootless_profile_static=pass
```

Shell syntax, Python session-guard compilation, asset registration, manifest
IDs, Runtime 4 shadow checks, selector propagation, log-cap paths, and the
private Runtime 4 bind mount are covered by the static checks. `git diff
--check` also passes.

The next device work must be a separately declared lifecycle run using fresh
processes/logs and exact artifact hashes:

1. preserve the SteamRT3C/direct-X11 baseline;
2. test the hardware profile with `VK_DRIVER_FILES` and current rooted Turnip;
3. if the official ARM64 payloads are installed, run `runtime4-smoke` through
   the private namespace;
4. then run one Geometry Wars DXVK profile with a fresh first-frame screenshot,
   Proton/DXVK/Wine/FEX logs, and cleanup verification; and
5. test PulseAudio separately from the bridge so audio success is attributable.

No one of these implementation or static checks is evidence of a Nova game
frame, Vulkan WSI success, Gamescope success, or hardware-accelerated Steam
UI. Those claims remain gated on fresh device evidence.
