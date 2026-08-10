# Nova Proton 11 ARM64 Steam-download experiment — 2026-08-10

Status: predeclared; device result pending.

## Question

The Nova is running Valve's native ARM64 Steam client, and the local Steam
compatibility catalog registers an official `proton_11` tool as AppID
`4628710`. The installed library currently contains Proton 10.0 and Proton
Hotfix, but no Proton 11 directory. The official Proton 11 ARM64 tool also
declares Steam Linux Runtime 4.0 - Arm64, AppID `4185400`, as its required
tool runtime.

This experiment will ask the signed-in Steam client to install Proton 11.0
(ARM64) through Steam's own `steam://install/4628710` route. If Steam leaves
the dependency unresolved, the same run may request the declared ARM64
Steam Linux Runtime dependency through `steam://install/4185400`; that
dependency request is still a Steam download, not a copied or manually
assembled runtime. No GitHub or third-party Proton archive will be copied to
the device.

The experiment does not launch a Windows game, change the selected game
compatibility tool, alter controller/input mappings, or remove Steam account,
game, shader-cache, or prefix data. It may add the two official tool
installations and their app manifests to the existing Steam library.

## Predeclared run

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

## Cleanup contract

The exact Nova/X11 cleanup helper and rootfs runtime cleanup helper will be
run before launch and again on every exit or interruption. The final process
filter must contain no matching Nova rootfs, Steam, Gamescope, Termux:X11,
compatibility-runtime, or relay process. Existing Steam data and installed
game content will be preserved.
