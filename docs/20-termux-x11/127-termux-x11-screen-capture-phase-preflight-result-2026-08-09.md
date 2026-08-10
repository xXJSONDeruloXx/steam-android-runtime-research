# Termux:X11 screen-capture phase-aware preflight result — 2026-08-09

Status: harness preflight failure; no APK, server, client, screenshot, or
X11 capture was launched.

## Run identity

```text
run_id=termux-x11-20260809T155500Z-android-screen-capture-display-0
repo_commit=bb3b47d
adb_serial=675a2365
device=Retroid Pocket Nova
display=:0
```

The run stopped in pre-run cleanup with:

```text
pre_cleanup_server_pids=
pre_cleanup_client_pids=28941,
namespace_cleanup=pass
server_state=absent client_state=present server_parent_state=absent socket_state=absent
nova_x11_cleanup=fail
```

No Termux:X11 server/client or `X0` socket existed. The exact state directory
was removed after inspection.

## Cause and repair

Even after excluding Android `shell` and Magisk `app_process` rows, a root
wrapper associated with state preparation carried the current run token before
any client had been launched. Matching a client token during preflight is
unnecessary and risks classifying setup infrastructure as a client.

The state directory now records `client-active=0` during preflight and changes
it to `1` immediately before the direct client launcher starts. The cleanup
helper ignores client-process matching while the marker is `0`; teardown
enables the exact root-token match after launch. Server/socket/file cleanup
remains active in both phases.

The next attempt remains the same predeclared Android screen-capture
experiment and should reach the Termux:X11 server gate before the client phase
is enabled.
