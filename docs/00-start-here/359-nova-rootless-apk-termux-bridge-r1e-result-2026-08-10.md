# Nova rootless APK/Termux bridge R1e result — 2026-08-10

Status: pass for APK-owned Termux:X11 startup and loopback readiness; native
rootless Steam remains the next gate.

## Run identity

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- APK: `/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/nova-lab-debug.apk`.
- APK SHA-256: `aec763abb14c9ea7b50b8e325b2329fa57947ab688ebfa85743df9fa180a45a4`.
- Termux base: official GitHub `v0.119.0-beta.3`, arm64-v8a; artifact and
  certificate hashes are recorded in [354](354-nova-rootless-termux-base-install-2026-08-10.md).
- Termux:X11: `1.03.01-d8013ac-09.08.26`; artifact hash is recorded in [354](354-nova-rootless-termux-base-install-2026-08-10.md).
- Rootless display: fresh `:77`, loopback TCP `127.0.0.1:6077`.
- Rooted signed-in Steam session: left running and untouched on `:0`.

## Failure chain closed

The first APK replay reached `RunCommandService` but did not start a process.
Fresh diagnostics isolated three integration defects:

1. The per-command log-level extra was sent as a string even though Termux
   v0.119 reads it as an integer. The bridge now sends debug level `2`.
2. Android rejected ordinary cross-package `startService()` after Nova left
   the foreground: `Not allowed to start service ... app is in background`.
   The bridge now uses `startForegroundService()` on API 26 and newer.
3. Termux AppShell executed `bash -s` without preserving the helper's
   intended positional arguments. The helper received a nonnumeric display
   and reported `invalid_display_number`. The bridge now executes
   `bash -c '. /dev/stdin' nova-rootless-termux-x11 start 77`, preserving
   `$1=start` and `$2=77` while retaining the intent stdin contract.

## Passing evidence

With a fresh APK install-in-place and the user-granted
`com.termux.permission.RUN_COMMAND` permission, the Java service log reported:

```text
NovaRootless: Rootless X11 requested on :77
Termux.AppShell: (1) Nova rootless Termux:X11 ... exited normally
Termux.TermuxService: nova_rootless_termux_x11=started display=:77 pid=15484
NovaRootless: Rootless X11 ready on 127.0.0.1:6077
```

The Termux-owned server was observed as:

```text
15484 u0_a129 termux-x11 com.termux.x11 :77 -listen tcp -ac
```

Nova's own `127.0.0.1:6077` probe succeeded. The APK stop control then stopped
the exact rootless server; a fresh probe returned connection refused, while the
rooted process remained:

```text
26237 root termux-x11
```

The temporary Termux state directory
`/data/data/com.termux/files/home/.nova-rootless` was removed. Termux's
diagnostic preference was restored from log level `3` to its original `1`.
No rooted runtime, Steam home, authentication data, or `:0` process was
removed or copied.

## Contract boundary

This closes the APK-to-Termux startup seam and proves the product service can
own the experimental rootless X11 lifecycle. The endpoint still uses
`-listen tcp -ac`; it is a bounded transport experiment, not a final shipped
authentication design. The next gate is a clean app-owned Steam home/client
through the rootless PRoot supervisor, using this fresh `:77` transport and
requiring a real Steam UI/OOBE frame.

The command shape remains aligned with Termux's official
[RUN_COMMAND Intent contract](https://github.com/termux/termux-app/wiki/RUN_COMMAND-Intent),
including the required user property, permission, package visibility, stdin,
and foreground-service boundaries.
