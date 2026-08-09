# Termux:X11 interactive QR login result — 2026-08-09

Status: operator-confirmed login success. The long-lived Nova session remains
running at the signed-in Steam home while the operator checks input and other
subsystems; teardown and final cleanup evidence are intentionally pending.

## Run identity and provenance

```text
run_id=termux-x11-20260809T190803Z-qr-login-interactive-0
repo_commit=67de0e005f7bbaf3ed33764e97ac9ca5c7c180fa
adb_serial=675a2365
device=Retroid Pocket Nova
android_version=13
termux_x11_apk=/tmp/nova-x11-prior-art-20260809/termux-x11-universal-debug.apk
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
x11_client=android/nova-lab/device/nova-termux-x11-steam-client.sh
x11_client_sha256=a5d032caeda8c34f0384201c14f9dd91fc4394beaad2cfdcaf6d80246143299c
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
client_namespace_mode=chroot-dev
bind_android_dev=1
steam_uid=501:20
dbus_session=1
dbus_session_user=steam
dbus_session_uid_record=1
dbus_system=1
steam_timeout_seconds=86400
```

The live run directory is:

```text
android/nova-lab/build/manual-runs/termux-x11-20260809T190803Z-qr-login-interactive-0/
```

## Login transition

The operator scanned the QR code with Steam Mobile while this run was live.
The first CDP snapshot taken after the scan showed the intermediate SteamOS
welcome screen. The next fresh snapshot settled at the authenticated home:

```text
title=Steam Big Picture Mode
body=Recent Games / Friends 1 / RECOMMENDED / NEWS / MENU / OPTIONS / SELECT / BACK
```

The Android capture visibly shows the Steam home/library/news UI and the
account avatar. The current signed-in CDP artifact is:

```text
cdp-login-state.json=d5646ba6fc569643358c1536a9c0aad358123293c2992861a6e011b6bb39d13f
android-screenshot-post-login.png=4c568cf45e52056f9c477f0cb941e5c75daf850e1c28f1673f9ba28f0c485bd6
x11-window-post-login.ppm=7999b0ef50b3eebcdb2b9d16e8eea79d03410d26b60f5ab6f75f33e4b642f839
```

`SteamClient.User` remains undefined in the CEF page, so it is not used as
the acceptance gate. The visible Steam home, account avatar, friends count,
and operator-reported QR approval establish the login transition for this
session.

The run's automatic pre-login input sequence passed all three focused Enter
events and recorded changed Android/X11 captures. The QR body was not retained
by the CDP probe because the operator completed the scan before that probe
ran; the independent fresh QR captures remain documented in
[docs/188](188-termux-x11-system-dbus-only-result-2026-08-09.md) and
[docs/190](190-termux-x11-system-dbus-repeat-result-2026-08-09.md).

## Live subsystem observations

At the post-login snapshot:

- Termux:X11 remained the focused Android activity and its SurfaceView was
  responsive.
- The process tree still contained Steam, `steamwebhelper`, both D-Bus
  daemons, and the Termux:X11 server.
- Android Connectivity still reported validated Wi-Fi/Internet state. The
  retained snapshot hash is
  `1a5201998b12710d2372512bc41021f4a6d7f38c6d7ae08e2e480e26acff7e7f`.
- Android AudioFlinger exposed speaker output mixer threads; the snapshot hash
  is `e5a451aa8e686354a5da8ba29099f582004491444bf355ab59beaf4ebb8f0106`.
  This is routing/process evidence, not yet a claim that game audio was
  audibly verified.

This session still uses the native Steam client's explicit software GL/CEF
compatibility settings and no Gamescope, so it does not advance the separate
hardware-accelerated Gamescope product milestone.

## Cleanup status

The session is deliberately still live for operator testing. The lifecycle
contract requires the harness to be stopped through its normal path before
this result can be closed; that later stop must record `termux_x11_post_stop`
and `nova_runtime_cleanup=pass` with no residual runtime, bus, forward, or
temporary socket.
