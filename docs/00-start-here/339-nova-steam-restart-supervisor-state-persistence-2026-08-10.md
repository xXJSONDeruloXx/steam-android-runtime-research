# Nova Steam restart supervisor and state persistence — 2026-08-10

Status: passed. The bounded in-session restart and seeded-home ownership repair
reached the real Steam QR login page without retaining authentication material.

## Run identity and provenance

- Runtime: `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4`
- Launcher session: `20260810T211904Z-6888`
- APK SHA-256:
  `37099281d340902e271365cbf9d4aebaaa95668eef3a9d22773b2db420a645ec`
- Packaged direct-client asset SHA-256:
  `f860118ac24ddc2a826fd5df1db530751d852d67d6eab2297ad11a101503bb70`
- Profile: direct Termux:X11, 1280x960 Steam target, software CEF path,
  current network compatibility helper, truthful SteamOS updater helper,
  audio bridge, uinput relay, and one automatic in-session Steam restart.
- No OOBE view rewrite was enabled.

## Result

After controlled language, timezone, and Android-host-network selections,
Steam recorded:

```text
[2026-08-10 21:20:37] SteamUI: WARNING: SetOOBEComplete
[2026-08-10 21:20:37] SteamUI: WARNING: Restarting Steam
[2026-08-10 21:20:37] SteamUI: ERROR: Uncaught (in promise) Error: WHEN_CANCELLED
```

The wrapper evidence was fresh and bounded:

```text
client_attempt=1
client_webhelper_log_offset=17110
client_attempt_status=42
client_restart_evidence=pass
client_restart_request=detected
client_restart_attempt=1
client_attempt=2
client_webhelper_log_offset=22139
```

The second Steam process started at 21:20:42 while the original X11 and
system/session D-Bus processes remained alive. The visible second process was
back at the language picker rather than the login/QR route. Cleanup then
passed with no matching processes remaining.

## Independent state-persistence defect

Both Steam attempts emitted this native error:

```text
fopen /opt/nova-steam/home/.steam/steam.token failed: Permission denied
```

The corresponding seed directory was:

```text
root:root 755 /opt/nova-steam/home/.steam
501:20 755 /opt/nova-steam/home/.local/share/Steam
```

The Steam uid therefore could not create its normal per-user control/token
boundary. This is a rootfs/provisioning ownership problem, not evidence that
the updater helper, network, or X11 restart supervisor is requesting an
Android shutdown. It is also distinct from the missing SteamOSManager D-Bus
service.

## Predeclared next experiment

The authoritative provisioner and direct client preflight now create or repair
only `/opt/nova-steam/home/.steam` to `501:20` mode `0700`. They do not read,
export, copy, or back up `steam.token` or any other Steam authentication data.
All other launch variables remain unchanged.

Acceptance for the next fresh run:

1. the `steam.token` permission error is absent;
2. the existing one-restart supervisor still records a fresh handoff and a
   second Steam attempt in the same X11/D-Bus session; and
3. the second attempt advances beyond Stage 1 OOBE toward Stage 2 or the
   login/QR surface.

If Stage 1 still repeats after the ownership repair, investigate the native
Steam client-setting persistence and SteamOSManager contract as separate
experiments. Do not reintroduce an OOBE bundle rewrite into this run.

## Result of the predeclared run

The next fresh run used the same profile and launcher session
`20260810T212817Z-11248`. The provisioner and client both reported the repaired
ownership boundary, and the device showed:

```text
drwx------ 2 501 20 /opt/nova-steam/home/.steam
client_steam_dot_dir_owner_status=pass
```

The first Steam attempt again returned status `42` with fresh restart evidence;
the wrapper performed exactly one in-session relaunch. On the second attempt,
Steam recorded:

```text
SteamUI: WARNING: OOBE Stage 2: completed
SteamUI: WARNING: No restart requested
SteamUI: INFO: Login: OnLoginStateChange  1 1 0 0
```

The Android capture visibly matched Steam's sign-in page with the live QR
login control. The capture was inspected and immediately deleted because it
contained a live authentication challenge; no QR image, token, or Steam
authentication data was exported or backed up. Both attempts were free of the
earlier `.steam/steam.token` permission error.

The session is intentionally still running at the QR page for the operator to
scan. Cleanup is deferred until the operator finishes the login check.
