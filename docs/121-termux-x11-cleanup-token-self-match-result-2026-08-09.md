# Termux:X11 cleanup-token self-match result — 2026-08-09

Status: harness preflight failure; no Termux:X11 APK, server, or synthetic
client was launched. The run is documented and the repair is being pushed
before another device experiment.

## Run identity

```text
run_id=termux-x11-20260809T150500Z-foreground-namespace-display-0
repo_commit=83906d0
adb_serial=675a2365
device=Retroid Pocket Nova
display=:0
```

The run stopped in the pre-run exact-cleanup gate. Its only meaningful output
was:

```text
pre_cleanup_server_pids=
pre_cleanup_client_pids=26450,
namespace_cleanup=pass
server_state=absent client_state=present server_parent_state=absent socket_state=absent
nova_x11_cleanup=fail
```

No APK install, Activity start, server launch, client launch, X11 tree, or
pixel capture occurred. The run-specific state directory was removed after
the failure, and a fresh process/socket check found no matching Termux:X11
process and no `X0` socket.

## Cause

The cleanup helper received the full client token as a command-line argument.
Because the cleanup command itself contained that token, its own `/proc`
command line was eligible for the client substring matcher. The helper
failed closed rather than deleting an unrelated process, which is correct
behavior but made the preflight unusable.

## Repair

The helper now reads the exact client path, socket/lock paths, server token,
and client token from run-scoped state files. The host creates those files in
the shell-owned state directory before invoking cleanup, and the cleanup
command receives only the state directory and private namespace helper path.
The client token therefore remains available for exact post-launch matching
without appearing as an argument to the cleanup process itself.

The next run must reach the Termux:X11 server gate before its result can say
anything about the X11 client or Android rendering.
