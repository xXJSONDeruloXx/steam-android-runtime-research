# Nova Proton 11 ARM64 Steam-download experiment — 2026-08-10

Status: phase 1 complete with an AppID correction; phase 2 predeclared.

## Question

The Nova is running Valve's native ARM64 Steam client. The local Steam
compatibility catalog registers `proton_11` as AppID `4628710`, while the
separate Steam catalog entry for Proton 11.0 (ARM64) is AppID `4628740`. The
installed library currently contains Proton 10.0 and Proton Hotfix, but no
Proton 11 directory. The official Proton 11 ARM64 tool also declares Steam
Linux Runtime 4.0 - Arm64, AppID `4185400`, as its required tool runtime.

The second phase will ask the signed-in Steam client to install Proton 11.0
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

Profile and cleanup contract are unchanged from phase 1. The source commit
for this predeclaration is `a4d6604`. The device request will be
`steam://install/4628740`; the optional dependency request is
`steam://install/4185400`. The run will begin with a new exact cleanup and
will not reuse the phase 1 Steam process, URI result, or readiness state.

## Cleanup contract

The exact Nova/X11 cleanup helper and rootfs runtime cleanup helper will be
run before launch and again on every exit or interruption. The final process
filter must contain no matching Nova rootfs, Steam, Gamescope, Termux:X11,
compatibility-runtime, or relay process. Existing Steam data and installed
game content will be preserved.
