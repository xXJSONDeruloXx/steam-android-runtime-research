# Termux:X11 screen-capture Magisk preflight result — 2026-08-09

Status: harness preflight failure; no APK, server, client, screenshot, or
X11 capture was launched.

## Run identity

```text
run_id=termux-x11-20260809T155000Z-android-screen-capture-display-0
repo_commit=cdadc8d
adb_serial=675a2365
device=Retroid Pocket Nova
display=:0
```

The run stopped immediately after helper staging. The exact cleanup output was:

```text
pre_cleanup_server_pids=
pre_cleanup_client_pids=28695,
namespace_cleanup=pass
server_state=absent client_state=present server_parent_state=absent socket_state=absent
nova_x11_cleanup=fail
```

No Termux:X11 server or client process existed, and no `X0` socket remained.
The exact run state directory was removed after inspection.

## Cause and repair

The root-only matcher still saw a Magisk root `app_process` used to log the
regular `adb shell` state-writing command. That diagnostic process carried the
run's staged client path in its command line, so it was falsely classified as
the rootfs client. This is another cleanup self-match, not a leaked client.

The matcher now excludes `app_process` rows from the root `ps` result before
matching the client token. The actual direct chroot client is not an Android
`app_process`; it is the run-scoped launcher/chroot process and remains within
the cleanup authority.

The next attempt remains the same predeclared Android screen-capture
experiment. It must pass the preflight and mapped-window gates before physical
screen evidence is interpreted.

The phase-aware client matcher retry is recorded in
[doc 127](127-termux-x11-screen-capture-phase-preflight-result-2026-08-09.md).
