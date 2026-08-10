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

## Phase 2 result

The valid retry created session `20260810T021555Z-30367`. After restart,
Steam processed the local manifest and logged:

```text
Registering tool proton11_arm64, AppID 0
Mapping AppID 1086010 to tool "proton11_arm64" with priority 250
Loaded manifest for tool proton11_arm64.
```

This proves that the compatibility mapping mechanism works. The 198X launch
also reached `StartSession` with session
`58daf610a329773a`, and the Steam UI displayed the real controller-translation
interstitial for 198X. After the interstitial was dismissed with one
synthetic relay A event, Steam advanced through `CreatingProcess` and failed
with `AppError_51`.

The failure is a dependency-catalog boundary, not an untested launch:

```text
Tool 4185400 "" is unknown for appID 1086010.
Tool 0 "Proton 11.0 (ARM64)" has a dependency on tool 4185400: dependent tool cmdline wrap failed.
```

No Proton, pressure-vessel, Wine, FEX, or game process appeared, and no game
frame was produced. The installed Steam Linux Runtime 4.0 - Arm64 package is
present at `SteamLinuxRuntime_4-arm64`, but its official `toolmanifest.vdf`
does not provide a custom compatibility-tool AppID. A second local alias for
that runtime would therefore also register as AppID 0 and would not satisfy
the Proton manifest's hard dependency. The original `proton_hotfix` mapping
was restored and the transient Proton alias removed after the run; the Steam
downloaded Proton and runtime packages were preserved.

Run artifacts are retained under
`/tmp/proton-arm64-20260810T021453Z-198x-alias-retry/`, including the fresh
compatibility registration, `StartSession`, `AppError_51`, process captures,
and the pre/post-interstitial 1280x960 screenshots.

## Phase 3 predeclared run

Run ID: `proton-arm64-20260810T022307Z-198x-dependency-neutralized`

The next run will keep the Steam-downloaded package read-only and create a
small wrapper directory under `compatibilitytools.d/proton-11-arm64`:

1. symlink every top-level Proton package entry except `toolmanifest.vdf` to
   the installed Steam package;
2. copy the package's `toolmanifest.vdf` into the wrapper and remove only its
   `require_tool_appid 4185400` line, preserving a before/after hash; and
3. point the custom `proton11_arm64` compatibility manifest at that wrapper,
   map 198X to it, and repeat the fresh restart and launch sequence.

This isolates the dependency resolver from the Proton files and avoids a
multi-gigabyte copy. The run must capture whether Steam reaches the Proton
entry point, the exact runtime/container command, Wine/FEX process state, and
the first game frame. It must restore `proton_hotfix`, remove the wrapper, and
run the exact cleanup helpers before any further hypothesis.

### Discarded phase 3 setup

The first wrapper setup was discarded before Steam launch. Android's `sed`
did not match the tabbed `require_tool_appid` line, so the wrapper and the
Steam package had identical `toolmanifest.vdf` hashes. No Steam process was
started against that wrapper; it was removed and `proton_hotfix` was restored.
The setup helper now removes the exact `4185400` line with a literal AppID
match.

## Phase 3 retry predeclared run

Run ID: `proton-arm64-20260810T022711Z-198x-dependency-neutralized-retry`

The retry required a differing wrapper-manifest hash and a direct
no-`4185400` verification before `am start`. With that preflight passing, it
repeated the mapped 198X launch and captured the same runtime/frame gates.

## Phase 3 result

The fresh launcher session was `20260810T022841Z-9162`. Readiness passed for
the direct Termux:X11 profile at 1280x960, with the normal Steam UI visible.
The wrapper preflight preserved the original installed Proton package hash
(`872df60e3900b6f3f195faefa0cdbbf12c0f7dc388362aa9a4d5838be1c366bf`) and
produced a distinct wrapper-manifest hash
(`ca2f1ec4ef6cf41cd11ab1899d13d1cc1d3278b406fbe13341c6052f75f8a9cb`). The
wrapper dependency scan contained neither `require_tool_appid` nor `4185400`.
The compatibility-tool manifest hash was
`9eed42bb7ac471fb33197f98cf397e0b8bed92fa6f9c310db97d8697d6310d4d`.

After the fresh restart, the compatibility log registered the alias and
loaded the dependency-neutralized wrapper:

```text
Registering tool proton11_arm64, AppID 0
Mapping AppID 1086010 to tool "proton11_arm64" with priority 250
Loaded manifest for tool proton11_arm64.
Command prefix for tool 0 "Proton 11.0 (ARM64)" set to:
  "'/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64'/proton run "
```

The 198X launch began at `2026-08-10 02:31:53` with compat session
`2c8e8577960c8b92`. Steam reached the game command and selected the wrapper:

```text
AppID 1086010 adding PID 11554 as a tracked process
  .../compatibilitytools.d/proton-11-arm64/proton waitforexitandrun
  .../steamapps/common/198X/198X.exe
```

This clears the earlier missing-runtime catalog failure, but it is not yet a
working game launch. The tracked wrapper exited with code `0` almost
immediately, its only tracked child exited with `-1`, and no Proton, Wine,
Wineserver, FEX, pressure-vessel, or game process was present in the 12-second
capture. Steam consequently marked the action `Completed`/`WaitingGameWindow`
without a game window. `steam-after-applaunch-12s.png` shows the 198X library
page, not a game frame.

The evidence now points at the wrapper's early execution environment or Proton
entry-point behavior, rather than the Steam compatibility dependency resolver.
The wrapper has not been promoted into the one-click APK. The next bounded
experiment should execute the same wrapper directly inside the client mount
namespace with the Steam launch environment and capture its stderr plus the
first child-process decision, changing no game files or prefixes.

Run artifacts are retained under
`/tmp/proton-arm64-20260810T022711Z-198x-dependency-neutralized-retry/`,
including the wrapper hashes, fresh compatibility registration, launch
command, process captures, compatibility/game-process logs, launcher log, and
1280x960 screenshots. The exact X11 and runtime cleanup helpers both passed.
The cleanup then restored AppID `1086010` to `proton_hotfix` and removed only
the transient wrapper and staging files. Two stale Steam singleton/shmem
sockets were removed by their exact paths after Steam exited; the final
process, mount, and rootfs temporary-socket checks were empty. Steam account,
game, prefix, shader-cache, and installed-tool data were preserved.

## Phase 4 predeclared run

Run ID: `proton-arm64-20260810T023604Z-direct-entrypoint`

The next bounded diagnostic will leave AppID `1086010` on its restored
`proton_hotfix` mapping and will not ask Steam to launch the game. It will
start a fresh direct Termux:X11 client namespace, recreate only the transient
dependency-neutralized Proton 11 ARM64 wrapper, and invoke that wrapper
directly with the Steam compatibility environment for 198X:
`STEAM_COMPAT_DATA_PATH`, `STEAM_COMPAT_CLIENT_INSTALL_PATH`,
`STEAM_COMPAT_INSTALL_PATH`, `STEAM_COMPAT_LIBRARY_PATHS`, `SteamAppId`, and
`SteamGameId`. `PROTON_LOG=1` and an explicit temporary log directory will
capture Proton's own early-exit path. The run will collect the direct command
status, stderr/Proton log, child-process tree, and any Wine/FEX evidence, then
remove only the wrapper and execute the exact X11/runtime cleanup helpers.
It will not modify the 198X files, compatdata, prefix, or Steam account state.

## Phase 4 result

The fresh launcher session was `20260810T023743Z-15368`; readiness passed for
the direct Termux:X11 profile at 1280x960. The direct command used an isolated
scratch compatdata/log directory under
`/tmp/nova-proton-11-direct-20260810T023604Z`, so the installed 198X prefix
was not selected.

The wrapper failed before Python/Proton started:

```text
timeout: failed to run command
  '/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64/proton':
  No such file or directory
```

The wrapper's `proton` symlink resolved to
`/data/local/tmp/nova-holo-rootfs/opt/nova-steam/home/.local/share/Steam/steamapps/common/Proton 11.0 (ARM64)/proton`.
That absolute target exists from Android's view of the rootfs, but it is
outside the chroot-visible namespace; inside the chroot the target is
therefore absent. No Proton log, Wine/Wineserver/FEX process, or game frame
was produced. This explains the phase 3 early exit and identifies a harness
bug in the wrapper setup, not a Proton 11 ARM64 runtime failure.

The run artifacts are retained under
`/tmp/proton-arm64-20260810T023604Z-direct-entrypoint/`, including the fresh
launcher evidence, wrapper hashes, direct command output, symlink/readlink
captures, scratch-state check, and cleanup evidence. The exact X11 and runtime
cleanup helpers both passed. The transient wrapper, scratch directory, and
staging files were removed; two stale Steam singleton/shmem sockets were
removed by their exact paths after Steam exited. Final process, mount, and
rootfs temporary-socket checks were empty. AppID `1086010` remained on
`proton_hotfix`, and no game, prefix, shader-cache, or account data was
changed.

The next implementation change must make wrapper links chroot-visible (for
example, relative links rooted at the installed Proton package), add a setup
fixture that asserts the wrapper `proton` target exists from inside the
rootfs, and repeat the Steam launch only after that fix is committed and
pushed.

## Phase 5 predeclared run

Run ID: `proton-arm64-20260810T024222Z-chroot-visible-wrapper-retry`

The fixed wrapper helper is now committed and pushed. This retry will deploy
that helper, require its relative-link and chroot-visible-target checks to
pass, preserve the current `proton_hotfix` mapping, and then map only AppID
`1086010` to `proton11_arm64` for a fresh Steam restart. It will launch 198X
and capture the compatibility command, Proton/Wine/FEX/pressure-vessel process
tree, game-process lifetime, Proton logs, and a same-run screen capture. The
original config mapping will be restored and the transient wrapper/staging
files removed through the exact cleanup contract on every exit.

## Phase 5 result

The fixed helper passed both new gates before Steam started: the wrapper
`proton` link was relative (`../../steamapps/common/Proton 11.0 (ARM64)/proton`),
and a real `chroot` check reported `chroot_proton=pass` and
`chroot_wine=pass`. The fresh launcher session was
`20260810T024339Z-20250`, with readiness passing at 1280x960.

Steam registered and selected the ARM64 alias after restart, including:

```text
Posting queued tool registration callback 0 proton11_arm64
Posting queued app config changed callback 1086010
Command prefix for tool 0 "Proton 11.0 (ARM64)" set to:
  "'/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64'/proton run "
```

The 198X launch reached compat session `730bf06aaadfd5b` at
`2026-08-10 02:44:37`. Steam emitted the expected Proton 11 ARM64 command,
and `gameprocess_log.txt` recorded the wrapper plus eleven child PIDs
(`22021`, `22022`, `22024`, `22025`, `22027`, `22030`, `22032`, `22035`,
`22044`, `22050`, and `22056`). This is a substantial advance over the
broken-wrapper run: the chroot-visible Proton entry point ran far enough to
create the expected multi-process launch tree. The short capture did not
retain child command lines, so it is not yet proof of a persistent Wine/FEX
game process. All children exited by `02:44:41`; the
wrapper returned `0` while its children returned `-1`, and Steam marked the
action `Completed`/`WaitingGameWindow`. No persistent game process or game
frame existed in the 15-second capture; the screenshot returned to the Steam
UI rather than showing 198X.

The run touched the installed `steamapps/compatdata/1086010` prefix while
initializing Proton state: `pfx`, `tracked_files`, `config_info`, `version`,
and `proton-fex-config.json` carried the run's `02:44` timestamps. Those files
were preserved; no compatdata, game, shader-cache, or account data was
deleted or rolled back. The failure is now below compatibility registration
and wrapper resolution, in the short-lived Wine/FEX/game startup path.

Artifacts are retained under
`/tmp/proton-arm64-20260810T024222Z-chroot-visible-wrapper-retry/`, including
the chroot-link checks, fresh mapping, launch command, process/log captures,
and screenshot. The exact X11 and runtime cleanup helpers passed. The
original `proton_hotfix` mapping was restored, the transient wrapper/staging
files were removed, and the two stale Steam singleton/shmem sockets left by
Steam were removed by exact path. Final process, mount, and rootfs
temporary-socket checks were empty.

## Phase 6 predeclared run

Run ID: `proton-arm64-20260810T024718Z-subsecond-process-capture`

The next retry will repeat the fixed chroot-visible wrapper and
`proton11_arm64` mapping from a fresh baseline, but will poll the Android
process table every 250 ms from immediately before the `-applaunch` relay
through the first five seconds. Each poll will retain full command lines so
the short-lived child sequence can be attributed to Wine, FEX, pressure-vessel,
the Windows executable, or an early helper failure. It will also capture the
same-run Steam compatibility/game-process logs and screenshots. The mapping,
wrapper, and Nova session will be removed/rolled back through the exact
cleanup contract afterward; the existing `compatdata/1086010` state will be
preserved rather than reset.

## Phase 6 result

The fresh launcher session was `20260810T024816Z-24668`; readiness passed at
1280x960. Steam registered the alias and created compat session
`fdb10568c9e0ad03` for 198X at `02:49:14`. The 250 ms process snapshots
captured the following live chain at `process-05.txt`:

```text
pw-audio-namespace -- .../reaper SteamLaunch AppId=1086010 -- .../proton-11-arm64/proton waitforexitandrun .../198X.exe
reaper SteamLaunch AppId=1086010 -- .../proton-11-arm64/proton waitforexitandrun .../198X.exe
python3 .../proton-11-arm64/proton waitforexitandrun .../198X.exe
wine c:\windows\system32\steam.exe .../198X.exe
wineserver
C:\windows\system32\wineboot.exe --init
C:\windows\system32\services.exe
C:\windows\system32\winedevice.exe
C:\windows\system32\plugplay.exe
C:\windows\system32\svchost.exe -k LocalServiceNetworkRestricted
```

This is the first direct live-process proof that Proton 11 ARM64 and Wine
are executing on the Nova. It also narrows the remaining blocker: no process
whose command line is the 198X executable appeared, and no game frame was
produced. The Wine bootstrap tree disappeared by the next few samples;
`gameprocess_log.txt` records the wrapper returning `0` and all child PIDs
returning `-1` at `02:49:17`. Steam marked the action `Completed` without a
game window. `screen-04.png` shows Steam's delaying-launch/controller-layout
interstitial, while `screen-08.png` is back on the 198X library page; neither
is game-frame evidence. No Proton log file was emitted by the Steam launch.

The next useful distinction is therefore whether 198X can start when Proton
is asked to run its executable directly, bypassing the Windows Steam relay,
or whether the failure is in the installed game's own startup. That should
be a new bounded run with a fresh process capture and no game-file changes.

Artifacts are retained under
`/tmp/proton-arm64-20260810T024718Z-subsecond-process-capture/`, including all
250 ms process tables, timestamps, live screenshots, fresh Steam logs, and
mapping evidence. The exact X11 and runtime cleanup helpers passed. The
original `proton_hotfix` mapping was restored, the wrapper/staging files were
removed, and the two stale Steam singleton/shmem sockets left by Steam were
removed by exact path. Final process, mount, and rootfs temporary-socket
checks were empty; the existing compatdata state was preserved.

## Phase 7 predeclared run

Run ID: `proton-arm64-20260810T025147Z-direct-198x-entrypoint`

This run will keep the Steam client mapping restored to `proton_hotfix`,
recreate the fixed chroot-visible Proton 11 ARM64 wrapper, and invoke
`proton runinprefix` directly on the installed
`steamapps/common/198X/198X.exe`. That bypasses the Windows Steam relay seen
in Phase 6 while retaining the actual 198X compatdata path. It will set
`PROTON_LOG=1` with a run-specific log directory, poll the process table
through startup, capture the screen, and inspect whether a real 198X process
or frame appears. Proton may update the existing prefix's normal startup
metadata; no game files, installed Steam packages, or account data will be
removed. The wrapper and X11/runtime session will be cleaned afterward.

## Phase 7 result

The fresh launcher session was `20260810T025223Z-28667`; readiness passed at
1280x960. With the fixed wrapper visible inside the chroot, the direct command
returned `29` and its live process capture showed:

```text
python3 .../proton-11-arm64/proton runinprefix .../198X.exe
wine .../steamapps/common/198X/198X.exe
wineserver
C:\windows\system32\wineboot.exe --init
C:\windows\system32\winedevice.exe
```

The Proton log identifies the game-level failure precisely. Proton 11 loaded
the native x86-64 Windows binary and FEX's ARM64EC thunk library:

```text
Loaded L"S:\\common\\198X\\198X.exe" ...: native
Loaded L"C:\\windows\\system32\\libarm64ecfex.dll" ...: builtin
A 24 Couldn't detect CPU features
... code=c000001d (EXCEPTION_ILLEGAL_INSTRUCTION)
... L"libarm64ecfex.dll" + 0x175f50
err:seh:NtRaiseException Unhandled exception code c000001d
```

Thus 198X itself reaches FEX translation, but aborts before creating a game
window. This is no longer a Steam compatibility-tool, Windows Steam relay,
X11, or surface-rendering blocker. The host CPU inventory reports the Nova's
Kalama ARM64 cores and normal ARM feature flags, so the next investigation
should focus on why this Proton/FEX build cannot detect or safely expose the
required CPU feature set in this Android rootfs, rather than changing the
Gamescope/AHB path.

The Proton log and all direct-run artifacts are retained under
`/tmp/proton-arm64-20260810T025147Z-direct-198x-entrypoint/`. The exact X11 and
runtime cleanup helpers passed. The transient wrapper, staging files, and
run-specific Proton log directory were removed; the existing 198X compatdata
prefix and installed game/package data were preserved. Final process, mount,
and rootfs temporary-socket checks were empty.

## Phase 8 predeclared run

Run ID: `proton-arm64-20260810T030240Z-arm64ec-registry-key`

The direct Proton log identifies the next boundary in the bundled
`FEX-2604-97-ga04b024` ARM64EC module: its Windows-side CPU feature helper
opens `HKLM\\Hardware\\Description\\System\\CentralProcessor\\0` and
terminates with `Couldn't detect CPU features` when that key is absent. The
Nova prefix currently has no `CentralProcessor` key. This run will test that
specific missing-key hypothesis, without inventing register values or changing
the game binary.

After a fresh exact cleanup, the run will recreate the chroot-visible Proton 11
ARM64 wrapper, map only AppID `1086010` to `proton11_arm64`, and snapshot the
198X prefix's `system.reg`, `user.reg`, and `userdef.reg` byte hashes. It will
create only the empty registry key
`HKLM\\Hardware\\Description\\System\\CentralProcessor\\0`, invoke the
same direct `proton runinprefix` entry point on the installed
`steamapps/common/198X/198X.exe`, and retain a fresh Proton log, process
polling, and screen capture. The three registry files will then be restored
byte-for-byte from the snapshot after all Wine/FEX processes exit; the
transient wrapper, mapping, log directory, and prefix modification will not be
left installed. A passing result first requires the FEX diagnostic to
disappear; a game frame remains the stronger success gate.

## Cleanup contract

The exact Nova/X11 cleanup helper and rootfs runtime cleanup helper must run
before launch and on every exit or interruption. The final process filter must
contain no matching Nova rootfs, Steam, Gamescope, Termux:X11,
compatibility-runtime, or relay process. Existing Steam account, game,
shader-cache, prefix, and installed tool data must be preserved.
