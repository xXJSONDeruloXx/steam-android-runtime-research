# Android app roadmap: Linux-first Steam Gamepad UI

This is the project’s current planning document. It describes the product
target, the active experiment, and the gates for moving between stages. The
numbered documents linked here remain the historical evidence; update those
records after each bounded experiment rather than turning this file into a
run log.

Autonomous implementation agents should read this file before choosing work,
then read [doc 333](333-steamclienttermux-comparison-2026-08-10.md) before
importing SteamclientTermux behavior. Treat the immediate execution queue
below as the current priority, and read [doc 34](34-nova-runtime-harness-lifecycle.md)
before any Nova device run. The canonical local prior-art checkout is the
separate sibling repository at `/Users/kurt/Developer/steamclienttermux`;
verify its current clean revision before borrowing implementation details.

## 1. Product target and boundaries

### End-user product contract

The end product is a standalone Android app that launches the native ARM64
Steam client in Gamepad UI and presents the session on the device. The app
owns lifecycle, permissions, storage, downloads, runtime activation, input,
audio integration, and Android presentation. Steam owns login, library,
downloads, Gamepad UI, and game launching.

The install must not require Magisk, root, Termux, or Termux:X11. First-run
setup must acquire an app-owned, versioned, integrity-checked runtime and
activate it atomically. Authentication secrets must remain in place and must
not be exported or backed up. See [doc 299](299-nova-standalone-runtime-acquisition-product-requirement-2026-08-10.md).

### Research-harness boundary

The current rooted Nova/Termux:X11 path is a research harness, not the final
installation model. Root, Magisk, and Termux:X11 are acceptable for proving
runtime, graphics, input, audio, and lifecycle contracts, but every result
must identify the privilege and presentation boundary it actually tested.

Keep `/data/local/tmp/nova-holo-rootfs` as the rollback copy and keep the
current versioned direct-X11 profile selectable. Gamescope/AHardwareBuffer,
embedded X11, and rootless PRoot are optional profiles until the direct
runtime/game path is understood.

### Ownership model

```text
Android app
  ├─ lifecycle / permissions / storage / downloads
  ├─ runtime acquisition, verification, staging, and rollback
  ├─ controller + touch input bridge
  ├─ audio bridge and session diagnostics
  └─ Android Surface / AHardwareBuffer presentation
        │
        └── Linux userspace
              ├─ glibc ARM64 rootfs (Holo/Arch-compatible baseline)
              ├─ native ARM64 Steam client
              ├─ SteamRT3C baseline or isolated Steam Runtime 4 A/B profile
              ├─ gamescope + Wayland/Xwayland where the selected profile needs it
              └─ ARM Proton + FEX for x86 Windows game content
```

The app should not recreate Steam’s library, login, downloads, or Gamepad UI.
Armada and PockNix show that the Steam client already supplies the primary UI
when launched with the Deck session flags.

## 2. Current state — 2026-08-11

### Working baseline

The current Nova direct Termux:X11 session is the comparison baseline:

| Area | Current state | Roadmap treatment |
|---|---|---|
| Native Steam | Native ARM64 Steam launches from the Holo glibc rootfs. | Preserve as the baseline client path. |
| Steam UI | QR/OOBE and signed-in Big Picture have been reached. | Do not regress while changing the game runtime. |
| Display | Direct Termux:X11 presents the current Steam session. | Hold display variables constant for the next A/B test. |
| Network | Steam can use the inherited Android data path for client activity and downloads. | Treat Android connectivity as the data plane; do not model Steam’s UI device scan as transport. |
| Controller | Physical controller input is confirmed in the current signed-in session; see [doc 298](298-nova-physical-controller-live-confirmation-2026-08-10.md). | Remove basic controller transport from the immediate blocker list; retain game controls, rumble, and reattachment as later checks. |
| Audio | Startup and UI sounds are audible, with substantial observed delay. | Keep the current bridge as baseline; improve device reporting and latency after the runtime A/B gate. |
| Runtime | The rootless Holo/PRoot closure and native Steam updater pass. R17's stable/no-link replay stalled before `steamwebhelper`; R18b's stable client plus conventional `.steam` links reproduced the `bin/vgui2_s.dll` fatal. R19 and R21 both reached the stable update through `steamrtarm64/steam`, then exited after `Update complete, launching...` without a post-update Steam process. R20's top-level path was absent from the raw seed, and R21's explicit top-level symlink was replaced by a data directory without changing the boundary. R22's `-noverifyfiles` run bypassed the updater and reached Steam's X11 UI, then failed because `libvideo.so` requested `av_malloc_tracked@LIBAVUTIL_60` from a Holo `libavutil.so.60` that does not export it. R23 staged the matched Valve `libavutil.so.60` and crossed that failure, then exposed Holo `libavcodec.so.62` requesting `av_amf_to_av_format@LIBAVUTIL_60`. R24 staged the complete seven-file Valve media family and crossed both FFmpeg boundaries, then exposed `SDL_TryLockJoysticks@@SDL3_0.0.0` in `steamui.so`; R25 carried the completed rooted public-beta client/runtime/layout/flags and Valve SDL3 provider into rootless, crossed that SDL3 boundary, and stopped at `bin/vgui2_s.dll`/`vgui2_s.so` module-root resolution before SteamUI. R26 replayed the exact current rooted public client under the flattened rootless layout and reproduced the same fatal; R27 replayed those same bytes with the rooted nested client-root/HOME/cwd contract and reproduced it again; R28 carried the rooted SteamRT-first launch environment and library path and crossed the `vgui2_s` boundary, initialized native SteamUI/system controllers, and reached webhelper startup. | R28 is closed in [doc 468](468-nova-rootless-r28-rooted-launch-environment-result-2026-08-11.md): rooted bytes, nesting, and launch environment are now the rootless native-client baseline candidate. The remaining stop is later and separable: the guest cannot enumerate a Vulkan physical device because the rooted KGSL/Turnip ICD was not carried into R28, and webhelper needs app-owned `/dev/shm` plus a machine-id/session-bus contract. Run those as separate parity experiments. Do not guess an alias, patch SteamUI, or advance to Runtime 4, Proton, Gamescope/AHardwareBuffer, or OOBE packaging until the provider/runtime prerequisites are classified. See [docs 443](443-nova-rootless-r18b-steam-layout-links-result-2026-08-11.md), [444](444-nova-rootless-steamclienttermux-launch-contract-host-result-2026-08-11.md), [446](446-nova-rootless-r19-no-version-steam-lifecycle-result-2026-08-11.md), [448](448-nova-rootless-r20-client-root-entry-steam-lifecycle-result-2026-08-11.md), [450](450-nova-rootless-r21-client-root-symlink-result-2026-08-11.md), [452](452-nova-rootless-r22-noverifyfiles-result-2026-08-11.md), [453](453-nova-rootless-steam-media-provider-host-audit-2026-08-11.md), [454](454-nova-rootless-r23-matched-libavutil-predeclaration-2026-08-11.md), [455](455-nova-rootless-r23-matched-libavutil-result-2026-08-11.md), [456](456-nova-rootless-steam-media-suite-host-audit-2026-08-11.md), [457](457-nova-rootless-r24-matched-media-suite-predeclaration-2026-08-11.md), [458](458-nova-rootless-r24-matched-media-suite-result-2026-08-11.md), [459](459-nova-rootless-steam-sdl3-provider-host-audit-2026-08-11.md), [460](460-nova-rootless-r25-rooted-parity-predeclaration-2026-08-11.md), [461](461-nova-rootless-r25-rooted-parity-result-2026-08-11.md), [462](462-nova-rootless-rooted-runtime-layout-audit-2026-08-11.md), [463](463-nova-rootless-r26-rooted-device-public-tree-predeclaration-2026-08-11.md), [464](464-nova-rootless-r26-rooted-device-public-tree-result-2026-08-11.md), [465](465-nova-rootless-r27-rooted-layout-predeclaration-2026-08-11.md), [466](466-nova-rootless-r27-rooted-layout-result-2026-08-11.md), and [467](467-nova-rootless-r28-rooted-launch-environment-predeclaration-2026-08-11.md). |
| Games | Proton/FEX/Wine/DXVK startup has been reached, but the first-frame game gate remains unresolved on the current Nova path. | Classify the next result at the Vulkan/WSI boundary. |
| Gamescope/AHardwareBuffer | Synthetic and SteamUI presentation seams are valuable research evidence, but the product path is not closed. | Defer new low-level compositor work until the runtime A/B result. |

### Current rootless runtime state

R30 remains the last valid provider control: unsetting `VK_ICD_FILENAMES`
reached native SteamUI/webhelper but did not enumerate Vulkan and still hit
the independent `/dev/shm` and D-Bus prerequisites. The Thor stable-payload
replay then returned to the earlier `vgui2_s` boundary because it used a
different stable endpoint client (`steam=72f…`, `steamui=25ad…`,
`vgui2=705f…`). That result is closed in [doc
485](485-ayn-thor-rootless-stable-payload-replay-result-2026-08-11.md).

The rooted Thor comparator used the R28 public-beta client (`6d6…`, `69d…`,
`aba…`), allowed the normal updater, and reached language/timezone/network
OOBE and QR sign-in. It is recorded in [doc
486](486-ayn-thor-rooted-known-good-oobe-comparison-result-2026-08-11.md).
This proves that the `vgui2_s` result is not a simple rootless-impossible
rule, but it does not isolate the root-only services because the rooted path
changes several contracts together.

The exact-client recovery gate is closed in [doc
488](488-ayn-thor-rootless-exact-public-beta-recovery-gate-result-2026-08-11.md):
the rooted Thor tree still has the R28 selected binaries, package/beta, and
installed-manifest hashes, but the recreated full archive differs from the
historical R28 archive. The exact R35 replay was therefore not launched. The
single next baseline is [doc
489](489-ayn-thor-rootless-public-beta-equivalence-replay-predeclaration-2026-08-11.md),
which tested that current sanitized tree under the unchanged doc-485 rootless
environment. The result is closed in [doc
490](490-ayn-thor-rootless-public-beta-equivalence-replay-result-2026-08-11.md):
the current tree crossed `vgui2_s`, initialized native SteamUI, and reached
webhelper startup. Rootless is therefore not generically blind to the current
client; the remaining measured differences from rooted are the absent
`/dev/shm`, machine-id/D-Bus, SteamOS service, and rooted CEF/display
contracts. Vulkan provider selection is still unclassified because both
selectors were unset in R36. Resume the existing Thor R31
`VK_DRIVER_FILES`-only predeclaration in [doc
475](475-ayn-thor-rootless-r31-vk-driver-files-replication-predeclaration-2026-08-11.md),
then isolate `/dev/shm` and D-Bus as separate experiments only when their
preceding evidence justifies them. Do not combine R31 with shared memory,
D-Bus, Runtime 4, Proton, Gamescope/AHardwareBuffer, or packaging changes.

### Near-term iteration mode

Use cold provisioning only for a new device, a changed APK or pinned payload,
a failed fixture-integrity check, or a milestone acceptance run. For R31 and
subsequent one-variable rootless A/Bs on the same device, reuse only a
hash-verified authentication-free Holo/client/provider fixture. Keep every
run's HOME, Steam mutable state, logs, temporary directories, resolver,
Termux:X11 process, listener, screenshot, and readiness baseline fresh. Verify
the fixture before launch and verify it was unchanged after cleanup. This
preserves experiment identity while avoiding another multi-gigabyte
reprovisioning cycle for a selector-only change; see the lifecycle contract in
[doc 34](34-nova-runtime-harness-lifecycle.md).

### Active decision

The first integration to bring over from
[SteamclientTermux](333-steamclienttermux-comparison-2026-08-10.md) is its
official ARM64 compatibility-tool registration, not its complete PRoot or
compositor architecture. R17 established that the stable client channel
crosses the earlier module fatal but still stalls before `steamwebhelper`.
R18b then showed that the sibling's conventional `.steam` links reproduce
the fatal rather than fixing it. R19 and R21 reached the same stable updater
boundary through the actual `steamrtarm64/steam` executable; R20/R21 also
closed the raw-seed top-level path and symlink as explanations. R22's
diagnostic `-noverifyfiles` run reached Steam's X11 UI but exposed a concrete
`libvideo.so`/`libavutil.so.60` symbol mismatch. The next controlled step was
the smallest complete Valve media family beside `libvideo.so`, not a single
library. R24 is now closed: that family crossed the R22/R23 FFmpeg boundaries
but exposed `SDL_TryLockJoysticks@@SDL3_0.0.0` while loading `steamui.so`. The
host-only audit in [doc
459](459-nova-rootless-steam-sdl3-provider-host-audit-2026-08-11.md) confirmed
that the raw seed has no client-side SDL3 and that the completed Valve ARM64
provider exports the missing symbol. R25 then carried the completed rooted
public-beta client/runtime/layout/flag contract into rootless and crossed the
SDL3 boundary, but stopped at `bin/vgui2_s.dll`/`vgui2_s.so` resolution before
SteamUI. The audit in [doc
462](462-nova-rootless-rooted-runtime-layout-audit-2026-08-11.md) found that
the preserved rooted OOBE runtime is public-beta build `1786137466`, while
R25 staged the older host build `1785979614`; the three ARM64 files at the
failure boundary are different bytes. It also confirmed that rooted uses a
nested `/opt/nova-steam/home/.local/share/Steam` client root while rootless
flattens it to `/opt/nova-steam` and starts in `/home/nova`. R26 is predeclared
in [doc
463](463-nova-rootless-r26-rooted-device-public-tree-predeclaration-2026-08-11.md)
to change only the sanitized current rooted public tree first. R26 is now
closed in [doc
464](464-nova-rootless-r26-rooted-device-public-tree-result-2026-08-11.md):
the current rooted public client reproduced the same `vgui2_s` fatal under the
flattened rootless layout. Do not guess a `.so`-to-`.dll` alias, preload an
exploratory adapter, or patch SteamUI. The next A/B is R27, changing only the
rooted nested client-root/HOME/cwd contract while retaining the R26 public
tree and Holo closure. R27 is predeclared in [doc
465](465-nova-rootless-r27-rooted-layout-predeclaration-2026-08-11.md) to run
this layout-only A/B before any loader alias, Runtime 4, Proton, or packaging
work. R27 is now closed in [doc
466](466-nova-rootless-r27-rooted-layout-result-2026-08-11.md): the rooted
nested client-root/HOME/cwd contract reproduced the same `vgui2_s` fatal. R28
is closed in [doc
468](468-nova-rootless-r28-rooted-launch-environment-result-2026-08-11.md):
carrying the rooted SteamRT-first launch environment and library path crossed
that fatal, initialized native SteamUI/system controllers, and reached
webhelper startup. The remaining rootless boundaries are now later and
separable: the guest cannot see a Vulkan physical device without the rooted
KGSL/Turnip provider, and webhelper lacks app-owned `/dev/shm` plus a
machine-id/session-bus contract. Keep Runtime 4, Proton, and packaging
deferred while those provider/runtime prerequisites are isolated.
Record the exact source revision and require fresh SteamUI/webhelper evidence
before advancing to Runtime 4 or Proton; the
rejected setup is in [doc
441](441-nova-rootless-r18-beta-seed-setup-rejection-2026-08-11.md), the
predeclaration is in [doc
442](442-nova-rootless-r18b-steam-layout-links-predeclaration-2026-08-11.md),
and the result is in [doc
443](443-nova-rootless-r18b-steam-layout-links-result-2026-08-11.md).
The launch-contract audit is in [doc
444](444-nova-rootless-steamclienttermux-launch-contract-host-result-2026-08-11.md).

## 3. Immediate execution queue

The running implementation agent should work this queue in order:

1. **Freeze the baseline.** Keep the current direct-X11 profile unchanged for
   comparison. Add the target-derived per-run log cap/guard and capture fresh
   Steam, SteamUI, Proton, and Pressure Vessel artifacts. Do not export Steam
   authentication state.
2. **Close the native ARM64 client lifecycle gate.** R17 and R18b isolated
   the stable-channel and conventional-layout behaviors, while R19 and R21
   showed that the actual `steamrtarm64/steam` entry and the no-version
   command both stop at the updater-to-client handoff. R20/R21 ruled out the
   raw-seed top-level path and symlink as fixes. R22's diagnostic
   `-noverifyfiles` run reached Steam's X11 UI but exposed a concrete
   `libvideo.so`/`libavutil.so.60` symbol mismatch. The host audit in [doc
   453](453-nova-rootless-steam-media-provider-host-audit-2026-08-11.md)
   found the matched Valve provider in the completed client bootstrap; R23 is
   closed in [doc 455](455-nova-rootless-r23-matched-libavutil-result-2026-08-11.md)
   and proves that the complete matched media family—not only
   `libavutil.so.60`—must be staged beside `libvideo.so`. The seven-file
   family is enumerated in [doc 456](456-nova-rootless-steam-media-suite-host-audit-2026-08-11.md)
   and R24 is closed in [doc 458](458-nova-rootless-r24-matched-media-suite-result-2026-08-11.md).
   R24 crossed the complete FFmpeg family but stopped at the SDL3 symbol
   `SDL_TryLockJoysticks@@SDL3_0.0.0` before loading SteamUI. The host audit
   in [doc 459](459-nova-rootless-steam-sdl3-provider-host-audit-2026-08-11.md)
   justified the client-side provider, and R25 in [doc 461](461-nova-rootless-r25-rooted-parity-result-2026-08-11.md)
   carried the complete rooted public client closure into rootless without
   auth data. R25 crossed SDL3 but stopped at `bin/vgui2_s.dll`/`vgui2_s.so`.
   The audit in [doc 462](462-nova-rootless-rooted-runtime-layout-audit-2026-08-11.md)
   found that R25 used the older public-beta build `1785979614`, while the
   preserved rooted OOBE runtime is build `1786137466` with different ARM64
   client/module bytes and a different HOME/client-root/cwd contract. R26 is
   predeclared in [doc 463](463-nova-rootless-r26-rooted-device-public-tree-predeclaration-2026-08-11.md)
   to replay the sanitized current rooted public tree under the unchanged
   rootless contract. R26 is closed in [doc
   464](464-nova-rootless-r26-rooted-device-public-tree-result-2026-08-11.md)
   with the same `vgui2_s` fatal. R27 is closed in [doc
   466](466-nova-rootless-r27-rooted-layout-result-2026-08-11.md) with the same
   `vgui2_s` fatal. Before Runtime 4 or Proton, perform the read-only
   rooted-versus-rootless module-loader/environment audit described in the
   result. R28 was predeclared in [doc
   467](467-nova-rootless-r28-rooted-launch-environment-predeclaration-2026-08-11.md)
   and is closed in [doc
   468](468-nova-rootless-r28-rooted-launch-environment-result-2026-08-11.md):
   the environment parity crossed the `vgui2_s` boundary and reached
   SteamUI/webhelper startup. The next A/B is a driver-only parity test for
   the known-good KGSL Turnip ICD; keep the R28 client bytes, layout,
   environment, display, PRoot identity, and flags fixed. After that, test
   app-owned `/dev/shm` and then machine-id/session-bus support as separate
   experiments. Require fresh Vulkan topology, SteamUI/webhelper logs, a
   visible-frame correlation, and no residual process for each run.
   R29 is predeclared in [doc
   469](469-nova-rootless-r29-rooted-kgsl-provider-predeclaration-2026-08-11.md)
   with the exact rooted `libvulkan_freedreno.so` and ICD; it must not add
   `/dev/shm`, D-Bus, a root helper, or any Steam patch. R29 is now closed in
   [doc 470](470-nova-rootless-r29-rooted-kgsl-provider-result-2026-08-11.md):
   the app-owned provider files and ICD selector were staged correctly, but
   Steam crashed with `SIGSEGV` in updater/X11 startup before Vulkan,
   `steamsysinfo`, SteamUI, or webhelper evidence. It did not prove provider
   discovery or an app-UID KGSL denial. The single next A/B is the provider-off
   control predeclared in [doc
   471](471-nova-rootless-r30-r29-provider-off-control-predeclaration-2026-08-11.md),
   changing only `VK_ICD_FILENAMES` while keeping the provider files staged.
   R30 is now closed in [doc
   472](472-nova-rootless-r30-r29-provider-off-control-result-2026-08-11.md):
   unsetting the selector crossed R29's updater/X11 `SIGSEGV`, reached the
   native SteamUI/webhelper boundary, and reproduced the independent Vulkan,
   `/dev/shm`, and D-Bus failures. It did not enumerate Vulkan, but it makes
   the selector/provider interaction the nearest discriminant. The single
   next A/B is [doc
   473](473-nova-rootless-r31-vk-driver-files-provider-selector-predeclaration-2026-08-11.md),
   which changes only the selector to `VK_DRIVER_FILES` and keeps
   `VK_ICD_FILENAMES` plus the broader Mesa environment unset. Handle the
   Android one-time device-log consent gate before screenshots, as recorded in
   [doc 34](34-nova-runtime-harness-lifecycle.md). Do not advance to
   `/dev/shm`, D-Bus, Runtime 4, Proton, Gamescope/AHardwareBuffer, or
   packaging until R31 is classified.

   Later Thor evidence refines this sequence. R33 demonstrated that the
   app-UID rootless path can load the pinned Turnip ICD, enumerate
   `Turnip Adreno (TM) 740`, and reach `vkCreateDevice`; its crash occurred
   after device use, not at provider discovery. The rooted comparator in [doc
   486](486-ayn-thor-rooted-known-good-oobe-comparison-result-2026-08-11.md)
   reached OOBE and QR with a different compound contract: CEF GPU disabled,
   software GL, `/dev/shm`, D-Bus, root-side mounts, and lifecycle helpers.
   R38 then exposed rootless client-staging mode/ownership defects and stalled
   the official stable updater at `Client version: 0`, so it is not a
   `vgui2_s` or Vulkan result. That result is recorded in [doc
   512](512-ayn-thor-rootless-r38-libtalloc-soname-retry-result-2026-08-12.md).
   R39 is now closed in [doc
   515](515-ayn-thor-rootless-r39-cef-disable-retry-result-2026-08-12.md):
   the valid app-UID retry found the pinned Turnip ICD, enumerated Adreno 740,
   reached `vkCreateDevice`, and reproduced PRoot signal 11 before SteamUI or
   webhelper. `-cef-disable-gpu` alone did not move the boundary. The single
   next A/B is [doc
   516](516-ayn-thor-rootless-r40-steamclienttermux-proot-predeclaration-2026-08-12.md),
   which changes only the verified SteamClientTermux patched PRoot and loader.
   Keep shared `/tmp`, `/dev/shm`, D-Bus, software GL, Runtime 4, Proton,
   Gamescope/AHardwareBuffer, Mesa/WSI variables, and other sister-repository
   helpers out of R40. The historical R39 archive is no longer recoverable;
   the companion selected-tree-equivalence replay is predeclared in [doc
   517](517-ayn-thor-rootless-r40b-current-public-tree-patched-proot-predeclaration-2026-08-12.md)
   and must keep that provenance distinction explicit. R40b is now closed in
   [doc 518](518-ayn-thor-rootless-r40b-current-tree-patched-proot-result-2026-08-12.md):
   the patched PRoot still reached Turnip Adreno 740 and `vkCreateDevice`,
   then reproduced the post-device-use signal 11 before SteamUI or webhelper.
   App-UID read/write visibility of `/dev/kgsl-3d0` and the successful Vulkan
   enumeration do not support a simple DAC/SELinux-denial classification. The
   single next diagnostic is [doc
   519](519-ayn-thor-rootless-r41-patched-proot-crash-trace-predeclaration-2026-08-12.md),
   which adds only the sibling PRoot's opt-in `PROOT_CRASH_LOG=1`; keep all
   shared-`/tmp`, D-Bus, Mesa/WSI, Runtime 4, Proton, Gamescope/AHardwareBuffer,
   and other sibling helpers out of R41.

   R41 is now closed in [doc
   520](520-ayn-thor-rootless-r41-patched-proot-crash-trace-result-2026-08-12.md):
   the patched PRoot again reached Turnip Adreno 740 and the `vkCreateDevice`
   layer callstack, then reported the same guest signal 11. Its trace had
   `fault=0x0` and `ip=0`, so it was non-discriminating: it did not identify a
   PRoot translation operation or faulting mapping. The run also showed the
   Holo `VK_LAYER_MESA_device_select` layer loaded immediately before the
   boundary; app-UID `/dev/kgsl-3d0` metadata and read/write probes still do
   not support a simple DAC/SELinux-denial classification. The exact R41
   scopes were cleaned and the rooted rollback paths remained intact. The
   single next A/B is [doc
   521](521-ayn-thor-rootless-r42-nodevice-select-predeclaration-2026-08-12.md),
   which adds only the manifest-declared `NODEVICE_SELECT=1` guest variable to
   isolate that implicit layer. Keep the patched PRoot, provider, client,
   display, flags, and crash tracer fixed, and do not combine this with
   `/dev/shm`, D-Bus, Runtime 4, Proton, Gamescope/AHardwareBuffer, or any
   other sibling-repository helper.
3. **Stage an isolated official-runtime profile.** Register Proton 11 ARM64
   (`AppID 4628740`, depot `4628741`) with its declared Steam Linux Runtime 4
   ARM64 dependency (`AppID 4185400`, depot `4185401`). Preserve the
   `require_tool_appid` relationship. Do not make the current
   dependency-neutral wrapper the success criterion, and do not overwrite the
   SteamRT3C profile.
4. **Smoke-test Runtime 4 before launching a game.** Run the runtime’s
   `_v2-entry-point --verb=run -- /bin/true` or the exact equivalent exposed by
   the installed runtime through the same Holo/chroot-visible environment.
   Verify the selected runtime, bind/link cleanliness, ABI startup, and fresh
   logs.
5. **Run one first-frame game gate.** Use Geometry Wars or another current
   small library test with display, input, network, audio, and storage
   variables held constant. Change only the compatibility-tool/runtime
   selection. Require fresh Proton/DXVK/Wine/FEX logs and a screenshot; classify
   the result as game startup, Vulkan device, Vulkan/WSI surface, compositor, or
   game-level failure.
6. **Only after the gate passes**, promote the profile and take up the
   follow-on work: conventional loopback PulseAudio, `/proc/net`/route
   compatibility, complete APK/OOBE packaging, embedded X11, and
   Gamescope/AHardwareBuffer integration.

This is an A/B experiment, not a wholesale PRoot transplant. Import the
target’s proven runtime/tool contracts while leaving Nova’s display and
Android lifecycle work intact.

## 4. Staged roadmap

### Stage 0 — Versioned runtime acquisition and rollback

First-run setup is a product feature, not a manual lab prerequisite. It must
obtain a complete, versioned closure covering:

- Holo-compatible ARM64 glibc rootfs;
- native ARM64 Steam and its compatible Steam runtime;
- Gamescope/Wayland/Xwayland where selected by the profile;
- Mesa/Turnip/Vulkan and the pinned ICD;
- input and audio bridges;
- the selected Proton/FEX payloads; and
- helper binaries, APK shims, and diagnostic tools required by the profile.

The provisioner must verify hashes, root availability, architecture, free
space, and inode headroom; stage under a versioned directory; reuse existing
Steam data in place when safe; and atomically activate only after all checks
pass. Failed staging must leave the previous marker and rollback rootfs
usable. It must support resume, retry, cleanup, and rollback without copying
Steam authentication secrets.

The current implementation work is centered on the manifest/provisioner and
APK launcher. The Runtime 4 profile from Stage 2 must be added beside the
current SteamRT3C content rather than silently changing the known-good
profile.

**Stage 0 acceptance:** a clean-device run reaches QR/OOBE and signed-in
Big Picture with the current display, network, controller, and audio baseline;
the active marker points only to a fully verified runtime; and the prior
runtime can be reactivated.

### Stage 1 — Direct-X11 native Steam baseline

Use the rooted Android-managed Holo rootfs and direct Termux:X11 path to prove
the native ARM64 Steam session before adding the app-owned compositor. The
baseline needs:

- native `steamrtarm64` startup;
- persistent Linux supervision and bounded logs;
- the Steam Deck/Gamepad UI flags;
- QR/OOBE and signed-in Big Picture;
- inherited Android networking;
- the confirmed physical controller path; and
- clean start/stop of every child process.

The attached Termux:X11 kit is useful here as a display fallback and diagnostic
surface. It is not evidence that a DRM/KMS-backed Gamescope session works, and
it is not an end-user APK dependency.

### Stage 2 — Official Runtime 4 and Proton 11 ARM64 A/B

This is the active stage. Reproduce the target’s explicit manifest semantics in
a separate Nova profile:

- Proton 11 ARM64: AppID `4628740`, depot `4628741`;
- Steam Linux Runtime 4 ARM64: AppID `4185400`, depot `4185401`;
- the Proton-to-runtime `require_tool_appid` relationship; and
- the exact Steam-owned paths and tool manifests needed by Pressure Vessel.

The runtime-only test must prove that the official container starts cleanly
before a game is involved. The game test must use the same display, input,
network, audio, storage, rootfs, and Turnip variables as the baseline. A
wrapper-only launch, a stale Steam log, or a successful Proton process without
a fresh first-frame artifact is not acceptance.

**Stage 2 acceptance:** Runtime 4 executes a trivial command, Steam dispatches
the selected Proton 11 ARM64 tool with its declared dependency, and one game
produces either a first frame or a precise, fresh failure classification at
the Vulkan/WSI/compositor boundary.

### Stage 3 — Game/runtime services

After Stage 2, improve the conventional services that affect real games:

- expose loopback PulseAudio using the target’s `PULSE_SERVER=tcp:127.0.0.1:4713`
  contract and measure UI/game audio latency;
- add route or `/proc/net` compatibility only when a fresh Proton/Wine trace
  demonstrates that the container cannot discover the inherited network;
- verify Steam-mediated game launch and per-game Proton/FEX wrappers; and
- keep a small known-good game as a regression test while varying one runtime
  or service variable at a time.

The target has proven Superflight and Kingsway through Proton/FEX/DXVK/Turnip
with PulseAudio, while its Burnout path remains incomplete. Treat those as
prior-art boundaries, not promises for Nova.

### Stage 4 — App-owned presentation

Replace the desktop display with an Android app-owned `Surface`,
`ANativeWindow`, or a proven equivalent. The Nova lab has already demonstrated
important pieces:

- a three-buffer AHardwareBuffer/SurfaceControl queue with acquire/release
  fence backpressure;
- sustained 60-frame and 960×540 Wayland-SHM output through patched headless
  Gamescope in [doc 12](../10-ahb-and-harness/12-nova-gamescope-ahb-output.md); and
- an animated ARM64 X11 client crossing Xwayland, Gamescope, and the same
  Android fence loop in [doc 13](../10-ahb-and-harness/13-nova-xwayland-ahb-output.md).

The stock Holo Gamescope control reaches the KGSL Turnip device but is blocked
by its unconditional `VK_EXT_physical_device_drm` device-identity contract;
the narrow headless patch crosses that identity boundary. This remains a
useful optional research path, not a reason to block the direct-X11 runtime
A/B test.

The presentation gate must measure frame latency, buffer reuse, release fences,
rotation, lifecycle loss, and actual display cadence. The observed 1–3 visibly
changing UI frames per second is only a symptom until producer submit,
Gamescope present, Android latch/present, and release timestamps are correlated.
The pre-login SteamUI AHardwareBuffer result is recorded in [doc 15](../10-ahb-and-harness/15-nova-steam-ui-ahb-smoke.md);
hardware CEF, login, game launch, and clean lifecycle behavior remain separate
gates.

### Stage 5 — Rootless session and app-owned services

Remove root-only services one boundary at a time while keeping the rooted
profile as a fallback:

- replace privileged mounts and `binfmt_misc` assumptions with explicit
  gamescope/FEX wrappers;
- replace `/dev/uinput` with an app-owned controller socket or supported Android
  input path;
- replace system PipeWire/session services with a user session or Android
  audio bridge;
- use normal-priority scheduling before adding Android-supported performance
  hints; and
- move temporary directories, mounts, and logs into app-owned storage.

Rootless means that the Android app no longer needs a privileged helper; it
does not mean that the app owns a Linux kernel or can assume DRM/KMS access.
If a rootless user-owned display remains reliable while the full compositor
path does not, retain it as a useful fallback.

### Stage 6 — x86 Windows games

Only after native Steam UI and the selected presentation path are stable should
the app expand game compatibility. Use FEX plus ARM Proton for x86 game
payloads, never for the native ARM64 Steam client. Validate Pressure
Vessel/Bubblewrap, user namespaces, file descriptors, shared memory,
futex/semaphore behavior, and controller handoff per game. Use explicit
per-game wrappers and preserve a rooted fallback for devices that cannot
expose the required graphics or input interfaces.

## 5. Cross-cutting contracts

### Network: inherit Android’s active data path

The desired network data plane is Android connectivity, not a second
Linux-owned Wi-Fi or Ethernet setup. A normal `chroot` changes the visible
filesystem, and PRoot performs user-space path/syscall mediation; neither
creates a kernel network namespace by itself. Unless the supervisor explicitly
uses `CLONE_NEWNET`/`unshare -n`, Linux processes should create ordinary
IPv4/IPv6 sockets through Android’s existing routing, firewall, NAT, and VPN
machinery. The session must not own `wlan0`/`eth0`, run DHCP, or invent a
second route/NAT layer for normal Steam traffic.

The inherited path has four separate contracts:

1. **Namespace and routes.** Preserve the Android network namespace when
   entering the rootfs. A process does not need a Linux-named Wi-Fi/Ethernet
   device in order to use sockets; visible `/proc` and `/sys` interfaces are
   not a stable Steam-facing API.
2. **Android network selection.** Android can select a default network per
   process/UID and apply VPN or per-app restrictions. A rooted `su` helper must
   not be assumed to inherit an app-bound network merely because it shares the
   kernel namespace. The glibc rootfs also does not automatically load
   bionic’s `libnetd_client` hooks. Basic default-route connectivity may work,
   but same-namespace is not proof of same Android `Network` selection.
3. **Linux name resolution.** The glibc rootfs needs a dynamically refreshed
   `/etc/resolv.conf`/resolver path and any required proxy configuration.
   `NOVA_HOLO_NAMESERVER` is a diagnostic/bootstrap fallback, not the final
   contract.
4. **Steam’s System.Network API.** Gamepad UI network-device callbacks and
   scan controls are a UI compatibility surface, not the transport for Steam’s
   HTTP, WebSocket, TCP, or UDP sockets. “Continue with Android host network”
   means use the existing Android data path, not register fake Wi-Fi/Ethernet.

Required validation before calling networking complete:

- run a glibc resolver/HTTPS probe and native Steam bootstrap through the same
  session;
- record namespace identity for the app, supervisor, root helper, and Steam;
- test actual glibc socket/DNS selection rather than treating `ip route` or
  interface names as sufficient, and compare with an Android-native socket;
- test Wi-Fi/default-network changes, IPv4/IPv6, DNS changes, VPN/per-app VPN,
  and loss/restoration of connectivity;
- compare rootless/app-UID and rooted/`su` behavior after UID transitions;
- retain an app-side `ConnectivityManager` default-network callback for
  lifecycle/diagnostics without adding a second network request solely for
  Linux reachability; and
- use a proxy or socket relay only after direct inherited sockets fail, because
  games may require arbitrary TCP/UDP behavior.

This contract is grounded in Android’s
[`ConnectivityManager`](https://developer.android.com/reference/android/net/ConnectivityManager)
and [VPN/per-app routing model](https://developer.android.com/develop/connectivity/vpn),
Linux [network namespaces](https://man7.org/linux/man-pages/man7/network_namespaces.7.html),
PRoot’s [rootfs behavior](https://manpages.debian.org/trixie/proot/proot.1.en.html),
and AOSP’s [netd socket-marking client](https://android.googlesource.com/platform/system/netd/+/refs/heads/main/client/NetdClient.cpp).

### Lifecycle, cleanup, and artifact provenance

Every bounded run and manual session is a separate experiment. Before launch,
establish a fresh process/log baseline; on exit, interruption, or manual stop,
run the exact-scope cleanup and verify that no matching Steam, Gamescope,
webhelper, libei, uinput, mount, or bridge-socket artifact remains. See [doc
34](34-nova-runtime-harness-lifecycle.md).

Every device result must record the exact runtime, Steam seed, Proton/runtime,
Turnip driver/ICD, APK/helper artifact, presentation mode, input mode, and
relevant flags. Readiness must come from current-run logs and screenshots, not
from a familiar line in a stale Steam log. Preserve failed-run evidence until
the result is documented and committed.

### Input and audio

The current physical controller path is a baseline for direct Termux:X11, not
proof that every game, axis, rumble path, or future Gamescope profile works.
Keep those as regression checks after the first-frame gate. The audio bridge
already produces audible startup/UI sound but has delayed delivery and weak
device enumeration; improve it after the runtime comparison, with separate
Steam device-state and short game-audio evidence.

## 6. Proof paths and privilege boundaries

### Full Linux boot proof

Use Armada or PockNix on a supported Snapdragon handheld when the question is
whether the complete ARM64 Steam + Gamescope + Gamepad UI composition works
with Linux owning the kernel, DRM/KMS, seat, input, audio, and power services.
Acceptance is Steam login/Gamepad UI, continuous Gamescope output, controller
navigation, one game, and understood suspend/session cleanup. This is the
fastest composition proof, but it is not an Android app.

### Android-managed rooted proof

Keep Android booted, use a root helper to enter an app-owned glibc rootfs, and
launch native ARM64 Steam. Reuse the existing Android-compatible presentation
work from `steam-arm-findings` without assuming a normal DRM/KMS path. The
initial Android milestone is deliberately narrow: one fixed rootfs and Steam
seed, one persistent supervisor, one selected presentation path, one reliable
controller class, and clean child-process teardown.

### Privilege boundary matrix

| Capability | Full Linux boot | Rooted Android app | Rootless Android app |
|---|---|---|---|
| ARM64 Steam process | Native | Native | Native, if the user-space loader works |
| Steam Gamepad UI | Proven by Armada/PockNix | Targeted MVP | Targeted after Stage 1 |
| DRM/KMS Gamescope | Natural | Usually unavailable unless exposed by device | Not a safe assumption |
| Android presentation | Separate bridge | Rooted bridge possible | App-owned Surface/ANativeWindow or buffer copy |
| Controller input | System service | Root helper possible | App input/socket path required |
| Gamescope keyboard input | Native EIS/XTEST | libei round trip proven | Android event mapping required |
| PipeWire/session services | Systemd/logind | Rootfs plus Android bridge | User session only |
| FEX/Proton x86 games | System integration | Root helper can provide missing pieces | Explicit wrappers and user namespaces |
| ABL/kernel/firmware ownership | Yes | Android kernel remains in control | Android kernel remains in control |

## 7. Decision gates

Do not advance a stage until its artifacts exist and the result is written as a
separate experiment record.

| Gate | Required evidence |
|---|---|
| Runtime acquisition | Pinned manifest, hashes, free-space/inode checks, atomic activation marker, and rollback proof |
| Native client | ARM64 manifest/runtime revision, bootstrap logs, `steamui.so`, and `.installed` manifest |
| Steam UI | Fresh screenshot/video of login and Gamepad UI plus `steamwebhelper` rendering logs |
| Official Proton runtime | Runtime 4 trivial-command pass, exact tool/dependency selection, and clean Pressure Vessel paths |
| First game frame | Fresh Proton/DXVK/Wine/FEX logs, screenshot, and classification of the first failure or rendered frame |
| Network | Native Steam bootstrap plus glibc DNS/HTTPS through Android’s active path; IPv4/IPv6, reconnect, and UID/VPN behavior recorded |
| Audio | Steam device state, short UI/game sound evidence, route/latency measurements, and named fallback bridge |
| Android presentation | Continuous synthetic and Steam UI/game frames on the app-owned surface, frame/fence metrics, and no unexplained visible-update stall |
| Lifecycle | Clean start/stop, no stale Steam/Gamescope processes, no leaked mounts/sockets, and suspend/resume behavior |
| Rootless | Same UI/session evidence without a privileged helper, with documented fallbacks for missing APIs |

## 8. Important non-goals

- Do not begin by reverse-engineering Android Steam libraries while the native
  ARM64 Linux client is directly available.
- Do not use FEX to launch the native ARM64 Steam client; reserve it for x86
  game payloads.
- Do not treat a Gamescope process, `vkcube`, or a passing AHardwareBuffer
  transport as proof that Steam Gamepad UI or a game works.
- Do not turn the target’s patched PRoot into an unexamined Nova dependency;
  port observed contracts only when Nova’s own boundary requires them.
- Do not create a synthetic Linux Wi-Fi/Ethernet setup when Android sockets
  already provide the data plane.
- Do not require the end user to choose Wi-Fi or Ethernet inside Steam.
- Do not commit Valve runtime binaries or large OS images to the evidence
  repository; keep source notes, hashes, URLs, and reproducible procedures.

## 9. Prior-art roles and references

Use each project for the boundary it actually proves:

| Reference | What to borrow | What not to assume |
|---|---|---|
| GameNative | Android lifecycle, storage, downloads, controller, and session-management patterns | Its Android packaging does not automatically solve Nova’s Holo/SteamRT presentation boundary |
| Armada/PockNix | Full Linux ARM64 Steam session flags, Gamescope, Xwayland, input, audio, Proton, and FEX composition | Their Linux boot/DRM/KMS ownership is not the Android product model |
| SteamclientTermux | Official Runtime 4/Proton 11 ARM64 tool manifests, PulseAudio TCP, route/`/proc/net` compatibility, and bounded session logs | Its patched PRoot is not a drop-in replacement for Nova’s rooted Holo path |

The most relevant current records are:

- [doc 299: standalone runtime acquisition](299-nova-standalone-runtime-acquisition-product-requirement-2026-08-10.md);
- [doc 333: SteamclientTermux comparison](333-steamclienttermux-comparison-2026-08-10.md);
- [doc 34: runtime harness lifecycle](34-nova-runtime-harness-lifecycle.md);
- [doc 12: Gamescope AHardwareBuffer output](../10-ahb-and-harness/12-nova-gamescope-ahb-output.md);
- [doc 13: Xwayland AHardwareBuffer output](../10-ahb-and-harness/13-nova-xwayland-ahb-output.md);
- [doc 15: SteamUI AHardwareBuffer smoke](../10-ahb-and-harness/15-nova-steam-ui-ahb-smoke.md); and
- [doc 298: live physical-controller confirmation](298-nova-physical-controller-live-confirmation-2026-08-10.md).

When a technical blocker appears, search current primary project
documentation/source before treating it as a hard boundary. Record the URLs,
revisions, search date, and the exact Nova profile used in the experiment
record.
