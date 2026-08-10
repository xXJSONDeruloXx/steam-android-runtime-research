# Termux:X11 198X command-line launch experiment — 2026-08-09

Status: complete; the command reached the running Steam client, but no
compatibility-runtime child was created.

## Question

The signed-in Steam UI and the installed 198X content are healthy, but the
previous UI launch failed before Proton/Wine because the ARM64 runtime tried to
execute an x86-64 `pressure-vessel-wrap` and received `Exec format error`.
Can a fresh native ARM64 Steam client accept a direct `-applaunch 1086010`
request and expose a more precise game-session boundary without using the
Steam UI or any controller/button input?

This is a no-input lifecycle experiment. It does not change Gamescope,
AHardwareBuffer, Termux:X11 preferences, networking, audio, or controller
handling. The existing installed game and account state are retained.

## Predeclared run

Run ID: `game-20260810T004435Z-198x-cli-launch`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- APK `com.xjsonderulo.steamandroid.novalab`, source commit `4c36ee1`;
- APK SHA-256:
  `0ff3b753b113e0a5c9ecadd7b1f88a66113b1891ec7e698fbe5eaa1950fa18f8`;
- normal `run_steam_session=true` launcher path;
- direct Termux:X11 display `:0`, software Steam/CEF, audio bridge disabled;
- restored baseline Termux:X11 preferences; no preference mutation in this
  run;
- installed title: 198X, AppID `1086010`, executable
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/198X/198X.exe`;
- no physical, synthetic, keyboard, pointer, touch, or controller input.

After the fresh Steam session reaches its normal UI readiness boundary, the
run will issue exactly one rooted, UID-matched command-line request equivalent
to:

```text
/system/bin/chroot /data/local/tmp/nova-holo-rootfs \
  /usr/bin/env -i PATH=/usr/bin:/bin HOME=/opt/nova-steam/home USER=steam \
  LOGNAME=steam DISPLAY=:0 XDG_RUNTIME_DIR=/tmp/nova-steam-runtime \
  LANG=C LC_ALL=C \
  /usr/bin/timeout 120 /usr/bin/setpriv --reuid=501 --regid=20 \
  --groups=1005 \
  /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam \
  -applaunch 1086010
```

The exact command, exit status, stdout/stderr, fresh Steam game-process logs,
and any Proton/Wine/pressure-vessel descendants will be captured. If the
command cannot reach the already-running Steam client from the ordinary
rootfs namespace, that is a launcher/IPC boundary result; it will not be
silently retried through a different path in the same run.

## Device result

The fresh run reached the normal Steam UI boundary before issuing the command.
The exact command returned exit status 0 with this terminal result:

```text
CProcessEnvironmentManager is ready, 5 preallocated environment variables.
WARNING: setlocale('en_US.UTF-8') failed, using locale: 'C'. International characters may not work.
Steam is already running, exiting (command line was forwarded).
```

The request did reach the existing client asynchronously: `webhelper_js.txt`
recorded `LaunchGameAction: OnGameActionUserRequest: 1086010 LaunchApp
ShowInterstitials` at `00:48:36`, and `compat_log.txt` recorded
`StartSession: appID 1086010` at `00:48:35`. However, the fresh
`gameprocess_log.txt` tail contained no new AppID 1086010 process entry after
this run's `00:46:32` Steam-client baseline, and the post-observation process
table contained no `steam-launch-wrapper`, `pressure-vessel`, Proton, Wine, or
198X process. The Steam client remained alive, so the failure is after command
dispatch and before compatibility-runtime child creation.

The installed artifacts were unchanged and were recorded for provenance:

- `198X.exe`: 650,752 bytes, SHA-256
  `ce03bffd959a5153fddf2af1565700ce7d29d7ca67028e86e097ae67f08c8730`;
- both installed `pressure-vessel-wrap` copies: 868,056 bytes, SHA-256
  `d591669878339b21bffeaa68c8ad7c2b5d51d01f91cabe1c87e6c3e7c2aeb554`;
- `readelf` identified each pressure-vessel wrapper as ELF64
  `Advanced Micro Devices X86-64`; the game executable is not an ELF file.

This run therefore passes command dispatch, fails compatibility-runtime
startup, and does not reach a live game process or a game-frame check. It did
not add a new `Exec format error` line because no wrapper child was created;
the earlier UI-driven launch result in [198](198-termux-x11-198x-game-launch-result-2026-08-09.md)
still provides that direct pressure-vessel architecture error. No screenshot
was treated as evidence because Steam never produced a candidate game frame.

The host evidence bundle is `/tmp/game-20260810T004435Z-198x-cli-launch`.
The run used no physical, synthetic, keyboard, pointer, touch, or controller
input. Exact teardown returned `nova_x11_cleanup=pass` and
`nova_runtime_cleanup=pass`; the final filtered process table was empty for
the Nova rootfs, Steam, X11, compatibility-runtime, and relay patterns. The
Termux:X11 preferences hash remained
`25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895`, with
owner `10120:10120` and mode `660`. The installed game, account, and downloaded
content were retained.

## Evidence and decision boundary

The run captured fresh launcher/client logs, the command transcript, the Steam
`gameprocess_log.txt` and `content_log.txt` tails, process and file
architecture evidence, and the asynchronous dispatch markers. A screenshot
pair was not used because no game process or candidate game frame existed. It
does not claim a game-rendering pass merely because Steam accepted or queued
the AppID.

The gates are:

1. command dispatch reaches the existing Steam session;
2. a compatibility runtime starts without an architecture error;
3. the 198X process remains alive beyond the launch handoff; and
4. a first game frame is visible and correlated to this run.

The first failed gate identifies the next action: x86-64 translation/runtime
availability or compatibility-runtime startup. Physical controls and
Gamescope presentation are not implicated by this result.

## Cleanup contract

Before launch and on exit, the run follows [34](34-nova-runtime-harness-lifecycle.md)
and uses the exact Nova/X11 cleanup helpers. The APK, account, and downloaded
198X content remain installed; only run-scoped state, processes, sockets, and
temporary logs were removed. The result is committed and pushed before another
device experiment begins.
