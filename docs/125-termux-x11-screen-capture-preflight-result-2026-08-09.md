# Termux:X11 screen-capture preflight result — 2026-08-09

Status: harness preflight failure; no APK, server, client, screenshot, or
X11 capture was launched.

## Run identity

```text
run_id=termux-x11-20260809T154000Z-android-screen-capture-display-0
repo_commit=9ca5a42
adb_serial=675a2365
device=Retroid Pocket Nova
display=:0
```

The run stopped immediately after staging the three device helpers. The
pre-run cleanup output was:

```text
pre_cleanup_server_pids=
pre_cleanup_client_pids=28509,
namespace_cleanup=pass
server_state=absent client_state=present server_parent_state=absent socket_state=absent
nova_x11_cleanup=fail
```

No Termux:X11 server or client process existed, and no `X0` socket remained.
The exact run state directory was removed after inspection.

## Cause and repair

The client matcher used one `ps -A` query and matched the run token anywhere in
the command line. The regular Android `shell` command that wrote the current
run's state files also carried that token, so it was falsely classified as a
rootfs client. This was another conservative cleanup failure, not a leaked
client.

The matcher now requires `$3 == "root"` in the Android `ps` output before
matching the exact run token. The direct chroot client is launched through
`su` as root; the host-side state-writing command is user `shell` and is
outside this experiment's cleanup authority.

The next attempt remains the same predeclared Android screen-capture
experiment and must reach the server/window gates before it can say anything
about physical presentation.
