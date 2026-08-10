# Termux:X11 198X command-line launch experiment — 2026-08-09

Status: predeclared; device result pending.

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

## Evidence and decision boundary

The run will capture fresh launcher/client logs, the command transcript, the
Steam `gameprocess_log.txt` and `content_log.txt` tails, process and file
architecture evidence, and an Android/X11 screenshot pair after the bounded
launch request. It will not claim a game-rendering pass merely because Steam
accepted or queued the AppID.

The gates are:

1. command dispatch reaches the existing Steam session;
2. a compatibility runtime starts without an architecture error;
3. the 198X process remains alive beyond the launch handoff; and
4. a first game frame is visible and correlated to this run.

The first failed gate will identify the next action: Steam IPC/dispatch,
x86-64 translation/runtime availability, Proton/Wine startup, or game display.

## Cleanup contract

Before launch and on exit, the run follows [34](34-nova-runtime-harness-lifecycle.md)
and uses the exact Nova/X11 cleanup helpers. The APK, account, and downloaded
198X content remain installed; only run-scoped state, processes, sockets, and
temporary logs are removed. The result will be committed and pushed before
another device experiment begins.
