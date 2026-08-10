# Nova Proton 11 ARM64 198X tool-discovery experiment — 2026-08-10

Status: phase 1 complete; ARM64 package installed but not exposed by the
fresh Steam compatibility-tool catalog.

## Question

Steam has now downloaded Valve's Proton 11.0 (ARM64) package, AppID
`4628740`, and its required Steam Linux Runtime 4.0 - Arm64 package, AppID
`4185400`. The installed 198X configuration still maps AppID `1086010` to
`proton_hotfix`:

```text
"CompatToolMapping"
{
    "1086010"
    {
        "name" "proton_hotfix"
        "config" ""
        "priority" "250"
    }
}
```

The user requires 198X to use Proton 11 ARM64. Before changing this mapping,
start a fresh native ARM64 Steam client and record the exact compatibility-tool
name Steam registers for the newly installed AppID. The name must come from
the current client/tool manifests or Steam's own selection state; it will not
be guessed from the directory name or manually invented.

This phase did not launch 198X or modify the selected compatibility tool. It
restarted the normal one-click Steam session and established a fresh
registration baseline. The next phase will set AppID `1086010` to the ARM64
Proton tool through a reversible compatibility mapping change, restart Steam
again, and then attempt the game launch.

## Predeclared run

Run ID: `proton-arm64-20260810T014513Z-tool-discovery`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`, ABI `arm64-v8a`;
- branch `feat/nova-one-click-launcher`, source commit `2da5475`;
- APK package `com.xjsonderulo.steamandroid.novalab`, installed APK SHA-256
  `0ff3b753b113e0a5c9ecadd7b1f88a66113b1891ec7e698fbe5eaa1950fa18f8`;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- direct Termux:X11 Steam path, software CEF, fullscreen, 1280x960;
- installed Proton 11 ARM64 directory and Steam Linux Runtime 4 ARM64
  directory are read-only discovery targets;
- no game launch, compatibility mapping change, physical input, synthetic
  input, keyboard input, pointer input, or touch input.

The run will:

1. execute the exact preflight cleanup and capture fresh process/log baselines;
2. launch the one-click test APK's Steam session;
3. capture the new session's Steam `compat_log.txt`, `client.log`, launcher
   log, and `config.vdf` compatibility mapping;
4. record every newly registered tool line for AppIDs `4628740` and `4185400`
   and inspect the corresponding `toolmanifest.vdf` files; and
5. stop through the exact cleanup helpers and verify processes, mounts, and
   X11/rootfs temporary sockets are absent.

Success means the fresh client registers the ARM64 Proton package with an
explicit usable tool name. A stable installation without a fresh registration
is a tool-catalog lifecycle boundary, not a game-launch result.

## Discarded harness attempts

The first launch attempt was discarded before interpreting any Steam result.
The preflight left the prior `/data/local/tmp/nova-android-launcher/ready`
marker in place, so a one-second readiness poll observed stale state before
the new launcher had written its session. The actual new session was
`20260810T015120Z-25822`; it was captured only as a control artifact and then
terminated through the exact helpers. No compatibility registration or game
result from that attempt is used here.

The following start was also discarded: the APK Activity had not been
force-stopped after that teardown, so Android reported that the intent was
delivered to the already-running top-most Activity and no new runtime was
created. The retry below therefore force-stops the APK after every discarded
session and requires both a missing old marker before launch and a new session
ID after launch.

## Phase 1 retry predeclared run

Run ID: `proton-arm64-20260810T015323Z-tool-discovery-retry`

The retry kept the original profile and source commit. It added an explicit
APK force-stop, removes only the prior launcher state markers (`ready`,
`client-active`, `server-token`, `client-token`, and `session`), records the
pre-launch compatibility-log line count, and accepts readiness only after the
session ID and launcher log belong to this retry. It will not launch 198X or
change `CompatToolMapping`.

## Phase 1 result

The retry created the fresh launcher session
`20260810T015442Z-30824`. Its launcher log reported the expected direct
Termux:X11 profile: software CEF, `DISPLAY=:0`, 1280x960 fullscreen,
gamepad relay `event9`, and `nova_launcher_ready=pass`. The Steam UI was
visible and signed in in `steam-after-45s.png`; this is display evidence only,
not a Gamescope or game-frame result.

The fresh compatibility log began at `2026-08-10 01:55:03` and registered the
ordinary tools (`proton_11` AppID `4628710`, `steamlinuxruntime_4` AppID
`4183110`, and the other existing entries), but it contained no registration
for Proton 11.0 (ARM64) AppID `4628740`, Steam Linux Runtime 4.0 - Arm64
AppID `4185400`, or an ARM64-specific tool name. The installed ARM64
`toolmanifest.vdf` is present and names `require_tool_appid` `4185400`; the
package itself contains native `files/bin-arm64/wine` and `wineserver`, FEX
ARM64EC/WOW64 files, and its ARM64 FEX configuration. Thus the package is
installed, but the current client did not add it to its active compatibility
catalog after restart.

The run did not change the 198X mapping: AppID `1086010` remained
`proton_hotfix`. Ancillary synthetic UI captures were taken after the fresh
Steam evidence to inspect the existing game-selection path; they are not
used as physical-controller or game-launch evidence.

Run artifacts are retained under the host evidence directory
`/tmp/proton-arm64-20260810T015323Z-tool-discovery-retry/`, including
`launcher.log`, `compat_log.txt`, `steam-after-45s.png`, the fresh-state
checks, and the teardown captures. The exact cleanup helpers then reported
`nova_x11_cleanup=pass` and `nova_runtime_cleanup=pass`; a final process
filter was empty and the rootfs temporary socket count was zero. Steam
account, game, prefix, shader-cache, and installed-tool data were preserved.

## Decision boundary

The next run may change only the 198X compatibility mapping after first
recording the exact mapping key/path used for the installed ARM64 package. It
must preserve the current `proton_hotfix` mapping as a rollback artifact, use
a fresh Steam process, and capture the resulting `StartSession`,
Proton/Wine/FEX/pressure-vessel process tree, Proton logs, game lifetime, and
a frame correlated to the same run ID. If Steam rejects the mapping or still
does not expose the ARM64 tool, that is a documented catalog boundary and the
run must be cleaned before any alternate installation alias is considered.

## Phase 2 predeclared run

Run ID: `proton-arm64-20260810T020843Z-198x-alias`

The built-in catalog boundary requires a separate, explicitly named alias
experiment. Before launch, preserve the current `config.vdf` and its
`proton_hotfix` value as a rollback artifact. Then create only this transient
registration under Steam's user-owned `compatibilitytools.d` directory:

```text
compat_tools/proton11_arm64
  install_path = /opt/nova-steam/home/.local/share/Steam/steamapps/common/Proton 11.0 (ARM64)
  display_name = Proton 11.0 (ARM64)
  from_oslist = windows
  to_oslist = linux
```

This uses the Steam-downloaded Proton files in place; it does not copy or
modify the Proton package and it does not alter the required-runtime manifest.
The format follows Valve's documented local compatibility-tool layout in the
[Proton README](https://github.com/ValveSoftware/Proton#using-a-local-build-of-proton-with-steam).
The alias name is intentionally distinct from the absent built-in catalog
name, so a successful result is attributable to this registration shim.

The run will restart Steam from a fresh baseline, confirm that the new tool is
registered, set AppID `1086010` to `proton11_arm64`, and launch 198X. It will
capture the post-change mapping, compatibility log, `StartSession`, process
tree, Proton/Wine/FEX/pressure-vessel evidence, game lifetime, and a fresh
screen capture. It will then restore the original mapping and remove only the
transient alias unless the result is promoted into the one-click launcher.
No game success will be claimed from the Steam UI alone: a game process and a
frame from the same run are required.

### Discarded phase 2 startup

The first phase 2 `am start` returned `LaunchState: COLD`, but the launcher
rejected the request with `nova_launcher_start=fail
reason=existing_nova_runtime` before creating a new session marker. A
post-failure process filter was empty and the rootfs temporary socket count
was zero. The attempt therefore produced no Steam, compatibility, or game
result and is retained only as a harness-discard artifact under
`/tmp/proton-arm64-20260810T020843Z-198x-alias/`.

## Phase 2 retry predeclared run

Run ID: `proton-arm64-20260810T021453Z-198x-alias-retry`

The retry uses the same alias and mapped configuration, but gives the
launcher a fresh state directory baseline, force-stops the APK, runs both
exact cleanup helpers, verifies the filtered process set and rootfs socket
count immediately before `am start`, and clears the old launcher log. It
accepts evidence only from a new session ID and new launcher log. The retry
will be cleaned through the same helpers even if Steam fails before readiness.

## Cleanup contract

The exact Nova/X11 cleanup helper and rootfs runtime cleanup helper must run
before launch and on every exit or interruption. The final process filter must
contain no matching Nova rootfs, Steam, Gamescope, Termux:X11,
compatibility-runtime, or relay process. Existing Steam account, game,
shader-cache, prefix, and installed tool data must be preserved.
