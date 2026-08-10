# Nova Proton 11 ARM64 Steam-download experiment — 2026-08-10

Status: complete for Steam-owned installation; game launch remains a separate
experiment.

## Question

The Nova is running Valve's native ARM64 Steam client. The local Steam
compatibility catalog registers `proton_11` as AppID `4628710`, while the
separate Steam catalog entry for Proton 11.0 (ARM64) is AppID `4628740`. The
installed library currently contains Proton 10.0 and Proton Hotfix, but no
Proton 11 directory. The official Proton 11 ARM64 tool also declares Steam
Linux Runtime 4.0 - Arm64, AppID `4185400`, as its required tool runtime.

The planned second phase asked the signed-in Steam client to install Proton 11.0
(ARM64) through Steam's own `steam://install/4628740` route. If Steam leaves
the dependency unresolved, the same run may request the declared ARM64
Steam Linux Runtime dependency through `steam://install/4185400`; that
dependency request is still a Steam download, not a copied or manually
assembled runtime. No GitHub or third-party Proton archive will be copied to
the device.

The experiment does not launch a Windows game, change the selected game
compatibility tool, alter controller/input mappings, or remove Steam account,
game, shader-cache, or prefix data. It may add the two official tool
installations and their app manifests to the existing Steam library.

## Phase 1 predeclared run

Run ID: `proton-arm64-20260810T011039Z-steam-download`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, pre-run source `23bfc21`;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- signed-in native ARM64 Steam client and existing Steam library;
- direct Termux:X11 display path, with the standard software-CEF Steam
  profile unless a download-only helper needs a narrower client invocation;
- no game launch and no physical, synthetic, keyboard, pointer, touch, or
  controller input.

The run will record:

1. storage and process state before the request;
2. the exact Steam URI and AppID request(s), Steam client/content/compatibility
   logs, and connection state;
3. any new `appmanifest_*.acf`, tool directory, `toolmanifest*.vdf`, and
   dependency metadata;
4. file ownership, sizes, SHA-256 values, ELF/PE architecture headers, and
   the official tool's reported command/dependency fields;
5. the final exact-scope Nova/X11 cleanup result and a filtered process table.

Success requires a complete Steam-owned installation with a stable manifest
and the expected ARM64 Proton tool files. A URI-forwarding response without
new Steam-owned package files is a boundary result, not a successful
download. A successful download still does not prove that 198X launches;
that requires a separately predeclared compatibility-runtime experiment.

## Local catalog evidence before the run

The current device's `logs/compat_log.txt` records:

```text
Registering tool proton_11, AppID 4628710
Registering tool steamlinuxruntime_4, AppID 4183110
```

The local Steam app cache also contains the strings `Proton 11.0 (ARM64)` and
`Steam Linux Runtime 4.0 - Arm64`, while the installed appmanifest set has
only Proton 10.0, Proton Hotfix, Steam Linux Runtime 3.0, and Steam Linux
Runtime 4.0. The official Proton 11 ARM64 tool manifest is the provenance
reference for the expected `require_tool_appid 4185400` field.

## Phase 1 result and AppID correction

Run ID: `proton-arm64-20260810T011039Z-steam-download`

The first request used `steam://install/4628710` because that was the
`proton_11` entry visible in the client's compatibility log. The rootfs-aware
Steam invocation returned the normal forwarding response:

```text
Steam is already running, exiting (command line was forwarded.)
```

Steam's `console_log.txt` recorded both `ExecCommandLine` and
`ExecuteSteamURL` for `steam://install/4628710` at `2026-08-10 01:14:20`, but
the request produced no `appmanifest_4628710.acf`,
`appmanifest_4185400.acf`, new compatibility-tool directory, download queue
entry, or matching content-log line during the 30-second observation window.
The existing client continued running and was then stopped through the exact
launcher cleanup path.

This was a valid forwarding/control result, not an ARM64 Proton download. The
catalog distinction is now corrected: `4628710` is Proton 11.0, while
`4628740` is Proton 11.0 (ARM64). The SteamDB catalog records that ARM64
entry at [AppID 4628740](https://steamdb.info/app/4628740/info/). The next
phase uses only the corrected ARM64 AppID.

## Phase 2 predeclared run

Run ID: `proton-arm64-20260810T011620Z-steam-download`

Profile and cleanup contract are unchanged from phase 1. The phase was first
predeclared at `a4d6604`; the AppID correction was committed as `17bbf75`
before the device launch, so `17bbf75` is the source under test. The device
requests were `steam://install/4628740` and `steam://install/4185400`. The run
began with a new exact cleanup and did not reuse the phase 1 Steam process,
URI result, or readiness state.

## Phase 2 result

Run ID: `proton-arm64-20260810T011620Z-steam-download`

The rootfs-aware invocation of `steam://install/4628740` reached the signed-in
Steam client and returned the normal forwarding response:

```text
Steam is already running, exiting (command line was forwarded).
```

Steam presented its ARM64 Proton compatibility confirmation and the normal
install dialog. After the install was confirmed, `content_log.txt` recorded
preallocation, download, staging, and commit through Steam content servers.
The download committed successfully at `01:29:02` with no error:

```text
AppID 4628740 finished update, 1 mounted depots (BuildID 23303086) : 4628741 (8847727881196985995)
```

The Proton tool manifest was then read from the installed Steam directory and
matched the official ARM64 manifest shape:

```text
"commandline" "/proton %verb%"
"require_tool_appid" "4185400"
"use_sessions" "1"
"compatmanager_layer_name" "proton"
```

Because that manifest declares AppID `4185400`, the same signed-in Steam
client was asked to install `steam://install/4185400`. Steam presented the
ARM64 runtime confirmation and install dialog, then committed it at
`01:31:49`:

```text
AppID 4185400 finished update, 1 mounted depots (BuildID 24222035) : 4185401 (360564636299137996)
```

The stable manifests and Steam-owned package sizes are:

| AppID | Installed name | Depot / build | Downloaded | Installed | Manifest SHA-256 |
| --- | --- | --- | ---: | ---: | --- |
| `4628740` | `Proton 11.0 (ARM64)` | `4628741` / `23303086` | 776,745,120 bytes | 3,596,743,348 bytes | `cdd7f3dd0177f30e28050b96f0fd356416fb41fe7289be0c06598e964f8e52a6` |
| `4185400` | `Steam Linux Runtime 4.0 - Arm64` | `4185401` / `24222035` | 140,500,160 bytes | 426,767,282 bytes | `6963af325975b0d5f3095e605322e8864859c2a14ccabd320bfe5752d4367047` |

The package paths and architecture checks provide the important provenance
boundary:

- Proton's `toolmanifest.vdf` is at
  `/data/local/tmp/nova-holo-rootfs/opt/nova-steam/home/.local/share/Steam/steamapps/common/Proton 11.0 (ARM64)/toolmanifest.vdf`, SHA-256
  `872df60e3900b6f3f195faefa0cdbbf12c0f7dc388362aa9a4d5838be1c366bf`.
- The installed `files/bin-arm64/wine` is an ELF64 `arm64` executable, size
  71,328 bytes, SHA-256
  `3f6410e47eee7e260071c59707f28d854a28421600fa84243ec7550d5aadaee4`.
- The installed `files/bin-arm64/wineserver` is an ELF64 `arm64` executable,
  size 900,048 bytes, SHA-256
  `03ab33cb7389a8899cb78160c5b7d1bb582834f5b345a03a43d6b31810cabf5e`.
- The package contains `files/share/fex-emu/Config.json`,
  `files/share/default_pfx_arm64`, and the x86-64 PE FEX components
  `files/lib/wine/aarch64-windows/libarm64ecfex.dll` and
  `libwow64fex.dll`. Their SHA-256 values are
  `728cade374d9f52518a87f662b2dda741edfe136373a231f4bf54b0b2051227c` and
  `52c1350f8b6705249d6010393faeb0aa9918de40ffbd85903490977e57820bccb`,
  respectively.
- The dependency directory is
  `/data/local/tmp/nova-holo-rootfs/opt/nova-steam/home/.local/share/Steam/steamapps/common/SteamLinuxRuntime_4-arm64`; its `toolmanifest.vdf` declares the container-runtime entry point and is 227 bytes.

This proves that Valve's ARM64 Proton package and its declared ARM64 runtime
can be downloaded, committed, and inspected in the existing native Steam
library. It does not yet prove that FEX translates 198X or that any Windows
game reaches a frame.

The current Steam process was started before the two new tools existed. Its
fresh-start compatibility log still registered the ordinary `proton_11`
AppID `4628710` and ordinary `steamlinuxruntime_4` AppID `4183110`; it did not
register `4628740` or `4185400` during this run. That is a client catalog
refresh/selection boundary for the next experiment, not a failed download.
No game compatibility tool was selected and no game was launched in this
run.

The host evidence bundle is
`/tmp/proton-arm64-20260810T011620Z-steam-download`; it includes the two
confirmation-dialog screenshots, URI transcripts, full selected Steam logs,
manifests, architecture output, cleanup records, and `evidence-sha256.txt`.

The exact preflight and postflight helpers returned
`nova_x11_cleanup=pass` and `nova_runtime_cleanup=pass`. The final filtered
process table was empty, no rootfs-related mount remained, and the X11 and
rootfs temporary socket searches both returned zero. With no Nova runtime
process alive, 301 stale Steam IPC socket files matching the exact
`SingletonSocket` and `steam_chrome_shmem_uid501_spid*` patterns were removed
from the rootfs `/tmp`; no Steam account, game, shader-cache, prefix, or
installed package data was removed. Post-cleanup `/data` reported 75,567,964
KiB available.

## Decision boundary

The requested Steam-side prerequisite is now complete. The next bounded
experiment should start a fresh Steam client so it can rediscover the newly
installed tool manifests, verify that Steam exposes Proton 11.0 (ARM64) as a
selectable compatibility tool, and then issue one 198X launch request through
that tool. That run must separately capture pressure-vessel/FEX/Wine process
creation, Proton logs, game lifetime, and a correlated first frame. No manual
Proton archive, copied runtime, or guessed compatibility mapping was used in
this installation run.

## Cleanup contract

The exact Nova/X11 cleanup helper and rootfs runtime cleanup helper were run
before launch and again on exit. The final process filter contained no
matching Nova rootfs, Steam, Gamescope, Termux:X11, compatibility-runtime, or
relay process. Existing Steam data and installed game content were preserved.
