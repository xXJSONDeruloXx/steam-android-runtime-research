# Termux:X11 stateful cleanup and foreground launcher result — 2026-08-09

Status: partial device result. The state-file cleanup preflight passed and the
Termux:X11 server gate passed, but the synthetic client still did not map. The
run also exposed a cleanup false positive: the harness reported a clean stop
while an exact server process remained. Both failures are documented here and
the next repair is being pushed before another device run.

## Run identity

```text
run_id=termux-x11-20260809T151500Z-stateful-cleanup-display-0
repo_commit=f683e41
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
display=:0
termux_x11_source_commit=d8013ac5d174bb16120f915c10a7255948c59c17
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
x11_animate_sha256=884853cdc47c0d10a644153404fcd25e155b8784e24903f3ced568649b10bc04
x11_capture_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

Run artifacts are under
`android/nova-lab/build/manual-runs/termux-x11-20260809T151500Z-stateful-cleanup-display-0/`.

## Result

The state-file preflight passed, the server socket became live, and fresh
logs again showed the official Termux:X11 revision, rootfs `TMPDIR`, Adreno
EGL initialization, and Activity-side XCB setup. The X11 tree remained only:

```text
nova_x11_display=pass display=:0 screen=0 root=0x511
nova_x11_window id=0x511 parent=0x0 depth=0 map_state=viewable x=0 y=0 width=1280 height=714 border=0 name="<none>" res_name="<none>" res_class="<none>"
nova_x11_tree=pass root=0x511
```

The client stderr again contained:

```text
unshare: Operation not permitted
```

The host-side `adb` process was backgrounded, but the remote `su -c` payload
still combined `echo`, redirection, and the namespace helper with shell
operators. On this device that is not equivalent to a direct root invocation;
the foreground control check
`adb shell su -c /system/bin/unshare -m /system/bin/echo` succeeds. The next
repair moves all log redirection into a checked-in device launcher script and
invokes that script as the sole direct `su -c` command.

No synthetic window, X11 PPM, or Android screenshot acceptance was produced.

## Teardown audit

The run's automatic artifacts said:

```text
pre_cleanup_server_pids=
pre_cleanup_client_pids=
namespace_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_x11_cleanup=pass
```

An independent exact process check immediately afterward found the live
server tree:

```text
27149  1    shell  su -c /system/bin/env ... --nice-name=termux-x11 ...
27153  1026 root   sh -c /system/bin/env ... --nice-name=termux-x11 ...
27154 27153 root   termux-x11
```

The process details were `/proc/27154/comm=main` and
`/proc/27154/cmdline=termux-x11`. The matcher received the same token, but
the NUL-to-space conversion left a trailing space, so exact equality rejected
the real server. The state directory and socket were removed while the
process survived, making the automatic pass a stale/false cleanup result.

The exact PIDs `27154`, `27153`, and `27149` were then terminated and a fresh
process/socket check returned no matching server and no `X0` socket. This run
does not count as a clean automatic teardown.

## Repair published with this result

The harness now trims the terminal separator from `/proc/*/cmdline` before
matching `termux-x11`, and adds
`nova-termux-x11-client-launcher.sh`. The launcher performs the remote stdout
and stderr redirection inside a root shell script, then directly execs the
private namespace/chroot helper. The host keeps only the outer `adb` process
backgrounded, so the `su -c` payload has no semicolon, background operator, or
remote redirection to be flattened.

The next run must pass the synthetic mapped-window, X11 PPM, Android
screenshot, and independently verified automatic teardown gates before any
Steam process is introduced.
