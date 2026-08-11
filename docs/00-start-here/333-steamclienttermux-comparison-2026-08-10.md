# `steamclienttermux` comparison and Nova integration guidance

Date: 2026-08-10
Status: comparison complete; no device run performed
Scope: compare the freshly cloned `huntergdavis/steamclienttermux` project with
the current Nova direct Termux:X11 and APK/provisioning work.

## Provenance and checkout state

The comparison repository was cloned as a separate sibling checkout:

```text
/Users/kurt/Developer/steamclienttermux
remote: https://github.com/huntergdavis/steamclienttermux.git
branch: main
HEAD: a008a5f0ee8a20dcd3245293482f6234a0aff378
```

The comparison snapshot below was captured against `a008a5f` (`Allow empty
removable mount shadows`). The separate checkout is intentionally kept live
for agent follow-up; it was refreshed after this snapshot and is currently
clean at `origin/main` commit `8d14c10195b34fe2714ba59df1680df27a852532`
(`Apply GTA IV signed registry state`). The repository is a complete working
tree for comparison only; it was not copied into Nova, added as a submodule,
or treated as a source of proprietary Steam or game payloads.

## Current agent handoff

When a task touches Runtime 4, Proton 11 ARM64, Pressure Vessel, FEX/DXVK,
route visibility, PulseAudio, removable game storage, or session logging,
inspect the current sibling checkout before implementing a Nova analogue:

```sh
git -C /Users/kurt/Developer/steamclienttermux status --short --branch
git -C /Users/kurt/Developer/steamclienttermux rev-parse HEAD
```

Read the pinned evidence in this document first, then compare the current
checkout's `README.md`, `docs/TECHNICAL_LOG.md`, and relevant `bin/`,
`diagnostics/`, `scripts/`, and `config/` files. Record the source revision in
the Nova experiment. Borrow narrow contracts; preserve Nova's rooted
Holo/direct-X11 product boundary and never copy Steam, Proton, runtime, game,
or authentication payloads into this repository.

The Nova checkout was at:

```text
/Users/kurt/Developer/steam-android-runtime-research
HEAD before this documentation commit: 489573e5765e6b5472ed7724409c5100dc0ca4c2
```

The Nova working tree already contained seven modified tracked paths and new
APK/provisioning assets. Those changes are user work and are deliberately not
part of this record's commit. The comparison was read-only with respect to
both runtime environments: no Android device session, Steam session, or
authentication data was touched.

## Executive conclusion

`steamclienttermux` is the strongest local prior-art reference for the part of
the Nova problem that begins after a display can be shown: native ARM64 Steam,
official ARM64 Proton, Pressure Vessel, FEX, DXVK, Turnip, networking
compatibility, audio, storage discipline, and repeatable game launching.

It is not a drop-in replacement for Nova. The projects use different
privilege and filesystem architectures:

```text
steamclienttermux:
  Android -> Termux -> Debian/glibc PRoot -> native ARM64 Steam -> Proton/FEX

Nova:
  Android APK/root helper -> Holo/glibc rootfs -> direct Termux:X11 Steam
  with optional Gamescope/AHardwareBuffer presentation
```

The correct use of the clone is therefore selective. Preserve Nova's current
known-good direct X11 presentation path, and port or reproduce the target
project's narrow runtime contracts one at a time. Do not replace Nova's rooted
chroot with the target's PRoot stack before a game reaches its first frame.

## Capability comparison

| Boundary | `steamclienttermux` | Current Nova path | Assessment |
| --- | --- | --- | --- |
| Android integration | Unrooted Termux and Termux:X11 on a Samsung Galaxy Tab S9+ | Rooted Retroid Pocket Nova APK, `su`, private rootfs, and Termux:X11 | Platform assumptions differ; lifecycle ideas are reusable, device paths are not |
| Native Steam | ARM64 Steam client launches, authenticates, renders UI, and downloads games | ARM64 Steam reaches QR/OOBE and signed-in Big Picture through direct X11 | Nova has the display/product baseline; target has the more mature game boundary |
| Steam UI rendering | `-cef-disable-gpu` stabilizes CEF; games still use hardware Vulkan | Nova exposes CEF/software-vs-hardware switches and direct X11 controls | Keep CEF software rendering as the default until a game frame is stable |
| Vulkan games | Private Mesa Turnip bundle | KGSL Turnip driver/ICD staged in Holo | Same broad GPU strategy, but artifacts and Android loader paths must stay device-specific |
| Linux runtime | Patched Termux PRoot plus official Steam Linux Runtime 4 ARM64 | Holo rootfs plus a current SteamRT3C snapshot in the uncommitted provisioner | Runtime 4 versus SteamRT3C needs an isolated A/B test |
| Proton | Official Proton 11 ARM64, registered with explicit App IDs and Runtime 4 dependency | Proton 11 ARM64 files plus local wrapper manifests and a wrapper setup script | Target's manifest semantics are cleaner and should be reproduced first |
| Networking | Private `/proc/net` route snapshot, Pressure Vessel injection, scoped `lsof`, and optional SteamUI guards | SteamUI optional-method/OOBE compatibility patch, host-network continuation, and D-Bus profiles | Nova's patch is UI-facing; target adds the kernel-observation and game-runtime side |
| Audio | Canonical PulseAudio server exposed over loopback TCP at port 4713 | Optional ALSA-to-Android `AudioTrack` bridge; sound works but can be delayed and Steam may report no devices | Test PulseAudio TCP before extending the custom bridge |
| Storage/logging | Free-space floor, bounded output, safe noisy-log redirection, runtime shadow checks | Versioned provisioning and cleanup work is in progress; direct client logs are `/tmp` files without the target's hard cap | Port the log guard independently of runtime changes |
| Removable game data | Validated microSD layout with internal Steam control metadata and compatdata | Not currently the blocker | Reuse later if Nova storage expansion is needed |
| Packaging | Shell/scripts installed into a stable Termux prefix | One-click APK, foreground service, first-run provisioning, and Termux:X11 launch | Nova's APK is the right product layer; target is the right runtime reference |

## What the comparison repository actually proves

The target README and technical log report these concrete milestones:

- Native ARM64 Steam launches, authenticates, renders its UI, and downloads
  games.
- Turnip provides Vulkan acceleration on the Adreno GPU.
- Official Proton 11 ARM64 and Steam Linux Runtime 4 ARM64 are registered
  through the expected ARM64 paths.
- Superflight runs fullscreen through FEX, Wine, DXVK, and Turnip with
  PulseAudio output.
- Kingsway runs fullscreen with audio using the validated removable-library
  split.

The target does not claim that every Windows game works. Its technical log
also records a Burnout/EA path that reached official Proton, ARM64 Wine,
FEX, and DXVK but later failed in the Link2EA/DXVK boundary. This distinction
matters for Nova: the target is evidence that the standard ARM64 Proton/FEX
stack can become real and useful, not evidence that Nova's current Vulkan WSI
boundary is already solved.

The target's local validation suite completed successfully during this audit:

```sh
for test_file in scripts/test-*.py; do
    PYTHONDONTWRITEBYTECODE=1 python3 "$test_file" || exit
done
```

The six tests cover the Superflight profile, PulseAudio preparation, the
Pressure Vessel route wrapper, CPU affinity, removable-library handling, and
the session/log guard. Nova's shell scripts also passed a read-only `bash -n`
syntax sweep.

## Runtime and compatibility-tool findings

### Target: explicit official ARM64 registration

The target's
[`config/steam-arm64-compatibilitytools.vdf.in`](https://github.com/huntergdavis/steamclienttermux/blob/a008a5f0ee8a20dcd3245293482f6234a0aff378/config/steam-arm64-compatibilitytools.vdf.in)
declares:

- Proton 11 ARM64 App ID `4628740`, depot `4628741`;
- Steam Linux Runtime 4 ARM64 App ID `4185400`, depot `4185401`;
- Proton's `require_tool_appid` as `4185400`;
- the exact official ARM64 install paths and aliases.

This matters because Steam resolves a Proton tool's required runtime by its
numeric App ID. The target's launcher consequently overlays a prepared Runtime
4 shadow onto the exact guest path Steam requests, while leaving the official
depot and appmanifest untouched.

Nova's current checked-in compatibility manifest,
[`nova-proton-11-arm64-compatibilitytool.vdf`](../../android/nova-lab/device/nova-proton-11-arm64-compatibilitytool.vdf),
contains only a local tool name, install path, display name, and OS lists. The
current wrapper setup additionally copies the Proton tree into a local wrapper,
creates relative links, and removes the `4185400` dependency from the copied
`toolmanifest.vdf`. That may be a useful diagnostic escape hatch, but it is not
the closest representation of Valve's supported registration model.

The uncommitted Nova provisioning manifest currently pins:

```text
runtime_version:       nova-holo-direct-x11-20260810-v3
Holo rootfs:            mash-20251118.3/system.rootfs.zst
rootfs SHA-256:        7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
Steam client seed:     bins_linuxarm64_linuxarm64.zip.7affd5c9053499769e4f0a46bbb6cbdf0ba0d548
seed SHA-256:          b2de13c267e101679750445c9c449fbfb58dbb7c9851729e95ac69637b9df563
Steam runtime:         SteamRT3C 3c.0.20260714.251839
SteamRT3C SHA-256:     f59e9541fb08f36097610f8cab07a0ed8f5f13e4a642b6fead87505aff979ab0
Turnip SHA-256:        a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
free-space floor:      8 GiB and 200,000 inodes
```

The direct comparison should therefore be a new versioned runtime/profile,
not an in-place replacement:

1. Keep the current SteamRT3C profile and its working QR/OOBE/Big Picture state
   intact.
2. Add an official Runtime 4 ARM64 profile using the target's App ID and
   `require_tool_appid` semantics.
3. Run a runtime-only smoke test through Pressure Vessel.
4. Launch one small game with the same display, input, and storage variables.
5. Compare first-frame and failure logs before changing WSI or Gamescope code.

### Target: patched PRoot is not a free Nova upgrade

The target pins Termux PRoot commit
`a89b3732ec6ae1db674510f0843b2f3db54d0a2f` and applies a ten-patch series for
robust-list behavior, SysV IPC, `.l2s` link presentation, mountinfo escaping,
Pressure Vessel bind paths, pivot behavior, and shared temporary paths. It
hash-stamps the patch set, source diff, and resulting binary before launch.

That work is valuable evidence about what Pressure Vessel expects, but Nova is
currently using root plus a direct Holo rootfs rather than PRoot. Replacing the
Nova architecture with PRoot would reintroduce the target's own historical
Pressure Vessel failure surface: `.l2s` pseudo-links, spaced Proton paths,
shared `/tmp`, and container bind resolution. Port the observed contracts, not
the entire implementation, unless a later rootless Nova branch explicitly
requires PRoot.

## Networking findings

### Target's runtime-facing path

The target's
[`prepare-proc-net-shadow.sh`](https://github.com/huntergdavis/steamclienttermux/blob/a008a5f0ee8a20dcd3245293482f6234a0aff378/bin/prepare-proc-net-shadow.sh)
builds a private, validated `/proc/net` directory containing only `route` and
`ipv6_route`. It derives an interface, address, mask, gateway, and route table,
then atomically replaces the snapshot. The compiled
[`pressure-vessel-route-bwrap.c`](https://github.com/huntergdavis/steamclienttermux/blob/a008a5f0ee8a20dcd3245293482f6234a0aff378/diagnostics/pressure-vessel-route-bwrap.c)
injects that directory into Bubblewrap's NUL-delimited argument stream after
the `/proc` mount. It validates ownership, permissions, file types, and
unexpected entries before passing control to the real `srt-bwrap`.

The target also uses a narrow [`lsof`](https://github.com/huntergdavis/steamclienttermux/blob/a008a5f0ee8a20dcd3245293482f6234a0aff378/bin/lsof) shim.
It only intercepts Steam's loopback `lsof -i TCP@127.0.0.1:<port>` query and
reports a matching `steamwebhelper` NetworkService process; every other `lsof`
call delegates to Termux's real implementation.

These pieces address Android's restricted network-observation interfaces from
inside the Linux runtime. They are different from SteamUI's JavaScript calls.

### Nova's current path

Nova's
[`nova-steam-network-api-compat.sh`](../../android/nova-lab/device/nova-steam-network-api-compat.sh)
patches minified SteamUI bundles so missing `SteamClient.System.Network` methods
become optional, changes the OOBE network path to continue with the Android host
network, and adjusts OOBE completion ordering. This is useful for getting
through the UI, but it does not provide Wine/Proton with route visibility and it
does not make Android Wi-Fi/Bluetooth APIs appear inside the Holo rootfs.

For Nova, the target's design should be adapted as follows:

- Prefer root-visible `ip route`/interface information or a controlled
  `/proc/net` snapshot over `termux-wifi-connectioninfo`; the latter is a
  Samsung/Termux-specific assumption.
- Add a narrow `lsof` compatibility probe only if fresh Steam logs show the
  loopback ownership query failing.
- Inject the route snapshot into the actual Proton/Pressure Vessel child, not
  just the Steam client process.
- Keep the existing UI patch as an OOBE compatibility layer, and label it
  separately from runtime network reachability.

## Audio findings

The target's
[`prepare-pulseaudio-tcp.sh`](https://github.com/huntergdavis/steamclienttermux/blob/a008a5f0ee8a20dcd3245293482f6234a0aff378/bin/prepare-pulseaudio-tcp.sh)
ensures one project-private PulseAudio server exists, loads
`module-native-protocol-tcp` on `127.0.0.1:4713` when needed, and verifies the
TCP endpoint before Steam starts. The launcher then exports:

```text
PULSE_SERVER=tcp:127.0.0.1:4713
```

This is a conventional Linux audio contract and is substantially simpler than
making every Steam/Proton/ALSA client cross into Android `AudioTrack` directly.

Nova's direct launcher currently has an optional
[`nova-alsa-audiotrack-bridge.c`](../../android/nova-lab/device/nova-alsa-audiotrack-bridge.c)
preload path. The bridge is useful as a device-specific fallback and has
already produced audible startup/UI sound, but the delayed sound and Steam's
intermittent “no input or output devices” report make it a poor sole baseline.
The next audio experiment should first expose the existing Termux/X11 Pulse
server over loopback to Holo and set `PULSE_SERVER` for the client and game.
Only if that fails should the AudioTrack bridge remain the primary path.

## Storage and lifecycle findings

The target's
[`steam-arm64-session-guard.py`](https://github.com/huntergdavis/steamclienttermux/blob/a008a5f0ee8a20dcd3245293482f6234a0aff378/bin/steam-arm64-session-guard.py)
is directly relevant to Nova's previous storage incident. It:

- enforces a free-space floor before launch;
- caps mirrored stdout at 1 MiB and the canonical session log at 64 MiB by
  default;
- replaces only known noisy CEF log paths with exact `/dev/null` symlinks;
- refuses to change an unexpected path or a path belonging to a live Steam
  process;
- verifies the canonical log is a private, singly-linked regular file;
- drains child output after the cap so the launcher does not deadlock.

Nova's direct client currently writes fixed `/tmp/nova-steam-client.log`,
`.stdout`, `.stderr`, and optional D-Bus/audio logs. It clears the main client
log at the beginning of a run, but does not have the target's byte cap and
safe noisy-log guard. This should be ported as a small independent helper,
without tying it to Runtime 4 or the APK provisioner.

The current Nova versioned provisioner has the right high-level storage shape:
it checks root, architecture, free bytes, and free inodes; preserves the legacy
`/data/local/tmp/nova-holo-rootfs`; stages downloads under a versioned hidden
directory; verifies hashes; and activates a complete runtime through an
atomic marker. The target's session guard complements that design by protecting
the long-lived Steam data and logs after activation.

## Packaging and product boundary

Nova's APK work is materially more product-oriented than the comparison
repository. The APK can own the foreground service, root grant, Termux:X11
launch, cleanup, progress reporting, and first-run provisioning. The target's
shell installer and desktop entry are useful implementation references, but
they should not replace the APK lifecycle.

The first-run critical path should remain:

```text
APK -> root availability/free-space check -> verified versioned Holo runtime
    -> direct Termux:X11 -> native ARM64 Steam -> QR/OOBE -> Big Picture
```

Gamescope/AHardwareBuffer, embedded X11, and rootless PRoot remain optional
profiles. The target comparison does not change the acceptance boundary for
the current product: preserve the current display, network, controller, and
audio baseline while extending the game-launch path.

## Proposed integration sequence

### Phase 1: preserve the baseline

- Keep `/data/local/tmp/nova-holo-rootfs` untouched as rollback.
- Keep the current versioned direct-X11 profile selectable by marker/profile,
  not by overwriting its files.
- Add the target-derived log cap before another long session.
- Record fresh Steam, SteamUI, Proton, and Pressure Vessel logs per run.

Acceptance: QR/OOBE and signed-in Big Picture still render on the Nova with no
new display or input regression.

### Phase 2: standard ARM64 runtime registration

- Reproduce the target's explicit Proton 11 ARM64 and Runtime 4 ARM64 manifest
  semantics in a separate Nova profile.
- Do not remove `require_tool_appid` from the test profile.
- Verify `_v2-entry-point --verb=run -- /bin/true` and the exact Proton command
  before launching a game.
- Keep the current SteamRT3C profile available for comparison.

Acceptance: the official Runtime 4 container starts cleanly, contains no
contaminated runtime links, and reaches Proton without a wrapper-only success.

### Phase 3: conventional audio

- Start or reuse the Termux PulseAudio server.
- Expose only loopback TCP and set `PULSE_SERVER` inside Holo/Proton.
- Capture `pactl info`, Steam audio-device state, and a short game audio test.
- Retain the AudioTrack bridge as an explicitly named fallback profile.

Acceptance: Steam reports an output device and UI/game sounds arrive without
the observed long delay.

### Phase 4: runtime network compatibility

- Add a Nova-specific route snapshot generator based on the rooted Android
  interface data.
- Add the target-style Pressure Vessel `/proc/net` injection only when a fresh
  Proton/Wine log demonstrates the need.
- Add the scoped `lsof` shim only when the exact Steam loopback query fails.
- Leave the SteamUI optional-method patch in place for OOBE, but report the two
  boundaries independently.

Acceptance: a Proton child can enumerate the host route and complete a small
  authenticated download or game-network check while Steam UI remains healthy.

### Phase 5: first-frame game gate

- Use the current one-click Geometry Wars profile.
- Change only the runtime/compatibility variables under test.
- Capture the first game window, Proton command, DXVK/Wine logs, Vulkan
  extensions, and WSI error.
- Classify the failure as runtime setup, FEX/Wine, DXVK, Vulkan WSI, X11, or
  Android presentation before changing another layer.

Acceptance: one small game produces a real frame through the direct X11 path.
Only after that should the project revisit Gamescope/AHardwareBuffer promotion
or embedded X11 packaging.

## Non-goals and safety boundaries

- Do not copy Valve Steam, Proton, runtime, or game binaries into Git.
- Do not export, back up, or include Steam authentication secrets.
- Do not make the public comparison checkout a submodule or vendor its
  proprietary runtime data.
- Do not replace the known-good Nova rootfs until the staged candidate passes
  all validation gates.
- Do not treat target-device success as Nova-device proof; the target uses a
  different Android/product privilege boundary even though both paths use
  ARM64 Steam, Termux:X11, and Turnip.

## Files consulted

Comparison repository:

- `README.md`
- `docs/ARCHITECTURE.md`
- `docs/PROPRIETARY_AND_BINARY_INPUTS.md`
- `docs/TECHNICAL_LOG.md`
- `bin/steam-arm`
- `bin/prepare-proc-net-shadow.sh`
- `bin/prepare-pulseaudio-tcp.sh`
- `bin/lsof`
- `bin/steam-arm64-session-guard.py`
- `diagnostics/pressure-vessel-route-bwrap.c`
- `scripts/build-proot.sh`
- `scripts/prepare-arm64-runtime-shadow.sh`
- `config/steam-arm64-compatibilitytools.vdf.in`

Nova repository:

- `android/nova-lab/README.md`
- `android/nova-lab/device/nova-termux-x11-steam-client.sh`
- `android/nova-lab/device/nova-steam-network-api-compat.sh`
- `android/nova-lab/device/nova-runtime-cleanup.sh`
- `android/nova-lab/device/nova-alsa-audiotrack-bridge.c`
- `android/nova-lab/device/nova-proton-11-arm64-compatibilitytool.vdf`
- `android/nova-lab/device/nova-proton-11-arm64-wrapper-setup.sh`
- `android/nova-lab/provisioning/nova-runtime-manifest.tsv` (uncommitted at audit time)
